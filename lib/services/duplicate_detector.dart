import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nordplayer/database/app_database.dart';
import 'package:nordplayer/services/logger.dart';
import 'package:nordplayer/utils/string_extension.dart';
import 'package:path/path.dart' as p;

final duplicateDetectorProvider = Provider<DuplicateDetector>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return DuplicateDetector(db);
});

class DuplicateCandidate {
  final Track track;
  final String artistName;
  final String albumTitle;

  DuplicateCandidate({required this.track, required this.artistName, required this.albumTitle});
}

class DuplicateGroup {
  final String title;
  final String artist;
  final String album;
  final List<Track> tracks;
  final Track preferredTrack;

  DuplicateGroup({
    required this.title,
    required this.artist,
    required this.album,
    required this.tracks,
    required this.preferredTrack,
  });
}

class DuplicateDetector with LoggerMixin {
  final AppDatabase _db;

  DuplicateDetector(this._db);

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

    await (_db.delete(_db.tracks)..where((t) => t.id.equals(track.id))).go();

    await _db
        .into(_db.ignoredPaths)
        .insertOnConflictUpdate(IgnoredPathsCompanion(filePath: Value(track.filePath.normalizePath().toLowerCase())));
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
  }

  /// Determines the preferred/highest quality track copy in a list.
  /// Prefers lossless formats (.flac, .wav, .alac, .ape) and falls back to larger file sizes.
  Track _determinePreferredTrack(List<Track> group) {
    return group.reduce((best, current) {
      final extBest = p.extension(best.filePath).toLowerCase();
      final extCurr = p.extension(current.filePath).toLowerCase();

      final isLosslessBest = const ['.flac', '.wav', '.alac', '.ape'].contains(extBest);
      final isLosslessCurr = const ['.flac', '.wav', '.alac', '.ape'].contains(extCurr);

      if (isLosslessBest && !isLosslessCurr) return best;
      if (!isLosslessBest && isLosslessCurr) return current;

      // If formats are of equal lossless/lossy tier, prefer the larger file size
      return (current.fileSize > best.fileSize) ? current : best;
    });
  }
}

class _IsolateCandidate {
  final int id;
  final int durationMs;
  final Uint8List? audioFingerprint;

  _IsolateCandidate({required this.id, required this.durationMs, required this.audioFingerprint});
}

List<List<int>> _findDuplicatesIsolate(List<_IsolateCandidate> candidates) {
  // Sort candidates by duration to enable window-based scanning
  candidates.sort((a, b) => a.durationMs.compareTo(b.durationMs));

  List<int>? parseRawAudioFingerprint(Uint8List? bytes) {
    if (bytes == null || bytes.isEmpty) return null;
    if (bytes.offsetInBytes % 4 != 0) {
      final alignedBytes = Uint8List.fromList(bytes);
      return Uint32List.view(alignedBytes.buffer);
    }
    return Uint32List.view(bytes.buffer, bytes.offsetInBytes, bytes.lengthInBytes ~/ 4);
  }

  int popcount(int x) {
    x = x & 0xFFFFFFFF; // Ensure 32-bit
    x -= ((x >> 1) & 0x55555555);
    x = (((x >> 2) & 0x33333333) + (x & 0x33333333));
    x = (((x >> 4) + x) & 0x0F0F0F0F);
    x += (x >> 8);
    x += (x >> 16);
    return (x & 0x0000003F);
  }

  double compareRawAudioFingerprints(List<int> fp1, List<int> fp2) {
    if (fp1.isEmpty || fp2.isEmpty) return 0.0;

    const int maxOffset = 40;
    double maxSimilarity = 0.0;

    final int len1 = fp1.length;
    final int len2 = fp2.length;

    for (int offset = -maxOffset; offset <= maxOffset; offset++) {
      final int start1 = math.max(0, offset);
      final int start2 = math.max(0, -offset);
      final int overlapLen = math.min(len1 - start1, len2 - start2);

      if (overlapLen < 15) continue;

      int matchingBits = 0;
      for (int i = 0; i < overlapLen; i++) {
        final int val1 = fp1[start1 + i];
        final int val2 = fp2[start2 + i];
        final int diffBits = val1 ^ val2;
        matchingBits += (32 - popcount(diffBits));
      }

      final double similarity = matchingBits / (overlapLen * 32);
      if (similarity > maxSimilarity) {
        maxSimilarity = similarity;
      }
    }

    return maxSimilarity;
  }

  final List<List<int>> duplicateGroups = [];
  final Set<int> processedIds = {};

  // Pre-parse fingerprints to avoid parsing them repeatedly in the inner loops
  final Map<int, List<int>?> parsedFingerprints = {};
  for (final candidate in candidates) {
    parsedFingerprints[candidate.id] = parseRawAudioFingerprint(candidate.audioFingerprint);
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
        final similarity = compareRawAudioFingerprints(fp1, fp2);
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
