import 'dart:io';
import 'dart:isolate';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nordplayer/config/app_config.dart';
import 'package:nordplayer/data/database/app_database.dart';
import 'package:nordplayer/data/repositories/playback_repository.dart';
import 'package:nordplayer/data/repositories/track_repository.dart';
import 'package:nordplayer/data/services/indexer/track_indexer.dart';
import 'package:nordplayer/data/services/system/background_task_service.dart';
import 'package:nordplayer/data/services/system/config_service.dart';
import 'package:nordplayer/utils/audio_metadata_hasher.dart';
import 'package:nordplayer/utils/logger.dart';
import 'package:nordplayer/utils/string_extension.dart';

class LibraryScanner(
  final Ref _ref,
  final AppDatabase _db,
  final TrackIndexer _trackIndexer,
  final VoidCallback _onCancelFingerprintTask,
) with LoggerMixin {
  AppConfig get _appConfig => _ref.read(configServiceProvider);

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

      final query = _db.selectOnly(_db.tracks)
        ..addColumns([
          _db.tracks.id,
          _db.tracks.filePath,
          _db.tracks.fileHash,
          _db.tracks.isMissing,
          _db.tracks.audioFingerprint,
        ]);
      final trackRows = await query.get();
      log.i('[Benchmark] Loaded ${trackRows.length} existing tracks from DB in ${stepStopwatch.elapsedMilliseconds}ms');
      stepStopwatch.reset();

      final Map<String, _TrackScanSummary> existingTracksMap = {};
      final Map<String, String> existingTrackHashes = {};
      for (final row in trackRows) {
        final filePath = row.read(_db.tracks.filePath)!;
        final fileHash = row.read(_db.tracks.fileHash)!;
        final summary = (
          id: row.read(_db.tracks.id)!,
          filePath: filePath,
          fileHash: fileHash,
          isMissing: row.read(_db.tracks.isMissing)!,
          audioFingerprint: row.read(_db.tracks.audioFingerprint),
        );
        final normalized = filePath.normalizePath().toLowerCase();
        existingTracksMap[normalized] = summary;
        existingTrackHashes[normalized] = fileHash;
      }

      log.i(
        '[Benchmark] Loaded ${trackRows.length} existing tracks into maps in ${stepStopwatch.elapsedMilliseconds}ms',
      );
      stepStopwatch.reset();

      final Set<String> existingTracksPathNormalized = existingTracksMap.keys.toSet();

      final ignoredPathsList = await _db.select(_db.ignoredPaths).get();
      final Set<String> ignoredPathsSet = {for (final p in ignoredPathsList) p.filePath.normalizePath().toLowerCase()};

      log.i(
        '[Benchmark] Loaded ${ignoredPathsList.length} ignored paths from DB in ${stepStopwatch.elapsedMilliseconds}ms',
      );
      stepStopwatch.reset();

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

      final sendPort = receivePort.sendPort;
      final scanRequest = (
        trackDirectories: _appConfig.trackDirectories.toList(),
        supportedExtensions: supportedExtensions.toSet(),
        existingTrackHashes: existingTrackHashes,
        ignoredPathsSet: ignoredPathsSet,
        sendPort: sendPort,
      );

      _ScanLibraryResponse isolateResponse;
      try {
        isolateResponse = await Isolate.run(_buildScanDirectoriesClosure(scanRequest));
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

        final separatorPattern = _trackIndexer.artistSeparatorPattern;
        const int chunkSize = 50;
        for (var i = 0; i < modifiedPayload.length; i += chunkSize) {
          final end = (i + chunkSize < modifiedPayload.length) ? i + chunkSize : modifiedPayload.length;
          final chunk = modifiedPayload.sublist(i, end);

          await _trackIndexer.reindexTracksChunk(chunk, separatorPattern: separatorPattern);
        }
      }

      final tracksToMarkAsMissingNormalized = existingTracksPathNormalized.difference(supportedFilesFoundOnDisk);
      final missingTracksMap = <int, _TrackScanSummary>{
        for (final path in tracksToMarkAsMissingNormalized) existingTracksMap[path]!.id: existingTracksMap[path]!,
      };
      const int batchSize = 500;
      List<(File, String)> newTracksToProcess = [];

      if (isolateResponse.newTracks.isNotEmpty && tracksToMarkAsMissingNormalized.isNotEmpty) {
        Map<String, _TrackScanSummary> missingTracksByHash = {};
        for (final track in missingTracksMap.values) {
          missingTracksByHash[track.fileHash] = track;
        }

        for (final newTrackPath in isolateResponse.newTracks.keys) {
          final newTrackHash = isolateResponse.newTracks[newTrackPath]!;

          if (missingTracksByHash.containsKey(newTrackHash)) {
            final oldTrack = missingTracksByHash[newTrackHash]!;
            log.i(
              "Detected file moved/renamed: '${oldTrack.filePath}' -> '$newTrackPath'. Reconnecting database entry...",
            );

            await _ref.read(trackRepositoryProvider).updateTrackFilePath(oldTrack.id, newTrackPath);

            missingTracksMap.remove(oldTrack.id);
          } else {
            newTracksToProcess.add((File(newTrackPath), newTrackHash));
          }
        }
      } else {
        newTracksToProcess = isolateResponse.newTracks.entries.map((e) => (File(e.key), e.value)).toList();
      }

      if (missingTracksMap.isNotEmpty) {
        final missingIds = missingTracksMap.keys.toList();
        final missingPaths = missingTracksMap.values.map((t) => t.filePath).toList();

        log.i('Marking ${missingIds.length} removed tracks as missing in database...');

        await _ref.read(trackRepositoryProvider).markTracksMissingByIds(missingIds);
        log.i('[Benchmark] Updated missing tracks in DB in ${stepStopwatch.elapsedMilliseconds}ms');
        stepStopwatch.reset();

        // Also remove missing tracks from the playback repository queue
        try {
          await _ref.read(playbackRepositoryProvider).removeTracksByPaths(missingPaths.toSet());
        } catch (e) {
          log.e("Failed to remove missing tracks from playback repository queue: $e");
        }
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
        final previouslyMissingIds = supportedFilesFoundOnDisk
            .where((path) => existingTracksMap[path]?.isMissing == true)
            .map((path) => existingTracksMap[path]!.id)
            .toList();

        if (previouslyMissingIds.isNotEmpty) {
          for (var i = 0; i < previouslyMissingIds.length; i += batchSize) {
            final end = (i + batchSize < previouslyMissingIds.length) ? i + batchSize : previouslyMissingIds.length;
            final batch = previouslyMissingIds.sublist(i, end);
            await (_db.update(
              _db.tracks,
            )..where((track) => track.id.isIn(batch))).write(const TracksCompanion(isMissing: Value(false)));
          }
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

// =========================================== Background Isolate Workers & Records ===========================================

typedef _TrackScanSummary = ({int id, String filePath, String fileHash, bool isMissing, Uint8List? audioFingerprint});

typedef _ScanLibraryRequest = ({
  List<String> trackDirectories,
  Set<String> supportedExtensions,
  Map<String, String> existingTrackHashes,
  Set<String> ignoredPathsSet,
  SendPort sendPort,
});

typedef _ScanLibraryResponse = ({
  Set<String> supportedFilesFoundOnDisk,
  Map<String, String> newTracks,
  Map<String, String> modifiedTracks,
});

Future<_ScanLibraryResponse> Function() _buildScanDirectoriesClosure(_ScanLibraryRequest request) {
  return () => _scanDirectoriesAndHashIsolate(request);
}

Future<_ScanLibraryResponse> _scanDirectoriesAndHashIsolate(_ScanLibraryRequest request) async {
  final supportedFilesFoundOnDisk = <String>{};
  final newTracks = <String, String>{};
  final modifiedTracks = <String, String>{};

  final List<(File, String)> filesToScan = [];

  for (String path in request.trackDirectories) {
    final trackDirectory = Directory(path);
    if (!await trackDirectory.exists()) continue;

    final entities = trackDirectory.list(recursive: true, followLinks: false).handleError((error) {
      debugPrint('Could not access folder in isolate: $error');
    });

    await for (FileSystemEntity entity in entities) {
      if (entity is File) {
        final dot = entity.path.lastIndexOf('.');
        final isSupported = dot != -1 && request.supportedExtensions.contains(entity.path.substring(dot).toLowerCase());
        if (isSupported) {
          final normalizedEntityPath = entity.path.normalizePath().toLowerCase();

          if (request.ignoredPathsSet.contains(normalizedEntityPath)) {
            continue;
          }

          filesToScan.add((entity, normalizedEntityPath));
        }
      }
    }
  }

  final total = filesToScan.length;
  int processed = 0;

  for (final (file, normalizedEntityPath) in filesToScan) {
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

  return (supportedFilesFoundOnDisk: supportedFilesFoundOnDisk, newTracks: newTracks, modifiedTracks: modifiedTracks);
}
