import 'dart:isolate';
import 'dart:typed_data';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nordplayer/data/database/app_database.dart' hide Track;
import 'package:nordplayer/utils/logger.dart';
import 'package:nordplayer/utils/string_extension.dart';
import 'package:nordplayer/data/database/db_mappers.dart';
import 'package:nordplayer/domain/models/models.dart';
import 'package:nordplayer/data/services/indexer/chromaprint_service.dart';
export 'package:nordplayer/domain/models/duplicate_group.dart';

final duplicateDetectorProvider = Provider<DuplicateDetector>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return DuplicateDetector(db);
});

class DuplicateCandidate({
  required final Track track,
  required final String artistName,
  required final String albumTitle,
});

class DuplicateDetector(final AppDatabase _db) with LoggerMixin {
  /// Scans the library database to find groups of duplicate tracks.
  Future<List<DuplicateGroup>> findDuplicates() async {
    log.i("Starting duplicate track detection scan...");
    final stopwatch = Stopwatch()..start();

    // Phase 1 (Probe): Query active tracks sorted by duration
    final trackQuery = _db.select(_db.tracks)
      ..where((t) => t.isMissing.equals(false) & t.audioFingerprint.isNotNull())
      ..orderBy([(t) => OrderingTerm.asc(t.durationMs)]);

    final tracks = await trackQuery.get();
    final int count = tracks.length;
    log.i("Fetched $count tracks with fingerprints for duplication checking.");

    if (count < 2) {
      stopwatch.stop();
      log.i("Duplicate scan complete. Not enough tracks to compare in ${stopwatch.elapsedMilliseconds}ms.");
      return [];
    }

    // Pack into flat Data-Oriented Structure of Arrays (SoA)
    final Int32List ids = Int32List(count);
    final Int32List durations = Int32List(count);
    final List<Uint32List?> fingerprints = List<Uint32List?>.filled(count, null);

    for (int i = 0; i < count; i++) {
      final track = tracks[i];
      ids[i] = track.id;
      durations[i] = track.durationMs;
      fingerprints[i] = ChromaprintService.parseRawAudioFingerprint(track.audioFingerprint);
    }

    // Perform duplicate search in background Isolate
    final duplicateTrackIdGroups = await _runDetection((ids: ids, durations: durations, fingerprints: fingerprints));

    if (duplicateTrackIdGroups.isEmpty) {
      stopwatch.stop();
      log.i("Duplicate scan complete. Found 0 duplicate groups in ${stopwatch.elapsedMilliseconds}ms.");
      return [];
    }

    // Phase 2 (Deferred Materialization):
    // Join albums & artists for tracks confirmed as duplicates!
    final duplicateIds = duplicateTrackIdGroups.expand((g) => g).toSet();
    final query = _db.select(_db.tracks).join([
      leftOuterJoin(_db.albums, _db.albums.id.equalsExp(_db.tracks.albumId)),
      leftOuterJoin(_db.artists, _db.artists.id.equalsExp(_db.tracks.artistId)),
    ])..where(_db.tracks.id.isIn(duplicateIds));

    final rows = await query.get();
    final Map<int, DuplicateCandidate> candidateMap = {};
    for (final row in rows) {
      final track = row.readTable(_db.tracks);
      final album = row.readTableOrNull(_db.albums);
      final artist = row.readTableOrNull(_db.artists);

      candidateMap[track.id] = DuplicateCandidate(
        track: track.toDomain(),
        artistName: artist?.name ?? 'Unknown Artist',
        albumTitle: album?.title ?? 'Unknown Album',
      );
    }

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

  static bool _isLossless(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.flac') || lower.endsWith('.wav') || lower.endsWith('.alac') || lower.endsWith('.ape');
  }

  /// Determines the preferred/highest quality track copy in a list.
  /// Prefers lossless formats (.flac, .wav, .alac, .ape) and falls back to larger file sizes.
  Track _determinePreferredTrack(List<Track> group) {
    Track best = group.first;
    bool bestIsLossless = _isLossless(best.filePath);

    for (int i = 1; i < group.length; i++) {
      final current = group[i];
      final currentIsLossless = _isLossless(current.filePath);

      if (currentIsLossless && !bestIsLossless) {
        best = current;
        bestIsLossless = true;
      } else if (currentIsLossless == bestIsLossless && current.fileSize > best.fileSize) {
        best = current;
      }
    }

    return best;
  }
}

typedef _DuplicateScanBatch = ({Int32List ids, Int32List durations, List<Uint32List?> fingerprints});

List<List<int>> _findDuplicatesIsolate(_DuplicateScanBatch batch) {
  final ids = batch.ids;
  final durations = batch.durations;
  final fingerprints = batch.fingerprints;
  final int count = ids.length;

  // 1-byte bitset: 0 = unprocessed, 1 = processed
  final Uint8List isProcessed = Uint8List(count);
  final List<List<int>> duplicateGroups = [];

  // Slide a 5-second window forward across sorted tracks
  for (int i = 0; i < count; i++) {
    if (isProcessed[i] == 1) continue;

    final int targetDuration = durations[i];
    final Uint32List? fp1 = fingerprints[i];
    if (fp1 == null) continue;

    List<int>? currentGroup;

    for (int j = i + 1; j < count; j++) {
      if (durations[j] - targetDuration > 5000) {
        break; // Duration difference exceeds 5-second window, stop looking forward
      }
      if (isProcessed[j] == 1) continue;

      final Uint32List? fp2 = fingerprints[j];
      if (fp2 == null) continue;

      if (ChromaprintService.areFingerprintsMatching(fp1, fp2, 0.85)) {
        currentGroup ??= [ids[i]];
        currentGroup.add(ids[j]);
        isProcessed[j] = 1;
      }
    }

    if (currentGroup != null) {
      isProcessed[i] = 1;
      duplicateGroups.add(currentGroup);
    }
  }

  return duplicateGroups;
}

Future<List<List<int>>> _runDetection(_DuplicateScanBatch batch) {
  return Isolate.run(() => _findDuplicatesIsolate(batch));
}
