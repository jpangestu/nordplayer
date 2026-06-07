import 'dart:io';

import "package:audiotags/audiotags.dart";
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nordplayer/database/app_database.dart';
import 'package:nordplayer/models/app_config.dart';
import 'package:nordplayer/services/config_service.dart';
import 'package:nordplayer/services/logger.dart';
import 'package:nordplayer/utils/string_extension.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

final libraryScannerProvider = Provider<LibraryScanner>((ref) {
  final appConfig = ref.watch(configServiceProvider).requireValue;
  final db = ref.watch(appDatabaseProvider);

  return LibraryScanner(appConfig, db);
});

class LibraryScanner with LoggerMixin {
  final AppConfig _appConfig;
  final AppDatabase _db;

  // 2. The new constructor
  LibraryScanner(this._appConfig, this._db);

  Set<String> supportedExtensions = {'.mp3', '.m4a', '.flac'};

  // Map<ArtistName, ArtistId>
  final Map<String, int> _artistCache = {};
  // Map<"AlbumName-ArtistId", AlbumId>
  final Map<String, int> _albumCache = {};

  Future<void> scanLibrary() async {
    log.i("Initializing library scan for ${_appConfig.musicPaths.length} folders");

    final existingTracks = await _db.select(_db.tracks).get();
    
    // Normalize and lowercase known paths for case-insensitive matching
    final Map<String, String> knownTrackPathsMap = {
      for (final track in existingTracks) track.filePath.normalizePath().toLowerCase(): track.filePath
    };
    final Set<String> knownTrackPathsNormalized = knownTrackPathsMap.keys.toSet();
    
    final Set<String> filesFoundOnDisk = {};
    List<File> newTrackToProcess = [];

    for (String path in _appConfig.musicPaths) {
      final musicDir = Directory(path);

      if (await musicDir.exists()) {
        final Stream<FileSystemEntity> entities = musicDir.list(recursive: true, followLinks: false).handleError((
          error,
        ) {
          log.e('Could not access folder: $error');
        });

        await for (FileSystemEntity entity in entities) {
          if (entity is File && supportedExtensions.contains(p.extension(entity.path).toLowerCase())) {
            final normalizedDiskPath = entity.path.normalizePath().toLowerCase();
            filesFoundOnDisk.add(normalizedDiskPath);

            if (!knownTrackPathsNormalized.contains(normalizedDiskPath)) {
              newTrackToProcess.add(entity);
              // log.d('New Track Found: ${p.basename(entity.path)}');
            }
          }
        }
      } else {
        log.e('Music directory not found: $path');
      }
    }

    if (newTrackToProcess.isNotEmpty) {
      log.i('Found ${newTrackToProcess.length} new track(s). Processing...');
      int chunkSize = 50;
      for (var i = 0; i < newTrackToProcess.length; i += chunkSize) {
        final end = (i + chunkSize < newTrackToProcess.length) ? i + chunkSize : newTrackToProcess.length;
        await _processBatch(newTrackToProcess.sublist(i, end));
      }
    } else {
      log.i('No new tracks found. Library is up to date');
    }

    final tracksToRemoveNormalized = knownTrackPathsNormalized.difference(filesFoundOnDisk);
    if (tracksToRemoveNormalized.isNotEmpty) {
      final tracksToRemove = tracksToRemoveNormalized.map((path) => knownTrackPathsMap[path]!).toList();
      log.i('Cleaning up ${tracksToRemove.length} removed tracks from database...');
      await (_db.delete(_db.tracks)..where((track) => track.filePath.isIn(tracksToRemove))).go();
    }
  }

  Future<void> removeTrackByPath(String path) async {
    final normalizedPath = path.normalizePath().toLowerCase();
    await (_db.delete(_db.tracks)..where((track) => track.filePath.lower().equals(normalizedPath))).go();
  }

  Future<void> removeTracksInDirectory(String directoryPath) async {
    log.i("Removing tracks under: $directoryPath");
    final normalizedDir = directoryPath.normalizePath().toLowerCase();
    await (_db.delete(_db.tracks)..where((track) => track.filePath.lower().like('$normalizedDir%'))).go();
  }

  Future<void> processSingleFile(File file) async {
    log.i("Processing individual file: ${file.path}");
    await _processBatch([file]);
  }

  Future<void> _processBatch(List<File> files) async {
    final metadataList = await Future.wait(
      files.map((file) async {
        try {
          final tag = await AudioTags.read(file.path);
          return (file.path, tag);
        } catch (e) {
          log.e("Error parsing ${file.path}: $e");
          return (file.path, null);
        }
      }),
    );

    await _db.transaction(() async {
      for (var item in metadataList) {
        final filePath = item.$1;
        final tag = item.$2;

        if (tag == null) {
          log.w("Skipped file due to parsing error: $filePath");
          continue;
        }

        final file = File(filePath);

        final rawArtistString = tag.trackArtist ?? 'Unknown Artist';
        List<String> artistNames = _splitArtistString(rawArtistString);
        if (artistNames.isEmpty) artistNames = ['Unknown Artist'];

        // Resolve IDs for ALL artists found
        // Use a Set to avoid duplicates
        final List<int> allArtistIds = [];
        for (final name in artistNames.toSet()) {
          final id = await _getOrCreateArtist(name);
          allArtistIds.add(id);
        }
        final primaryArtistId = allArtistIds.first;

        final albumId = await _getOrCreateAlbum(tag, primaryArtistId);

        final artPath = await _saveAlbumArt(tag, albumId);
        if (artPath != null) {
          await (_db.update(
            _db.albums,
          )..where((a) => a.id.equals(albumId))).write(AlbumsCompanion(albumArtPath: Value(artPath)));
        }

        final fileHash = _calculateFileHash(file);

        final newTrackId = await _db
            .into(_db.tracks)
            .insert(
              TracksCompanion(
                title: Value(tag.title ?? p.basename(filePath)),
                trackNumber: Value(tag.trackNumber ?? 0),
                trackTotal: Value(tag.trackTotal ?? 0),
                discNumber: Value(tag.discNumber ?? 0),
                discTotal: Value(tag.discTotal ?? 0),
                durationMs: Value((tag.duration ?? 0) * 1000),
                genre: Value(tag.genre),
                fileSize: Value(file.lengthSync()),
                filePath: Value(file.path),
                fileHash: Value(fileHash),
                artistId: Value(primaryArtistId),
                albumId: Value(albumId),
              ),
              mode: InsertMode.insertOrIgnore,
            );

        for (final artistId in allArtistIds) {
          await _db
              .into(_db.trackArtist)
              .insert(
                TrackArtistCompanion(trackId: Value(newTrackId), artistId: Value(artistId)),
                mode: InsertMode.insertOrIgnore,
              );
        }
      }
    });
  }

  Future<String?> _saveAlbumArt(Tag tag, int albumId) async {
    if (tag.pictures.isEmpty) return null;

    final cacheDir = await getApplicationCacheDirectory();
    final artDir = Directory(p.join(cacheDir.path, 'album_art'));
    if (!await artDir.exists()) {
      await artDir.create(recursive: true);
    }

    // Determine file extension from MIME type
    final picture = tag.pictures.first;
    final String ext = picture.mimeType == MimeType.png ? '.png' : '.jpg';

    // Create a unique filename based on Album ID
    final String fileName = "album_$albumId$ext";
    final String fullPath = p.join(artDir.path, fileName);

    if (await File(fullPath).exists()) {
      return fullPath;
    }

    try {
      await File(fullPath).writeAsBytes(picture.bytes);
      return fullPath;
    } catch (e) {
      log.e("Failed to save album art: $e");
      return null;
    }
  }

  List<String> _splitArtistString(String rawArtist) {
    final List<String> delimiters = _appConfig.artistDelimiters;
    final String pattern = delimiters.map((d) => RegExp.escape(d)).join('|');

    final RegExp separator = RegExp('\\s*(?:$pattern)\\s*', caseSensitive: false);

    // Split, trim whitespace, and remove empty strings
    return rawArtist.split(separator).map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  }

  Future<int> _getOrCreateArtist(String artistName) async {
    if (_artistCache.containsKey(artistName)) {
      return _artistCache[artistName]!;
    }

    final existing = await (_db.select(_db.artists)..where((a) => a.name.equals(artistName))).getSingleOrNull();

    if (existing != null) {
      _artistCache[artistName] = existing.id;
      return existing.id;
    }

    final newId = await _db.into(_db.artists).insert(ArtistsCompanion(name: Value(artistName)));
    _artistCache[artistName] = newId;
    return newId;
  }

  Future<int> _getOrCreateAlbum(Tag tag, int artistId) async {
    final albumTitle = tag.album ?? 'Unknown Album';
    final cacheKey = '$albumTitle-$artistId';

    if (_albumCache.containsKey(cacheKey)) {
      return _albumCache[cacheKey]!;
    }

    final existing = await (_db.select(
      _db.albums,
    )..where((a) => a.title.equals(albumTitle) & a.artistId.equals(artistId))).getSingleOrNull();

    if (existing != null) {
      _albumCache[cacheKey] = existing.id;
      return existing.id;
    }

    final newId = await _db
        .into(_db.albums)
        .insert(
          AlbumsCompanion(
            title: Value(albumTitle),
            artistId: Value(artistId),
            year: Value(tag.year ?? 0),
            albumArtist: Value(tag.albumArtist),
          ),
        );

    _albumCache[cacheKey] = newId;
    return newId;
  }

  String _calculateFileHash(File file) {
    try {
      final size = file.lengthSync();
      final numBytesToRead = size < 65536 ? size : 65536;
      final raf = file.openSync(mode: FileMode.read);
      final bytes = raf.readSync(numBytesToRead);
      raf.closeSync();

      // FNV-1a 32-bit hash
      int hash = 2166136261;
      for (final byte in bytes) {
        hash ^= byte;
        hash = (hash * 16777619) & 0xFFFFFFFF;
      }
      return '${hash.toRadixString(16)}_$size';
    } catch (e) {
      // Fallback to simple hash of path & size if file reading fails
      return '${file.path.hashCode.toRadixString(16)}_${file.lengthSync()}';
    }
  }
}
