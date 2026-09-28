import 'dart:io';

import 'package:audiotags/audiotags.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nordplayer/data/database/app_database.dart';
import 'package:nordplayer/data/services/audio/playback_controller.dart';
import 'package:nordplayer/data/services/indexer/chromaprint_service.dart';
import 'package:nordplayer/data/services/system/background_task_service.dart';
import 'package:nordplayer/utils/audio_metadata_hasher.dart';
import 'package:nordplayer/utils/logger.dart';
import 'package:nordplayer/utils/string_extension.dart';
import 'package:path/path.dart' as p;

import 'audio_fingerprint_indexer.dart';
import 'library_scanner.dart';
import 'track_indexer.dart';

final libraryIndexerProvider = Provider<LibraryIndexer>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return LibraryIndexer(ref, db);
});

class LibraryIndexer(final Ref _ref, final AppDatabase _db) with LoggerMixin {
  late final AudioFingerprintIndexer _audioFingerprintIndexer = AudioFingerprintIndexer(_ref, _db);
  late final TrackIndexer _trackIndexer = TrackIndexer(_ref, _db, _audioFingerprintIndexer.cancel);
  late final LibraryScanner _libraryScanner = LibraryScanner(_ref, _db, _trackIndexer, _audioFingerprintIndexer.cancel);

  Future<void> scanLibrary({void Function(int processed, int total)? onProgress}) async {
    return _libraryScanner.scanLibrary(onProgress: onProgress, onComplete: _startBackgroundFingerprintGenerationIfIdle);
  }

  Future<void> reindexTracks({void Function(int processed, int total)? onProgress}) async {
    return _trackIndexer.reindexTracks(onProgress: onProgress, onComplete: _startBackgroundFingerprintGenerationIfIdle);
  }

  Set<String> get supportedExtensions => _libraryScanner.supportedExtensions;

  Future<void> generateMissingFingerprints({void Function(int processed, int total)? onProgress}) async {
    return _audioFingerprintIndexer.generateAudioFingerprints(onProgress: onProgress);
  }

  Future<void> processSingleFile(File file) async {
    log.i("Processing individual file: ${file.path}");

    final trackHash = AudioMetadataHasher.calculateHash(file);

    // Check if the file was moved/renamed (hash matches an existing track)
    final existingTrackByHash =
        await (_db.selectOnly(_db.tracks)
              ..addColumns([_db.tracks.id, _db.tracks.filePath])
              ..where(_db.tracks.fileHash.equals(trackHash))
              ..limit(1))
            .getSingleOrNull();

    final normalizedPath = file.path.normalizePath().toLowerCase();

    if (existingTrackByHash != null) {
      final oldFilePath = existingTrackByHash.read(_db.tracks.filePath)!;
      final oldTrackId = existingTrackByHash.read(_db.tracks.id)!;
      final normalizedDbPath = oldFilePath.normalizePath().toLowerCase();
      if (normalizedDbPath != normalizedPath) {
        log.i(
          "Detected file moved/renamed via watcher: '$oldFilePath' -> '${file.path}'. Reconnecting database entry...",
        );
      }
      await (_db.update(_db.tracks)..where((t) => t.id.equals(oldTrackId))).write(
        TracksCompanion(filePath: Value(file.path), isMissing: const Value(false)),
      );
      return;
    }

    // Check if the file already exists in the database by path
    final existingTrackByPath =
        await (_db.selectOnly(_db.tracks)
              ..addColumns([_db.tracks.id, _db.tracks.audioFingerprint, _db.tracks.durationMs])
              ..where(_db.tracks.filePath.lower().equals(normalizedPath))
              ..limit(1))
            .getSingleOrNull();

    if (existingTrackByPath != null) {
      final trackId = existingTrackByPath.read(_db.tracks.id)!;
      final storedFingerprint = existingTrackByPath.read(_db.tracks.audioFingerprint);
      final storedDurationMs = existingTrackByPath.read(_db.tracks.durationMs)!;

      try {
        final trackTag = await AudioTags.read(file.path);
        if (trackTag != null) {
          // Safeguard: Verify if it is the same audio file by checking the audio fingerprint
          final fingerprintRes = await _ref.read(chromaprintServiceProvider).calculateAudioFingerprint(file.path);

          bool isSameTrack = false;
          if (fingerprintRes != null) {
            if (storedFingerprint != null) {
              final storedRaw = ChromaprintService.parseRawAudioFingerprint(storedFingerprint);
              if (storedRaw != null) {
                final similarity = ChromaprintService.compareRawAudioFingerprints(
                  fingerprintRes.rawAudioFingerprint,
                  storedRaw,
                );
                isSameTrack = similarity >= 0.85;
                log.i(
                  "Calculated fingerprint similarity for '${file.path}': ${(similarity * 100).toStringAsFixed(1)}% (match: $isSameTrack)",
                );
              }
            } else {
              // Fallback to duration for existing tracks that do not have fingerprints yet
              final newDurationMs = fingerprintRes.durationMs;
              final durationDifferenceMs = (storedDurationMs - newDurationMs).abs();
              isSameTrack = durationDifferenceMs <= 1000;

              if (isSameTrack) {
                // Cache the fingerprint back to the DB record
                await (_db.update(_db.tracks)..where((t) => t.id.equals(trackId))).write(
                  TracksCompanion(audioFingerprint: Value(fingerprintRes.fingerprintBytes)),
                );
              }
            }
          } else {
            // Hard fallback to duration if fingerprinting failed
            final newDurationMs = (trackTag.duration ?? 0) * 1000;
            final durationDifferenceMs = (storedDurationMs - newDurationMs).abs();
            isSameTrack = durationDifferenceMs <= 1000;
          }

          if (isSameTrack) {
            log.i("Detected file modified in-place: '${file.path}'. Updating metadata...");

            final fingerprintBytes = fingerprintRes?.fingerprintBytes ?? storedFingerprint;

            await _trackIndexer.reindexTracksChunk([(trackId, file.path, fingerprintBytes)]);
          } else {
            log.i(
              "File at '${file.path}' was replaced with different audio content (fingerprint mismatch). Re-indexing as new...",
            );
            // Soft-delete the old track record
            await markTrackAsMissing(file.path);
            // Index the new file as a brand new track
            await _trackIndexer.indexTracks([(file, trackHash)]);
          }
        } else {
          log.w("Failed to read tags for modified file: ${file.path}");
        }
      } catch (e) {
        log.e("Error processing tag updates for modified file: $e");
      }
      return;
    }

    // Index the file (this will parse tags and insert it if it's completely new)
    await _trackIndexer.indexTracks([(file, trackHash)]);
  }

  Future<void> markTrackAsMissing(String path) async {
    final normalizedPath = path.normalizePath().toLowerCase();
    await (_db.update(_db.tracks)..where((track) => track.filePath.lower().equals(normalizedPath))).write(
      const TracksCompanion(isMissing: Value(true)),
    );

    // Also remove from player queue if currently loaded
    try {
      await _ref.read(playbackControllerProvider).removeTrackByPath(path);
    } catch (e) {
      log.e("Failed to remove track from playback controller queue: $e");
    }
  }

  Future<void> markTracksInDirectoryAsMissing(String directoryPath) async {
    log.i("Marking tracks under $directoryPath as missing...");
    final normalizedDir = directoryPath.normalizePath().toLowerCase();
    final String separator = p.separator;
    final String queryPrefix = normalizedDir.endsWith(separator) ? normalizedDir : '$normalizedDir$separator';

    final query = _db.selectOnly(_db.tracks)
      ..addColumns([_db.tracks.id, _db.tracks.filePath])
      ..where(_db.tracks.filePath.lower().like('$queryPrefix%'));
    final tracksInDir = await query.get();

    if (tracksInDir.isEmpty) return;

    final trackIds = tracksInDir.map((r) => r.read(_db.tracks.id)!).toList();
    final trackPaths = tracksInDir.map((r) => r.read(_db.tracks.filePath)!).toList();

    await (_db.update(
      _db.tracks,
    )..where((track) => track.id.isIn(trackIds))).write(const TracksCompanion(isMissing: Value(true)));

    // Also remove them from the player queue
    try {
      await _ref.read(playbackControllerProvider).removeTracksByPaths(trackPaths.toSet());
    } catch (e) {
      log.e("Failed to remove tracks from playback controller queue: $e");
    }
  }

  void _startBackgroundFingerprintGenerationIfIdle() {
    final bgTaskService = _ref.read(backgroundTaskServiceProvider);
    final isBusy = bgTaskService.any(
      (t) => (t.id == 'library-scan' || t.id == 'metadata-reindex') && t.status == BackgroundTaskStatus.running,
    );

    if (!isBusy) {
      generateMissingFingerprints().catchError((e) {
        log.e('Idle fingerprint generation failed: $e');
      });
    }
  }
}
