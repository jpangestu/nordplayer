import 'dart:isolate';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nordplayer/core/database/app_database.dart';
import 'package:nordplayer/core/system/logger.dart';
import 'package:nordplayer/core/utils/string_extension.dart';
import 'package:nordplayer/services/indexer/chromaprint_service.dart';
import 'package:path/path.dart' as p;

final duplicateDetectorProvider = Provider<DuplicateDetector>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return DuplicateDetector(db);
});

class DuplicateCandidate({
  required final Track track,
  required final String artistName,
  required final String albumTitle,
});

class DuplicateGroup({
  required final String title,
  required final String artist,
  required final String album,
  required final List<Track> tracks,
  required final Track preferredTrack,
});

class DuplicateDetector(final AppDatabase _db) with LoggerMixin {

  /// Scans the library database to find groups of duplicate tracks.
  Future<List<DuplicateGroup>> findDuplicates() async {
    log.i("Starting duplicate track detection scan...");
    final stopwatch = Stopwatch()..start();

    // Fetch active tracks with fingerprints, joined with Artists and Albums
    final query = _db.select(_db.tracks).join([
      leftOuterJoin(_db.albums, _db.albums.id.equalsExp(_db.tracks.albumId)),
      leftOuterJoin(_db.artists, _db.artists.id.equalsExp(_db.tracks.artistId)),
    ])..where(_db.tracks.isMissing.equals(false) & _db.tracks.audioFingerprint.isNotNull());

    final rows = await query.get();
    final List<DuplicateCandidate> candidates = rows.map((row) {
      final track = row.readTable(_db.tracks);
      final album = row.readTableOrNull(_db.albums);
      final artist = row.readTableOrNull(_db.artists);

      return DuplicateCandidate(
        track: track,
        artistName: artist?.name ?? 'Unknown Artist',
        albumTitle: album?.title ?? 'Unknown Album',
      );
    }).toList();

    log.i("Fetched ${candidates.length} tracks with fingerprints for duplication checking.");

    // Map to simple data structures for sending to isolate
    final isolateCandidates = candidates
        .map(
          (c) => _IsolateCandidate(
            id: c.track.id,
            durationMs: c.track.durationMs,
            audioFingerprint: c.track.audioFingerprint,
          ),
        )
        .toList();

    // Perform duplicate search in background Isolate
    final duplicateTrackIdGroups = await _runDetection(isolateCandidates);

    final Map<int, DuplicateCandidate> candidateMap = {for (final c in candidates) c.track.id: c};

    final List<DuplicateGroup> duplicateGroups = [];
    for (final idGroup in duplicateTrackIdGroups) {
      final groupCandidates = idGroup.map((id) => candidateMap[id]!).toList();
      final target = groupCandidates.first;
      final groupTracks = groupCandidates.map((c) => c.track).toList();
      final preferredTrack = _determinePreferredTrack(groupTracks);

      duplicateGroups.add(
        DuplicateGroup(
          title: target.track.title,
          artist: target.artistName,
          album: target.albumTitle,
          tracks: groupTracks,
          preferredTrack: preferredTrack,
        ),
      );
    }

    stopwatch.stop();
    log.i(
      "Duplicate scan complete. Found ${duplicateGroups.length} duplicate groups in ${stopwatch.elapsedMilliseconds}ms.",
    );
    return duplicateGroups;
  }

  /// Ignores a track by removing it from the database and adding it to the ignored paths table.
  Future<void> ignorePath(Track track) async {
    log.i("Ignoring track '${track.title}' (ID: ${track.id}) by removing from database and adding to ignored paths.");
    await ignorePaths([track]);
  }

  /// Ignores multiple tracks in a single database transaction.
  Future<void> ignorePaths(List<Track> tracks) async {
    if (tracks.isEmpty) return;
    log.i("Ignoring ${tracks.length} tracks in a single transaction.");

    await _db.transaction(() async {
      for (final track in tracks) {
        await (_db.delete(_db.tracks)..where((t) => t.id.equals(track.id))).go();
        await _db
            .into(_db.ignoredPaths)
            .insertOnConflictUpdate(
              IgnoredPathsCompanion(filePath: Value(track.filePath.normalizePath().toLowerCase())),
            );
      }
    });

    await _db.deleteOrphanedMetadata();
  }

  static const _losslessExtensions = {'.flac', '.wav', '.alac', '.ape'};

  /// Determines the preferred/highest quality track copy in a list.
  /// Prefers lossless formats (.flac, .wav, .alac, .ape) and falls back to larger file sizes.
  Track _determinePreferredTrack(List<Track> group) {
    return group.reduce((best, current) {
      final extBest = p.extension(best.filePath).toLowerCase();
      final extCurr = p.extension(current.filePath).toLowerCase();

      final isLosslessBest = _losslessExtensions.contains(extBest);
      final isLosslessCurr = _losslessExtensions.contains(extCurr);

      if (isLosslessBest && !isLosslessCurr) return best;
      if (!isLosslessBest && isLosslessCurr) return current;

      // If formats are of equal lossless/lossy tier, prefer the larger file size
      return (current.fileSize > best.fileSize) ? current : best;
    });
  }
}

class _IsolateCandidate({
  required final int id,
  required final int durationMs,
  required final Uint8List? audioFingerprint,
});

List<List<int>> _findDuplicatesIsolate(List<_IsolateCandidate> candidates) {
  // Sort candidates by duration to enable window-based scanning
  candidates.sort((a, b) => a.durationMs.compareTo(b.durationMs));

  final List<List<int>> duplicateGroups = [];
  final Set<int> processedIds = {};

  // Pre-parse fingerprints to avoid parsing them repeatedly in the inner loops
  final Map<int, List<int>?> parsedFingerprints = {};
  for (final candidate in candidates) {
    parsedFingerprints[candidate.id] = ChromaprintService.parseRawAudioFingerprint(candidate.audioFingerprint);
  }

  // Slide a window forward
  for (int i = 0; i < candidates.length; i++) {
    final target = candidates[i];
    if (processedIds.contains(target.id)) continue;

    final List<int> currentGroup = [target.id];

    for (int j = i + 1; j < candidates.length; j++) {
      final next = candidates[j];
      if (next.durationMs - target.durationMs > 5000) {
        break; // Duration difference exceeds 5 seconds window, stop looking forward
      }
      if (processedIds.contains(next.id)) continue;

      final fp1 = parsedFingerprints[target.id];
      final fp2 = parsedFingerprints[next.id];

      if (fp1 != null && fp2 != null) {
        final similarity = ChromaprintService.compareRawAudioFingerprints(fp1, fp2);
        if (similarity >= 0.85) {
          currentGroup.add(next.id);
        }
      }
    }

    if (currentGroup.length > 1) {
      duplicateGroups.add(currentGroup);

      // Mark all matched tracks as processed
      for (final id in currentGroup) {
        processedIds.add(id);
      }
    }
  }

  return duplicateGroups;
}

Future<List<List<int>>> _runDetection(List<_IsolateCandidate> candidates) {
  return Isolate.run(() => _findDuplicatesIsolate(candidates));
}
