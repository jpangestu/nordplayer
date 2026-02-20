import 'dart:io';

import 'package:drift/drift.dart';
import 'package:metadata_god/metadata_god.dart';
import 'package:nordplayer/database/app_database.dart';
import 'package:nordplayer/services/logger.dart';
import 'package:path/path.dart' as p;
import 'package:nordplayer/services/config_service.dart';
import 'package:path_provider/path_provider.dart';

class LibraryScanner with LoggerMixin {
  Set<String> supportedExtensions = {'.mp3', '.m4a', '.flac'};

  // Map<ArtistName, ArtistId>
  final Map<String, int> _artistCache = {};
  // Map<"AlbumName-ArtistId", AlbumId>
  final Map<String, int> _albumCache = {};

  Future<void> scanLibrary(AppDatabase db) async {
    List<File> allMusic = [];

    for (String path in ConfigService().appConfig.musicPaths) {
      final musicDir = Directory(path);

      if (await musicDir.exists()) {
        final Stream<FileSystemEntity> entities = musicDir
            .list(recursive: true, followLinks: false)
            .handleError((error) {
              log.e('Could not access folder: $error');
            });

        await for (FileSystemEntity entity in entities) {
          if (entity is File &&
              supportedExtensions.contains(
                p.extension(entity.path).toLowerCase(),
              )) {
            allMusic.add(entity);
            // log.d('Found: ${p.basename(entity.path)}');
          }
        }
      } else {
        log.e('Music directory not found: $path');
      }
    }

    int chunkSize = 50;
    for (var i = 0; i < allMusic.length; i += chunkSize) {
      final end = (i + chunkSize < allMusic.length)
          ? i + chunkSize
          : allMusic.length;
      final batch = allMusic.sublist(i, end);

      await _processBatch(db, batch);

      log.d("Processed $end / ${allMusic.length}");
    }
  }

  Future<void> _processBatch(AppDatabase db, List<File> files) async {
    final metadataList = await Future.wait(
      files.map((file) async {
        try {
          final meta = await MetadataGod.readMetadata(file: file.path);
          return (file, meta);
        } catch (e) {
          log.e("Error parsing ${file.path}: $e");
          return null;
        }
      }),
    );

    await db.transaction(() async {
      for (var item in metadataList) {
        if (item == null) continue;
        final file = item.$1;
        final meta = item.$2;

        final rawArtistString = meta.artist ?? 'Unknown Artist';
        List<String> artistNames = _splitArtistString(rawArtistString);
        // If split resulted in empty (e.g. string was just ","), use default
        if (artistNames.isEmpty) artistNames = ['Unknown Artist'];

        // Resolve IDs for ALL artists found
        // Use a Set to avoid duplicates
        final List<int> allArtistIds = [];
        for (final name in artistNames.toSet()) {
          final id = await _getOrCreateArtist(db, name);
          allArtistIds.add(id);
        }
        final primaryArtistId = allArtistIds.first;

        final albumId = await _getOrCreateAlbum(db, meta, primaryArtistId);

        final artPath = await _saveAlbumArt(meta, albumId);
        if (artPath != null) {
          await (db.update(db.albums)..where((a) => a.id.equals(albumId)))
              .write(AlbumsCompanion(albumArtPath: Value(artPath)));
        }

        final newTrackId = await db
            .into(db.tracks)
            .insert(
              TracksCompanion(
                title: Value(meta.title ?? p.basename(file.path)),
                trackNumber: Value(meta.trackNumber ?? 0),
                trackTotal: Value(meta.trackTotal ?? 0),
                discNumber: Value(meta.discNumber ?? 0),
                discTotal: Value(meta.discTotal ?? 0),
                durationMs: Value(meta.duration?.inMilliseconds ?? 0),
                genre: Value(meta.genre),
                fileSize: Value(file.lengthSync()),
                filePath: Value(file.path),
                artistId: Value(primaryArtistId),
                albumId: Value(albumId),
              ),
              mode: InsertMode.insertOrIgnore,
            );

        for (final artistId in allArtistIds) {
          await db
              .into(db.trackArtist)
              .insert(
                TrackArtistCompanion(
                  trackId: Value(newTrackId),
                  artistId: Value(artistId),
                ),
                mode: InsertMode.insertOrIgnore,
              );
        }
      }
    });
  }

  Future<String?> _saveAlbumArt(Metadata metadata, int albumId) async {
    if (metadata.picture == null) return null;

    final cacheDir = await getApplicationCacheDirectory();
    final artDir = Directory(p.join(cacheDir.path, 'album_art'));
    if (!await artDir.exists()) {
      await artDir.create(recursive: true);
    }

    // Determine file extension from MIME type
    final String ext = metadata.picture!.mimeType == 'image/png'
        ? '.png'
        : '.jpg';

    // Create a unique filename based on Album ID
    final String fileName = "album_$albumId$ext";
    final String fullPath = p.join(artDir.path, fileName);

    if (await File(fullPath).exists()) {
      return fullPath;
    }

    try {
      await File(fullPath).writeAsBytes(metadata.picture!.data);
      return fullPath;
    } catch (e) {
      log.e("Failed to save album art: $e");
      return null;
    }
  }

  List<String> _splitArtistString(String rawArtist) {
    final List<String> delimiters = ConfigService().appConfig.artistDelimiters;
    final String pattern = delimiters.map((d) => RegExp.escape(d)).join('|');

    final RegExp separator = RegExp(
      '\\s*(?:$pattern)\\s*',
      caseSensitive: false,
    );

    RegExp(r'\s*(?:,|&|/|;|ft\.|feat\.)\s*', caseSensitive: false);

    // Split, trim whitespace, and remove empty strings
    return rawArtist
        .split(separator)
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  Future<int> _getOrCreateArtist(AppDatabase db, String artistName) async {
    if (_artistCache.containsKey(artistName)) {
      return _artistCache[artistName]!;
    }

    final existing = await (db.select(
      db.artists,
    )..where((a) => a.name.equals(artistName))).getSingleOrNull();

    if (existing != null) {
      _artistCache[artistName] = existing.id;
      return existing.id;
    }

    final newId = await db
        .into(db.artists)
        .insert(ArtistsCompanion(name: Value(artistName)));
    _artistCache[artistName] = newId;
    return newId;
  }

  Future<int> _getOrCreateAlbum(
    AppDatabase db,
    Metadata meta,
    int artistId,
  ) async {
    final albumTitle = meta.album ?? 'Unknown Album';
    final cacheKey = '$albumTitle-$artistId';

    if (_albumCache.containsKey(cacheKey)) {
      return _albumCache[cacheKey]!;
    }

    final existing =
        await (db.select(db.albums)..where(
              (a) => a.title.equals(albumTitle) & a.artistId.equals(artistId),
            ))
            .getSingleOrNull();

    if (existing != null) {
      _albumCache[cacheKey] = existing.id;
      return existing.id;
    }

    final newId = await db
        .into(db.albums)
        .insert(
          AlbumsCompanion(
            title: Value(albumTitle),
            artistId: Value(artistId),
            year: Value(meta.year ?? 0),
            albumArtist: Value(meta.albumArtist),
          ),
        );

    _albumCache[cacheKey] = newId;
    return newId;
  }
}
