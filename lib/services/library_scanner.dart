import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:crypto/crypto.dart';
import 'package:metadata_god/metadata_god.dart';

import 'package:suara/models/song.dart';

// Input Configuration for the Isolate
class ScanConfiguration {
  final List<String> folderPaths;
  // A snapshot of what the DB already knows: {Path: Timestamp}
  final Map<String, int> knownFiles;
  final String cachePath;

  ScanConfiguration(this.folderPaths, this.knownFiles, this.cachePath);
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

  // Create the art directory if it doesn't exist
  final artDir = Directory('${config.cachePath}/album_art'); 

  if (!artDir.existsSync()) {
    artDir.createSync(recursive: true);
  }

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
            String? localArtPath;

            // Only try to save if metadata has a picture
            if (metadata.picture != null) {
              final picture = metadata.picture!;
              
              // Generate a Unique Filename
              // We use Hash(AlbumName + AlbumArtist) to handle duplicates
              final uniqueString = '${metadata.album ?? ""}_${metadata.artist ?? ""}';
              final hash = md5.convert(utf8.encode(uniqueString)).toString();
              final fileName = '$hash.jpg'; // Assuming JPEG or generic image
              
              final file = File('${artDir.path}/$fileName');

              // 2. Write to disk ONLY if it doesn't exist (Optimization)
              if (!file.existsSync()) {
                file.writeAsBytesSync(picture.data);
              }
              
              localArtPath = file.path;
            }

            final song = Song(
              title: metadata.title ?? entity.uri.pathSegments.last,
              artist: metadata.artist ?? 'Unknown Artist',
              album: metadata.album ?? '',
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
