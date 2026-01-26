import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:crypto/crypto.dart';
import 'package:metadata_god/metadata_god.dart';
import 'package:suara/models/scanned_metadata.dart';

// =============================================================================
// CONFIGURATION & DTOs (Data Transfer Object)
// =============================================================================

/// Configuration payload passed to the background Isolate.
class ScanConfiguration {
  final List<String> folderPaths;
  final Map<String, int> knownFiles; // Snapshot of DB {Path: Timestamp}
  final String cachePath;
  final bool splitArtistsEnabled;

  ScanConfiguration(
    this.folderPaths,
    this.knownFiles,
    this.cachePath,
    this.splitArtistsEnabled,
  );
}

/// The result payload returned from the background Isolate.
class ScanResult {
  final List<ScannedMetadata> newOrUpdatedSongs;
  final List<String> deletedPaths;

  ScanResult(this.newOrUpdatedSongs, this.deletedPaths);
}

// =============================================================================
// PUBLIC API
// =============================================================================

/// Spawns a background thread (Isolate) to scan the library.
///
/// This prevents UI jank while processing thousands of files.
Future<ScanResult> scanLibrary(ScanConfiguration config) async {
  return await Isolate.run(() => _internalScanTask(config));
}

// =============================================================================
// INTERNAL BACKGROUND TASK
// =============================================================================

// Regex for splitting artists. Avoids '/' to protect bands like AC/DC.
final _separatorRegex = RegExp(r'[;&]|//');

Future<ScanResult> _internalScanTask(ScanConfiguration config) async {
  await MetadataGod.initialize(); // Initialize native libraries in this Isolate

  List<ScannedMetadata> songsToUpsert = [];
  Set<String> foundPaths = {}; // Track files on disk to detect deletions

  // --- SETUP: CACHE DIRECTORIES ---
  final artDir = Directory('${config.cachePath}/album_art');
  if (!artDir.existsSync()) {
    artDir.createSync(recursive: true);
  }

  for (String directoryPath in config.folderPaths) {
    final dir = Directory(directoryPath);
    if (!dir.existsSync()) continue;

    // --- STEP 1: RECURSIVE FILE LISTING ---
    final entities = dir.listSync(recursive: true, followLinks: false);

    for (var entity in entities) {
      if (entity is! File || !entity.path.toLowerCase().endsWith('.mp3')) {
        continue;
      }

      foundPaths.add(entity.path);

      // --- STEP 2: CHANGE DETECTION ---
      // We only parse the file if it's new OR strictly newer than our DB record.
      final lastMod = entity.lastModifiedSync().millisecondsSinceEpoch;
      final dbLastMod = config.knownFiles[entity.path];

      if (dbLastMod == null || lastMod > dbLastMod) {
        try {
          // --- STEP 3: METADATA PARSING ---
          final metadata = await MetadataGod.readMetadata(file: entity.path);
          
          // A. Handle Album Art
          String? localArtPath;
          if (metadata.picture != null) {
            // Optimization: Hash the artist+album to avoid saving duplicates
            final uniqueString = '${metadata.album}_${metadata.artist}';
            final hash = md5.convert(utf8.encode(uniqueString)).toString();
            final artFile = File('${artDir.path}/$hash.jpg');

            if (!artFile.existsSync()) {
              artFile.writeAsBytesSync(metadata.picture!.data);
            }
            localArtPath = artFile.path;
          }

          // B. Handle Artist Splitting
          final rawArtistString = metadata.artist ?? 'Unknown Artist';
          List<String> artistNames = [];

          if (config.splitArtistsEnabled) {
             // Logic: Split by semicolon or double-slash
            artistNames = rawArtistString
                .split(_separatorRegex)
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList();
          }

          // Fallback if splitting was disabled or returned nothing
          if (artistNames.isEmpty) {
            artistNames = [rawArtistString];
          }

          // --- STEP 4: DTO CREATION ---
          songsToUpsert.add(ScannedMetadata(
            title: metadata.title ?? entity.uri.pathSegments.last,
            artist: artistNames.first, // Primary Artist (for Sorting)
            allArtists: artistNames,   // All Artists (for Links)
            album: metadata.album ?? 'Unknown Album',
            genre: metadata.genre ?? '',
            year: metadata.year ?? 0,
            trackNumber: metadata.trackNumber ?? 0,
            discNumber: metadata.discNumber ?? 0,
            duration: Duration(milliseconds: metadata.durationMs?.toInt() ?? 0),
            path: entity.path,
            artPath: localArtPath,
            timestamp: lastMod,
          ));
        } catch (e) {
          print("Error parsing ${entity.path}: $e");
        }
      }
    }
  }

  // --- STEP 5: DETECT DELETIONS ---
  // If it was in the DB but we didn't see it on disk, it's gone.
  final deletedPaths = config.knownFiles.keys
      .where((path) => !foundPaths.contains(path))
      .toList();

  return ScanResult(songsToUpsert, deletedPaths);
}