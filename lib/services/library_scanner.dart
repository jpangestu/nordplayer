import 'dart:io';
import 'dart:isolate';

import 'package:metadata_god/metadata_god.dart';

import 'package:suara/models/song.dart';

// Input Configuration for the Isolate
class ScanConfiguration {
  final List<String> folderPaths;
  // A snapshot of what the DB already knows: {Path: Timestamp}
  final Map<String, int> knownFiles;

  ScanConfiguration(this.folderPaths, this.knownFiles);
}

// The output returning ONLY changes
class ScanResult {
  final List<Song> newOrUpdatedSongs; // Files that were added or edited
  final List<String> deletedPaths; // Files that no longer exist on disk

  ScanResult(this.newOrUpdatedSongs, this.deletedPaths);
}

Future<ScanResult> scanLibrary(ScanConfiguration config) async {
  return await Isolate.run(() => _internalScanTask(config));
}

Future<ScanResult> _internalScanTask(ScanConfiguration config) async {
  await MetadataGod.initialize();

  List<Song> songsToUpsert = [];
  Set<String> foundPaths =
      {}; // Keep track of every file we actually see on disk

  for (String directoryPath in config.folderPaths) {
    final dir = Directory(directoryPath);
    if (!dir.existsSync()) continue;

    // Recursive list of all files
    final entities = dir.listSync(recursive: true, followLinks: false);

    for (var entity in entities) {
      // Filter for MP3s (add other extensions here if needed)
      if (entity is File && entity.path.toLowerCase().endsWith('.mp3')) {
        foundPaths.add(entity.path);

        // --- THE OPTIMIZATION CORE ---
        final lastMod = entity.lastModifiedSync().millisecondsSinceEpoch;
        final dbLastMod = config.knownFiles[entity.path];

        // Logic: Parse ONLY if it's new (dbLastMod == null)
        // OR if the file is newer than the DB record (lastMod > dbLastMod)
        if (dbLastMod == null || lastMod > dbLastMod) {
          try {
            final metadata = await MetadataGod.readMetadata(file: entity.path);

            final song = Song(
              title: metadata.title ?? entity.uri.pathSegments.last,
              artist: metadata.artist ?? 'Unknown Artist',
              path: entity.path,
              duration: Duration(
                milliseconds: metadata.durationMs?.toInt() ?? 0,
              ),
              timestamp: lastMod,
            );

            songsToUpsert.add(song);
          } catch (e) {
            print("Error parsing ${entity.path}: $e");
          }
        }
      }
    }
  }

  // If a path is in 'knownFiles' (DB) but was NOT in 'foundPaths' (Disk),
  // it means the user deleted the file. Remove it from DB.
  final deletedPaths = config.knownFiles.keys
      .where((path) => !foundPaths.contains(path))
      .toList();

  return ScanResult(songsToUpsert, deletedPaths);
}
