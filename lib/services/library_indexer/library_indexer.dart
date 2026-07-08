library;

import 'dart:io';
import 'dart:isolate';

import 'package:audiotags/audiotags.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nordplayer/database/app_database.dart';
import 'package:nordplayer/models/app_config.dart';
import 'package:nordplayer/services/audio_fingerprinter.dart';
import 'package:nordplayer/services/background_task_service.dart';
import 'package:nordplayer/services/config_service.dart';
import 'package:nordplayer/services/logger.dart';
import 'package:nordplayer/services/player_service.dart';
import 'package:nordplayer/utils/audio_metadata_hasher.dart';
import 'package:nordplayer/utils/string_extension.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'scan_library.dart';
part 'track_indexer.dart';

final libraryIndexerProvider = Provider<LibraryIndexer>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return LibraryIndexer(ref, db);
});

class LibraryIndexer with LoggerMixin {
  LibraryIndexer(this._ref, this._db);

  final Ref _ref;
  final AppDatabase _db;

  AppConfig get _appConfig => _ref.read(configServiceProvider).requireValue;

  Set<String> supportedExtensions = {
    '.mp3',
    '.m4a',
    '.flac',
    '.wav',
    '.ogg',
    '.oga',
    '.opus',
    '.aac',
    '.wma',
    '.mka',
    '.ape',
    '.wv',
  };

  // Map<ArtistName, ArtistId>
  final Map<String, int> _artistCache = {};
  // Map<"AlbumName-AlbumArtist", AlbumId>
  final Map<String, int> _albumCache = {};

  bool _isFingerprintTaskCancelled = false;

  Future<void> generateMissingFingerprints({void Function(int processed, int total)? onProgress}) async {
    _isFingerprintTaskCancelled = false;
    log.i('Starting background generation of missing audio fingerprints...');

    final taskService = _ref.read(backgroundTaskServiceProvider.notifier);
    taskService.startTask(
      id: 'fingerprint-generation',
      name: 'Generating Audio Fingerprints',
      message: 'Fetching tracks lacking fingerprints...',
      isIndeterminate: true,
    );

    try {
      final tracksLackingFingerprint = await (_db.select(
        _db.tracks,
      )..where((t) => t.audioFingerprint.isNull() & t.isMissing.equals(false))).get();

      if (tracksLackingFingerprint.isEmpty) {
        log.i('No tracks lack fingerprints.');
        taskService.completeTask('fingerprint-generation');
        return;
      }

      final total = tracksLackingFingerprint.length;
      int processed = 0;

      onProgress?.call(processed, total);
      taskService.updateProgress(
        'fingerprint-generation',
        processed: processed,
        total: total,
        message: 'Generating fingerprint $processed of $total...',
        isIndeterminate: false,
      );

      for (final track in tracksLackingFingerprint) {
        if (_isFingerprintTaskCancelled) {
          log.i('Fingerprint generation task cancelled due to incoming scan/re-index.');
          taskService.completeTask('fingerprint-generation');
          return;
        }

        final file = File(track.filePath);
        if (!await file.exists()) {
          processed++;
          onProgress?.call(processed, total);
          taskService.updateProgress(
            'fingerprint-generation',
            processed: processed,
            total: total,
            message: 'Generating fingerprint $processed of $total...',
          );
          continue;
        }

        try {
          final fingerprintRes = await _ref.read(audioFingerprinterProvider).calculateFingerprint(file.path);
          if (fingerprintRes != null) {
            await (_db.update(_db.tracks)..where((t) => t.id.equals(track.id))).write(
              TracksCompanion(audioFingerprint: Value(fingerprintRes.fingerprintBytes)),
            );
          }
        } catch (e) {
          log.e("Error generating fingerprint for ${track.filePath}: $e");
        }

        processed++;
        onProgress?.call(processed, total);
        taskService.updateProgress(
          'fingerprint-generation',
          processed: processed,
          total: total,
          message: 'Generating fingerprint $processed of $total...',
        );
      }

      log.i('Background audio fingerprint generation complete.');
      taskService.completeTask('fingerprint-generation');
    } catch (e, s) {
      log.e("Error during audio fingerprint generation: $e", error: e, stackTrace: s);
      taskService.failTask('fingerprint-generation', e.toString());
      rethrow;
    }
  }

  Future<void> processSingleFile(File file) async {
    log.i("Processing individual file: ${file.path}");

    final trackHash = AudioMetadataHasher.calculateHash(file);

    // Check if the file was moved/renamed (hash matches an existing track)
    final existingTrackByHash =
        await (_db.select(_db.tracks)
              ..where((t) => t.fileHash.equals(trackHash))
              ..limit(1))
            .getSingleOrNull();

    final normalizedPath = file.path.normalizePath().toLowerCase();

    if (existingTrackByHash != null) {
      final normalizedDbPath = existingTrackByHash.filePath.normalizePath().toLowerCase();
      if (normalizedDbPath != normalizedPath) {
        log.i(
          "Detected file moved/renamed via watcher: '${existingTrackByHash.filePath}' -> '${file.path}'. Reconnecting database entry...",
        );
      }
      await (_db.update(_db.tracks)..where((t) => t.id.equals(existingTrackByHash.id))).write(
        TracksCompanion(filePath: Value(file.path), isMissing: const Value(false)),
      );
      return;
    }

    // Check if the file already exists in the database by path
    final existingTrackByPath =
        await (_db.select(_db.tracks)
              ..where((t) => t.filePath.lower().equals(normalizedPath))
              ..limit(1))
            .getSingleOrNull();

    if (existingTrackByPath != null) {
      try {
        final trackTag = await AudioTags.read(file.path);
        if (trackTag != null) {
          // Safeguard: Verify if it is the same audio file by checking the audio fingerprint
          final fingerprintRes = await _ref.read(audioFingerprinterProvider).calculateFingerprint(file.path);

          bool isSameTrack = false;
          if (fingerprintRes != null) {
            final storedFingerprint = existingTrackByPath.audioFingerprint;
            if (storedFingerprint != null) {
              final fingerprinter = _ref.read(audioFingerprinterProvider);
              final storedRaw = fingerprinter.parseRawFingerprint(storedFingerprint);
              if (storedRaw != null) {
                final similarity = fingerprinter.compareRawFingerprints(fingerprintRes.rawFingerprint, storedRaw);
                isSameTrack = similarity >= 0.85;
                log.i(
                  "Calculated fingerprint similarity for '${file.path}': ${(similarity * 100).toStringAsFixed(1)}% (match: $isSameTrack)",
                );
              }
            } else {
              // Fallback to duration for existing tracks that do not have fingerprints yet
              final newDurationMs = fingerprintRes.durationMs;
              final durationDifferenceMs = (existingTrackByPath.durationMs - newDurationMs).abs();
              isSameTrack = durationDifferenceMs <= 1000;

              if (isSameTrack) {
                // Cache the fingerprint back to the DB record
                await (_db.update(_db.tracks)..where((t) => t.id.equals(existingTrackByPath.id))).write(
                  TracksCompanion(audioFingerprint: Value(fingerprintRes.fingerprintBytes)),
                );
              }
            }
          } else {
            // Hard fallback to duration if fingerprinting failed
            final newDurationMs = (trackTag.duration ?? 0) * 1000;
            final durationDifferenceMs = (existingTrackByPath.durationMs - newDurationMs).abs();
            isSameTrack = durationDifferenceMs <= 1000;
          }

          if (isSameTrack) {
            log.i("Detected file modified in-place: '${file.path}'. Updating metadata...");

            final cacheDir = await getApplicationCacheDirectory();
            final fingerprintBytes = fingerprintRes?.fingerprintBytes ?? existingTrackByPath.audioFingerprint;

            final request = ReindexTracksChunkIsolateRequest(
              tracks: [(existingTrackByPath.id, file.path, fingerprintBytes)],
              artistExclusions: _appConfig.artistExclusions.map((e) => e.toLowerCase().trim()).toSet(),
              artistDelimiters: _appConfig.artistDelimiters.toList(),
              artistCache: Map<String, int>.from(_artistCache),
              albumCache: Map<String, int>.from(_albumCache),
              cacheDirPath: cacheDir.path,
            );

            final response = await Isolate.run(() => _reindexTracksChunkIsolate(request));

            _artistCache.addAll(response.artistCache);
            _albumCache.addAll(response.albumCache);
          } else {
            log.i(
              "File at '${file.path}' was replaced with different audio content (fingerprint mismatch). Re-indexing as new...",
            );
            // Soft-delete the old track record
            await markTrackAsMissing(file.path);
            // Index the new file as a brand new track
            await indexTracks([(file, trackHash)]);
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
    await indexTracks([(file, trackHash)]);
  }

  Future<void> markTrackAsMissing(String path) async {
    final normalizedPath = path.normalizePath().toLowerCase();
    await (_db.update(_db.tracks)..where((track) => track.filePath.lower().equals(normalizedPath))).write(
      const TracksCompanion(isMissing: Value(true)),
    );

    // Also remove from player queue if currently loaded
    try {
      await _ref.read(playerServiceProvider).removeTrackByPath(path);
    } catch (e) {
      log.e("Failed to remove track from player service queue: $e");
    }
  }

  Future<void> markTracksInDirectoryAsMissing(String directoryPath) async {
    log.i("Marking tracks under $directoryPath as missing...");
    final normalizedDir = directoryPath.normalizePath().toLowerCase();
    final String separator = p.separator;
    final String queryPrefix = normalizedDir.endsWith(separator) ? normalizedDir : '$normalizedDir$separator';

    // Get all track paths under this directory first to remove them from the queue
    final tracksInDir = await (_db.select(
      _db.tracks,
    )..where((track) => track.filePath.lower().like('$queryPrefix%'))).get();

    await (_db.update(_db.tracks)..where((track) => track.filePath.lower().like('$queryPrefix%'))).write(
      const TracksCompanion(isMissing: Value(true)),
    );

    // Also remove them from the player queue
    try {
      final playerService = _ref.read(playerServiceProvider);
      for (final track in tracksInDir) {
        await playerService.removeTrackByPath(track.filePath);
      }
    } catch (e) {
      log.e("Failed to remove tracks from player service queue: $e");
    }
  }

  void _startBackgroundFingerprintGenerationIfIdle() {
    final tasks = _ref.read(backgroundTaskServiceProvider);
    final isBusy = tasks.any(
      (t) => (t.id == 'library-scan' || t.id == 'metadata-reindex') && t.status == BackgroundTaskStatus.running,
    );

    if (!isBusy) {
      generateMissingFingerprints().catchError((e) {
        log.e('Idle fingerprint generation failed: $e');
      });
    }
  }
}
