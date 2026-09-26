import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nordplayer/data/database/app_database.dart';
import 'package:nordplayer/data/services/indexer/chromaprint_service.dart';
import 'package:nordplayer/data/services/system/background_task_service.dart';
import 'package:nordplayer/utils/logger.dart';

class AudioFingerprintIndexer(final Ref _ref, final AppDatabase _db) with LoggerMixin {
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
      final query = _db.selectOnly(_db.tracks)
        ..addColumns([_db.tracks.id, _db.tracks.filePath])
        ..where(_db.tracks.audioFingerprint.isNull() & _db.tracks.isMissing.equals(false));
      final rows = await query.get();

      if (rows.isEmpty) {
        log.i('No tracks lack fingerprints.');
        bgTaskService.completeTask('fingerprint-generation');
        return;
      }

      final tracksLackingFingerprint = rows.map((r) => (r.read(_db.tracks.id)!, r.read(_db.tracks.filePath)!)).toList();

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
      if (execPath == null) {
        log.w('fpcalc executable not available. Cannot generate audio fingerprints.');
        bgTaskService.completeTask('fingerprint-generation');
        return;
      }

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
        final chunk = tracksLackingFingerprint.sublist(i, end);

        final chunkRequest = (
          tracks: chunk,
          execPath: execPath,
          concurrencyLimit: concurrencyLimit,
          token: RootIsolateToken.instance,
        );

        await Isolate.run(_buildFingerprintChunkClosure(chunkRequest));

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

typedef _FingerprintChunkRequest = ({
  List<(int, String)> tracks,
  String? execPath,
  int concurrencyLimit,
  RootIsolateToken? token,
});

Future<void> Function() _buildFingerprintChunkClosure(_FingerprintChunkRequest request) {
  return () => _fingerprintChunkIsolate(request);
}

Future<void> _fingerprintChunkIsolate(_FingerprintChunkRequest request) async {
  if (request.token != null) {
    BackgroundIsolateBinaryMessenger.ensureInitialized(request.token!);
  }

  if (request.execPath == null) {
    return;
  }

  final db = AppDatabase();
  final fingerprinter = ChromaprintService(request.execPath);

  var index = 0;
  final generatedFingerprints = <(int, Uint8List)>[];

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
          generatedFingerprints.add((trackId, fingerprintRes.fingerprintBytes));
        }
      } catch (e) {
        debugPrint("Error generating fingerprint in isolate for $filePath: $e");
      }
    }
  }

  final workers = List.generate(request.concurrencyLimit, (_) => worker());
  await Future.wait(workers);

  if (generatedFingerprints.isNotEmpty) {
    await db.transaction(() async {
      for (final (trackId, bytes) in generatedFingerprints) {
        await (db.update(
          db.tracks,
        )..where((t) => t.id.equals(trackId))).write(TracksCompanion(audioFingerprint: Value(bytes)));
      }
    });
  }

  await db.close();
}
