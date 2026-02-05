import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:crypto/crypto.dart';
import 'package:metadata_god/metadata_god.dart';
import 'package:suara/models/scanned_metadata.dart';

// =============================================================================
// PROTOCOL (The Language between Threads)
// =============================================================================

/// Base class for messages sent FROM the Isolate TO the Main Thread
sealed class ScanEvent {}

/// A batch of new/updated songs found.
class ScanBatch extends ScanEvent {
  final List<ScannedMetadata> songs;
  ScanBatch(this.songs);
}

/// The scan is complete. Here are the files that were removed.
class ScanDone extends ScanEvent {
  final List<String> deletedPaths;
  ScanDone(this.deletedPaths);
}

/// Configuration payload passed to the background Isolate.
class ScanConfiguration {
  final List<String> folderPaths;
  final Map<String, int> knownFiles;
  final String cachePath;
  final bool splitArtistsEnabled;
  final SendPort sendPort; // <-- The pipe to talk back to Main Thread

  ScanConfiguration(
    this.folderPaths,
    this.knownFiles,
    this.cachePath,
    this.splitArtistsEnabled,
    this.sendPort,
  );
}

// =============================================================================
// PUBLIC API
// =============================================================================

/// Spawns a background thread and returns a STREAM of events.
Stream<ScanEvent> scanLibraryStream(
  List<String> folderPaths,
  Map<String, int> knownFiles,
  String cachePath,
  bool splitArtistsEnabled,
) {
  final controller = StreamController<ScanEvent>();
  final receivePort = ReceivePort(); // The "Mailbox" for the main thread

  // Spawn the isolate
  Isolate.spawn(
    _internalScanTask,
    ScanConfiguration(
      folderPaths,
      knownFiles,
      cachePath,
      splitArtistsEnabled,
      receivePort.sendPort,
    ),
  ).then((isolate) {
    // When the stream is cancelled (e.g. user leaves), kill the isolate
    controller.onCancel = () {
      receivePort.close();
      isolate.kill();
    };
  });

  // Listen to the mailbox and forward messages to the stream
  receivePort.listen((message) {
    if (message is ScanEvent) {
      controller.add(message);
      if (message is ScanDone) {
        controller.close();
        receivePort.close();
      }
    }
  });

  return controller.stream;
}

// =============================================================================
// INTERNAL BACKGROUND TASK
// =============================================================================

final _separatorRegex = RegExp(r'[;&,]|//');
const int _batchSize = 50; // Process 50 song object at a time

Future<void> _internalScanTask(ScanConfiguration config) async {
  await MetadataGod.initialize();

  List<ScannedMetadata> batchBuffer = [];
  Set<String> foundPaths = {};

  // Helper to flush the buffer
  void flushBatch() {
    if (batchBuffer.isNotEmpty) {
      // Send a COPY of the list to the main thread
      config.sendPort.send(ScanBatch(List.of(batchBuffer)));
      batchBuffer.clear(); // Clear memory immediately
    }
  }

  // --- SETUP ---
  final artDir = Directory('${config.cachePath}/album_art');
  if (!artDir.existsSync()) {
    artDir.createSync(recursive: true);
  }

  try {
    for (String directoryPath in config.folderPaths) {
      final dir = Directory(directoryPath);
      if (!dir.existsSync()) continue;

      final entities = dir.listSync(recursive: true, followLinks: false);

      for (var entity in entities) {
        if (entity is! File || !entity.path.toLowerCase().endsWith('.mp3')) {
          continue;
        }

        foundPaths.add(entity.path);

        // --- CHANGE DETECTION ---
        final lastMod = entity.lastModifiedSync().millisecondsSinceEpoch;
        final dbLastMod = config.knownFiles[entity.path];

        if (dbLastMod == null || lastMod > dbLastMod) {
          try {
            // --- METADATA PARSING ---
            final metadata = await MetadataGod.readMetadata(file: entity.path);

            // Album Art
            String? localArtPath;
            if (metadata.picture != null) {
              final uniqueString = '${metadata.album}_${metadata.artist}';
              final hash = md5.convert(utf8.encode(uniqueString)).toString();
              final artFile = File('${artDir.path}/$hash.jpg');

              if (!artFile.existsSync()) {
                artFile.writeAsBytesSync(metadata.picture!.data);
              }
              localArtPath = artFile.path;
            }

            // Artist Splitting
            final rawArtistString = metadata.artist ?? 'Unknown Artist';
            List<String> artistNames = [];
            if (config.splitArtistsEnabled) {
              artistNames = rawArtistString
                  .split(_separatorRegex)
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList();
            }
            if (artistNames.isEmpty) artistNames = [rawArtistString];

            // --- ADD TO BATCH ---
            batchBuffer.add(
              ScannedMetadata(
                title: metadata.title ?? entity.uri.pathSegments.last,
                artist: artistNames.first,
                allArtists: artistNames,
                album: metadata.album ?? 'Unknown Album',
                genre: metadata.genre ?? '',
                year: metadata.year ?? 0,
                trackNumber: metadata.trackNumber ?? 0,
                discNumber: metadata.discNumber ?? 0,
                duration: Duration(
                  milliseconds: metadata.durationMs?.toInt() ?? 0,
                ),
                path: entity.path,
                artPath: localArtPath,
                timestamp: lastMod,
              ),
            );

            // --- FLUSH IF FULL ---
            if (batchBuffer.length >= _batchSize) {
              flushBatch();
            }
          } catch (e) {
            print("Error parsing ${entity.path}: $e");
          }
        }
      }
    }

    // Flush any remaining items (e.g., if we had 12 items left)
    flushBatch();

    // --- DETECT DELETIONS ---
    final deletedPaths = config.knownFiles.keys
        .where((path) => !foundPaths.contains(path))
        .toList();

    // Signal completion
    config.sendPort.send(ScanDone(deletedPaths));
  } catch (e) {
    print("FATAL SCAN ERROR: $e");
    // Ideally send an error event here, but for now we just close
    config.sendPort.send(ScanDone([]));
  }
}
