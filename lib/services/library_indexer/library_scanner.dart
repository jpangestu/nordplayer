import 'dart:io';
import 'dart:isolate';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nordplayer/database/app_database.dart';
import 'package:nordplayer/models/app_config.dart';
import 'package:nordplayer/services/background_task_service.dart';
import 'package:nordplayer/services/config_service.dart';
import 'package:nordplayer/services/library_indexer/track_indexer.dart';
import 'package:nordplayer/services/logger.dart';
import 'package:nordplayer/utils/audio_metadata_hasher.dart';
import 'package:nordplayer/utils/string_extension.dart';
import 'package:path/path.dart' as p;

class LibraryScanner with LoggerMixin {
  LibraryScanner(this._ref, this._db, this._trackIndexer, this._onCancelFingerprintTask);

  final Ref _ref;
  final AppDatabase _db;
  final TrackIndexer _trackIndexer;
  final VoidCallback _onCancelFingerprintTask;

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

  Future<void> scanLibrary({void Function(int processed, int total)? onProgress, VoidCallback? onComplete}) async {
    final benchmarkTotal = Stopwatch()..start();
    _onCancelFingerprintTask();
    log.i('Starting full library scan...');
    onProgress?.call(0, 0);

    final bgTaskService = _ref.read(backgroundTaskServiceProvider.notifier);
    bgTaskService.startTask(
      id: 'library-scan',
      name: 'Scanning Library',
      message: 'Scanning folders for audio files...',
      isIndeterminate: true,
    );

    try {
      final stepStopwatch = Stopwatch()..start();

      final existingTracks = await _db.select(_db.tracks).get();
      log.i(
        '[Benchmark] Loaded ${existingTracks.length} existing tracks from DB in ${stepStopwatch.elapsedMilliseconds}ms',
      );
      stepStopwatch.reset();

      final Map<String, Track> existingTracksMap = {
        for (final track in existingTracks) track.filePath.normalizePath().toLowerCase(): track,
      };

      log.i(
        '[Benchmark] Loaded ${existingTracks.length} existing tracks into map in ${stepStopwatch.elapsedMilliseconds}ms',
      );
      stepStopwatch.reset();

      final Set<String> existingTracksPathNormalized = existingTracksMap.keys.toSet();

      final ignoredPathsList = await _db.select(_db.ignoredPaths).get();
      final Set<String> ignoredPathsSet = {for (final p in ignoredPathsList) p.filePath.normalizePath().toLowerCase()};

      log.i(
        '[Benchmark] Loaded ${ignoredPathsList.length} ignored paths from DB in ${stepStopwatch.elapsedMilliseconds}ms',
      );
      stepStopwatch.reset();

      final Map<String, String> existingTrackHashes = {
        for (final track in existingTracks) track.filePath.normalizePath().toLowerCase(): track.fileHash,
      };

      final receivePort = ReceivePort();
      final subscription = receivePort.listen((message) {
        if (message is (int, int)) {
          final processed = message.$1;
          final total = message.$2;
          bgTaskService.updateProgress(
            'library-scan',
            processed: processed,
            total: total,
            message: 'Scanning library for updates: $processed of $total',
            isIndeterminate: false,
          );
        }
      });

      final request = ScanLibraryIsolateRequest(
        trackDirectories: _appConfig.trackDirectories.toList(),
        supportedExtensions: supportedExtensions.toSet(),
        existingTrackHashes: existingTrackHashes,
        ignoredPathsSet: ignoredPathsSet,
        sendPort: receivePort.sendPort,
      );

      ScanLibraryIsolateResponse isolateResponse;
      try {
        isolateResponse = await Isolate.run(_buildScanLibraryIsolateClosure(request));
      } finally {
        subscription.cancel();
        receivePort.close();
      }
      log.i(
        '[Benchmark] Finished iterating Directory.list and hashing files in isolate in ${stepStopwatch.elapsedMilliseconds}ms',
      );
      stepStopwatch.reset();

      final supportedFilesFoundOnDisk = isolateResponse.supportedFilesFoundOnDisk;

      // Update modified tracks
      if (isolateResponse.modifiedTracks.isNotEmpty) {
        log.i("Detected ${isolateResponse.modifiedTracks.length} modified tracks. Re-indexing metadata...");

        final List<(int, String, Uint8List?)> modifiedPayload = [];

        for (final modifiedPath in isolateResponse.modifiedTracks.keys) {
          final normalizedPath = modifiedPath.normalizePath().toLowerCase();
          final track = existingTracksMap[normalizedPath]!;
          modifiedPayload.add((track.id, modifiedPath, track.audioFingerprint));
        }

        const int chunkSize = 50;
        for (var i = 0; i < modifiedPayload.length; i += chunkSize) {
          final end = (i + chunkSize < modifiedPayload.length) ? i + chunkSize : modifiedPayload.length;
          final chunk = modifiedPayload.sublist(i, end);

          await _trackIndexer.reindexTracksChunk(chunk);
        }
      }

      final tracksToMarkAsMissingNormalized = existingTracksPathNormalized.difference(supportedFilesFoundOnDisk);
      final tracksToMarkAsMissing = tracksToMarkAsMissingNormalized
          .map((path) => existingTracksMap[path]!.filePath)
          .toList();

      final missingTracks = await (_db.select(_db.tracks)..where((t) => t.filePath.isIn(tracksToMarkAsMissing))).get();
      List<(File, String)> newTracksToProcess = [];

      if (isolateResponse.newTracks.isNotEmpty && tracksToMarkAsMissingNormalized.isNotEmpty) {
        Map<String, Track> missingTracksByHash = {};
        for (final track in missingTracks) {
          missingTracksByHash[track.fileHash] = track;
        }

        for (final newTrackPath in isolateResponse.newTracks.keys) {
          final newTrackHash = isolateResponse.newTracks[newTrackPath]!;

          if (missingTracksByHash.containsKey(newTrackHash)) {
            final oldTrack = missingTracksByHash[newTrackHash]!;
            log.i(
              "Detected file moved/renamed: '${oldTrack.filePath}' -> '$newTrackPath'. Reconnecting database entry...",
            );

            await (_db.update(_db.tracks)..where((t) => t.id.equals(oldTrack.id))).write(
              TracksCompanion(filePath: Value(newTrackPath), isMissing: const Value(false)),
            );

            tracksToMarkAsMissing.remove(oldTrack.filePath);
          } else {
            newTracksToProcess.add((File(newTrackPath), newTrackHash));
          }
        }
      } else {
        newTracksToProcess = isolateResponse.newTracks.entries.map((e) => (File(e.key), e.value)).toList();
      }

      if (tracksToMarkAsMissing.isNotEmpty) {
        log.i('Marking ${tracksToMarkAsMissing.length} removed tracks as missing in database...');

        await (_db.update(_db.tracks)..where((track) => track.filePath.isIn(tracksToMarkAsMissing))).write(
          const TracksCompanion(isMissing: Value(true)),
        );
        log.i('[Benchmark] Updated missing tracks in DB in ${stepStopwatch.elapsedMilliseconds}ms');
        stepStopwatch.reset();
      }

      if (newTracksToProcess.isNotEmpty) {
        log.i('Found ${newTracksToProcess.length} new track(s). Processing...');

        await _trackIndexer.indexTracks(
          newTracksToProcess,
          onProgress: (processed, total) {
            onProgress?.call(processed, total);
            bgTaskService.updateProgress(
              'library-scan',
              processed: processed,
              total: total,
              message: 'Indexing track metadata: $processed of $total',
              isIndeterminate: false,
            );
          },
        );
        log.i('[Benchmark] Finished _indexTracks (inserts) in ${stepStopwatch.elapsedMilliseconds}ms');
        stepStopwatch.reset();
      } else {
        log.i('No new tracks found. Library is up to date');
      }

      if (supportedFilesFoundOnDisk.isNotEmpty) {
        final previouslyMissingPathsInDb = supportedFilesFoundOnDisk
            .where((path) => existingTracksMap[path]?.isMissing == true)
            .map((path) => existingTracksMap[path]!.filePath)
            .toList();

        if (previouslyMissingPathsInDb.isNotEmpty) {
          await (_db.update(_db.tracks)..where((track) => track.filePath.isIn(previouslyMissingPathsInDb))).write(
            const TracksCompanion(isMissing: Value(false)),
          );
        }
        log.i('[Benchmark] Unmarked found tracks as missing in DB in ${stepStopwatch.elapsedMilliseconds}ms');
        stepStopwatch.reset();
      }

      bgTaskService.completeTask('library-scan');
      log.i('[Benchmark] ====== SCAN LIBRARY COMPLETED IN ${benchmarkTotal.elapsedMilliseconds}ms ======');

      onComplete?.call();
    } catch (e, s) {
      log.e("Error scanning library: $e", error: e, stackTrace: s);
      bgTaskService.failTask('library-scan', e.toString());
      rethrow;
    }
  }
}

// =========================================== Background Isolate Workers & Classes ===========================================

class ScanLibraryIsolateRequest {
  const ScanLibraryIsolateRequest({
    required this.trackDirectories,
    required this.supportedExtensions,
    required this.existingTrackHashes,
    required this.ignoredPathsSet,
    required this.sendPort,
  });

  final List<String> trackDirectories;
  final Set<String> supportedExtensions;
  final Map<String, String> existingTrackHashes;
  final Set<String> ignoredPathsSet;
  final SendPort sendPort;
}

class ScanLibraryIsolateResponse {
  const ScanLibraryIsolateResponse({
    required this.supportedFilesFoundOnDisk,
    required this.newTracks,
    required this.modifiedTracks,
  });

  final Set<String> supportedFilesFoundOnDisk;
  final Map<String, String> newTracks;
  final Map<String, String> modifiedTracks;
}

Future<ScanLibraryIsolateResponse> Function() _buildScanLibraryIsolateClosure(ScanLibraryIsolateRequest request) {
  return () => _scanDirectoriesAndHashIsolate(request);
}

Future<ScanLibraryIsolateResponse> _scanDirectoriesAndHashIsolate(ScanLibraryIsolateRequest request) async {
  final supportedFilesFoundOnDisk = <String>{};
  final newTracks = <String, String>{};
  final modifiedTracks = <String, String>{};

  final List<File> filesToScan = [];

  for (String path in request.trackDirectories) {
    final trackDirectory = Directory(path);
    if (!await trackDirectory.exists()) continue;

    final entities = trackDirectory.list(recursive: true, followLinks: false).handleError((error) {
      debugPrint('Could not access folder in isolate: $error');
    });

    await for (FileSystemEntity entity in entities) {
      if (entity is File && request.supportedExtensions.contains(p.extension(entity.path).toLowerCase())) {
        final normalizedEntityPath = entity.path.normalizePath().toLowerCase();

        if (request.ignoredPathsSet.contains(normalizedEntityPath)) {
          continue;
        }

        filesToScan.add(entity);
      }
    }
  }

  final total = filesToScan.length;
  int processed = 0;

  for (final file in filesToScan) {
    final normalizedEntityPath = file.path.normalizePath().toLowerCase();
    supportedFilesFoundOnDisk.add(normalizedEntityPath);

    if (!request.existingTrackHashes.containsKey(normalizedEntityPath)) {
      final hash = AudioMetadataHasher.calculateHash(file);
      newTracks[file.path] = hash;
    } else {
      final oldHash = request.existingTrackHashes[normalizedEntityPath];
      final currentHash = AudioMetadataHasher.calculateHash(file);
      if (currentHash != oldHash) {
        modifiedTracks[file.path] = currentHash;
      }
    }

    processed++;
    if (processed % 5 == 0 || processed == total) {
      request.sendPort.send((processed, total));
    }
  }

  return ScanLibraryIsolateResponse(
    supportedFilesFoundOnDisk: supportedFilesFoundOnDisk,
    newTracks: newTracks,
    modifiedTracks: modifiedTracks,
  );
}
