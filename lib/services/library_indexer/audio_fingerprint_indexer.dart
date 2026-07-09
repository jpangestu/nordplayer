import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nordplayer/database/app_database.dart';
import 'package:nordplayer/services/background_task_service.dart';
import 'package:nordplayer/services/chromaprint_service.dart';
import 'package:nordplayer/services/logger.dart';

class AudioFingerprintIndexer with LoggerMixin {
  AudioFingerprintIndexer(this._ref, this._db);

  final Ref _ref;
  final AppDatabase _db;
  bool _isCancelled = false;

  void cancel() {
    _isCancelled = true;
    log.i('Fingerprint generation cancel requested.');
  }

  Future<void> generateAudioFingerprints({void Function(int processed, int total)? onProgress}) async {
    _isCancelled = false;
    log.i('Starting background generation of audio fingerprints...');

    final bgTaskService = _ref.read(backgroundTaskServiceProvider.notifier);
    bgTaskService.startTask(
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
        bgTaskService.completeTask('fingerprint-generation');
        return;
      }

      final total = tracksLackingFingerprint.length;
      int processed = 0;

      onProgress?.call(processed, total);
      bgTaskService.updateProgress(
        'fingerprint-generation',
        processed: processed,
        total: total,
        message: 'Generating fingerprint: $processed of $total',
        isIndeterminate: false,
      );

      final execPath = await _ref.read(chromaprintServiceProvider).fpcalcPath;
      const int chunkSize = 25;
      // Use half of the CPU cores, but at least 1, and cap it at 4 to prevent disk I/O bottlenecks.
      final concurrencyLimit = math.max(1, math.min(4, Platform.numberOfProcessors ~/ 2));

      for (var i = 0; i < tracksLackingFingerprint.length; i += chunkSize) {
        if (_isCancelled) {
          log.i('Fingerprint generation task cancelled due to incoming scan/re-index.');
          bgTaskService.completeTask('fingerprint-generation');
          return;
        }

        final end = (i + chunkSize < tracksLackingFingerprint.length) ? i + chunkSize : tracksLackingFingerprint.length;
        final chunk = tracksLackingFingerprint.sublist(i, end).map((t) => (t.id, t.filePath)).toList();

        final request = FingerprintChunkIsolateRequest(
          tracks: chunk,
          execPath: execPath,
          concurrencyLimit: concurrencyLimit,
          token: RootIsolateToken.instance,
        );

        await Isolate.run(_buildFingerprintIsolateClosure(request));

        processed += chunk.length;
        onProgress?.call(processed, total);
        bgTaskService.updateProgress(
          'fingerprint-generation',
          processed: processed,
          total: total,
          message: 'Generating fingerprint: $processed of $total',
        );
      }

      log.i('Background audio fingerprint generation complete.');
      bgTaskService.completeTask('fingerprint-generation');
    } catch (e, s) {
      log.e("Error during audio fingerprint generation: $e", error: e, stackTrace: s);
      bgTaskService.failTask('fingerprint-generation', e.toString());
      rethrow;
    }
  }
}

class FingerprintChunkIsolateRequest {
  const FingerprintChunkIsolateRequest({
    required this.tracks,
    required this.execPath,
    required this.concurrencyLimit,
    required this.token,
  });

  final List<(int, String)> tracks;
  final String? execPath;
  final int concurrencyLimit;
  final RootIsolateToken? token;
}

Future<void> Function() _buildFingerprintIsolateClosure(FingerprintChunkIsolateRequest request) {
  return () => _fingerprintChunkIsolate(request);
}

Future<void> _fingerprintChunkIsolate(FingerprintChunkIsolateRequest request) async {
  if (request.token != null) {
    BackgroundIsolateBinaryMessenger.ensureInitialized(request.token!);
  }

  if (request.execPath == null) {
    return;
  }

  final db = AppDatabase();
  final fingerprinter = ChromaprintService(request.execPath);

  var index = 0;
  Future<void> worker() async {
    while (index < request.tracks.length) {
      final item = request.tracks[index++];
      final trackId = item.$1;
      final filePath = item.$2;

      final file = File(filePath);
      if (!await file.exists()) continue;

      try {
        final fingerprintRes = await fingerprinter.calculateAudioFingerprint(filePath);
        if (fingerprintRes != null) {
          await (db.update(db.tracks)..where((t) => t.id.equals(trackId))).write(
            TracksCompanion(audioFingerprint: Value(fingerprintRes.fingerprintBytes)),
          );
        }
      } catch (e) {
        debugPrint("Error generating fingerprint in isolate for $filePath: $e");
      }
    }
  }

  final workers = List.generate(request.concurrencyLimit, (_) => worker());
  await Future.wait(workers);

  await db.close();
}
