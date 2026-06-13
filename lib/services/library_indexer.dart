import 'dart:io';

import 'package:audiotags/audiotags.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nordplayer/database/app_database.dart';
import 'package:nordplayer/models/app_config.dart';
import 'package:nordplayer/services/config_service.dart';
import 'package:nordplayer/services/logger.dart';
import 'package:nordplayer/utils/string_extension.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:nordplayer/services/player_service.dart';

final libraryIndexerProvider = Provider<LibraryIndexer>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return LibraryIndexer(ref, db);
});

class LibraryIndexer with LoggerMixin {
  LibraryIndexer(this._ref, this._db);

  final Ref _ref;
  final AppDatabase _db;

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

  // Map<ArtistName, ArtistId>
  final Map<String, int> _artistCache = {};
  // Map<"AlbumName-ArtistId", AlbumId>
  final Map<String, int> _albumCache = {};

  // ============================================= Main Function ======================================================

  /// Scans music directories, updates database track statuses (handles moved/missing files),
  /// indexes new tracks, and reports progress via [onProgress].
  Future<void> scanLibrary({void Function(int processed, int total)? onProgress}) async {
    log.i('Starting full library scan...');
    onProgress?.call(0, 0);

    // Maps normalized (lowercase, standard slash) paths to original case-sensitive DB paths to prevent duplicate
    // inserts and safely target records during updates/deletes.
    final existingTracks = await _db.select(_db.tracks).get();
    final Map<String, String> existingTracksPathMap = {
      for (final track in existingTracks) track.filePath.normalizePath().toLowerCase(): track.filePath,
    };
    // Fast O(1) lookup set of normalized paths to quickly identify new files and perform set difference logic for
    // missing tracks.
    final Set<String> existingTracksPathNormalized = existingTracksPathMap.keys.toSet();
    final Set<String> supportedFilesFoundOnDisk = {};
    List<File> newTracksToProcess = [];

    // Loop through all the user's track directories and get all of the supported files
    for (String path in _appConfig.trackDirectories) {
      final Directory trackDirectory = Directory(path);

      if (!await trackDirectory.exists()) {
        log.w("Path $path does not exist, skipping");
        continue;
      }

      // Loop through directory and find all files recursively
      final entities = trackDirectory.list(recursive: true, followLinks: false).handleError((error) {
        log.e('Could not access folder: $error');
      });

      // Select only supported files
      await for (FileSystemEntity entity in entities) {
        if (entity is File && supportedExtensions.contains(p.extension(entity.path).toLowerCase())) {
          final normalizedEntityPath = entity.path.normalizePath().toLowerCase();
          supportedFilesFoundOnDisk.add(normalizedEntityPath);

          if (!existingTracksPathNormalized.contains(normalizedEntityPath)) {
            newTracksToProcess.add(entity);
          }
        }
      }
    }

    // Tracks exist in database but not in supportedFilesFoundOnDisk
    final tracksToMarkAsMissingNormalized = existingTracksPathNormalized.difference(supportedFilesFoundOnDisk);
    final tracksToMarkAsMissing = tracksToMarkAsMissingNormalized.map((path) => existingTracksPathMap[path]!).toList();

    final missingTracks = await (_db.select(_db.tracks)..where((t) => t.filePath.isIn(tracksToMarkAsMissing))).get();

    if (newTracksToProcess.isNotEmpty && tracksToMarkAsMissingNormalized.isNotEmpty) {
      Map<String, Track> missingTracksByHash = {for (final track in missingTracks) track.fileHash: track};
      List<File> remainingNewTracks = [];

      for (File newTrack in newTracksToProcess) {
        final newTrackHash = _calculateFileHash(newTrack);

        if (missingTracksByHash.containsKey(newTrackHash)) {
          final oldTrack = missingTracksByHash[newTrackHash]!;
          log.i(
            "Detected file moved/renamed: '${oldTrack.filePath}' -> '${newTrack.path}'. Reconnecting database entry...",
          );

          // Update database entry with new path and set isMissing = false
          await (_db.update(_db.tracks)..where((t) => t.id.equals(oldTrack.id))).write(
            TracksCompanion(filePath: Value(newTrack.path), isMissing: const Value(false)),
          );

          // Prevent this track from being marked as missing later
          tracksToMarkAsMissing.remove(oldTrack.filePath);
        } else {
          remainingNewTracks.add(newTrack);
        }
      }

      newTracksToProcess = remainingNewTracks;
    }

    if (tracksToMarkAsMissing.isNotEmpty) {
      log.i('Marking ${tracksToMarkAsMissing.length} removed tracks as missing in database...');

      // A single bulk update query using isIn()
      await (_db.update(_db.tracks)..where((track) => track.filePath.isIn(tracksToMarkAsMissing))).write(
        const TracksCompanion(isMissing: Value(true)),
      );
    }

    if (newTracksToProcess.isNotEmpty) {
      log.i('Found ${newTracksToProcess.length} new track(s). Processing...');

      await _indexTracks(newTracksToProcess, onProgress: onProgress);
    } else {
      log.i('No new tracks found. Library is up to date');
    }

    // Mark all found tracks as not missing
    if (supportedFilesFoundOnDisk.isNotEmpty) {
      final foundPathsInDb = supportedFilesFoundOnDisk
          .map((path) => existingTracksPathMap[path])
          .whereType<String>()
          .toList();
      if (foundPathsInDb.isNotEmpty) {
        await (_db.update(
          _db.tracks,
        )..where((track) => track.filePath.isIn(foundPathsInDb))).write(const TracksCompanion(isMissing: Value(false)));
      }
    }
  }

  Future<void> markTrackAsMissing(String path) async {
    final normalizedPath = path.normalizePath().toLowerCase();
    await (_db.update(_db.tracks)..where((track) => track.filePath.lower().equals(normalizedPath))).write(
      const TracksCompanion(isMissing: Value(true)),
    );

    // Also remove from player queue if currently loaded
    try {
      await _ref.read(playerServiceProvider).removeTrackByPath(path);
    } catch (e) {
      log.e("Failed to remove track from player service queue: $e");
    }
  }

  Future<void> markTracksInDirectoryAsMissing(String directoryPath) async {
    log.i("Marking tracks under $directoryPath as missing...");
    final normalizedDir = directoryPath.normalizePath().toLowerCase();

    // Get all track paths under this directory first to remove them from the queue
    final tracksInDir = await (_db.select(_db.tracks)
          ..where((track) => track.filePath.lower().like('$normalizedDir%')))
        .get();

    await (_db.update(_db.tracks)..where((track) => track.filePath.lower().like('$normalizedDir%'))).write(
      const TracksCompanion(isMissing: Value(true)),
    );

    // Also remove them from the player queue
    try {
      final playerService = _ref.read(playerServiceProvider);
      for (final track in tracksInDir) {
        await playerService.removeTrackByPath(track.filePath);
      }
    } catch (e) {
      log.e("Failed to remove tracks from player service queue: $e");
    }
  }

  Future<void> processSingleFile(File file) async {
    log.i("Processing individual file: ${file.path}");

    final trackHash = _calculateFileHash(file);
    final existingTrackByHash = await (_db.select(
      _db.tracks,
    )..where((t) => t.fileHash.equals(trackHash))).getSingleOrNull();

    if (existingTrackByHash != null) {
      if (existingTrackByHash.filePath != file.path) {
        log.i(
          "Detected file moved/renamed via watcher: '${existingTrackByHash.filePath}' -> '${file.path}'. Reconnecting database entry...",
        );
      }
      await (_db.update(_db.tracks)..where((t) => t.id.equals(existingTrackByHash.id))).write(
        TracksCompanion(filePath: Value(file.path), isMissing: const Value(false)),
      );
      return;
    }

    // If the file already exists in the database by path, restore it (set isMissing = false).
    await (_db.update(
      _db.tracks,
    )..where((t) => t.filePath.equals(file.path))).write(const TracksCompanion(isMissing: Value(false)));

    // Index the file (this will parse tags and insert it if it's completely new)
    await _indexTracks([file]);
  }

  /// Performs a forced, in-place metadata re-indexing of all tracks in the database.
  ///
  /// Re-reads audio tags directly from all files on disk to update basic metadata, artist splits, and albums.
  /// Preserves track database IDs so that user playlists, favorites, and play history remain intact.
  ///
  /// The optional [onProgress] callback is invoked after each processed track.
  Future<void> reindexMetadata({void Function(int processed, int total)? onProgress}) async {
    log.i('Starting forced in-place metadata re-indexing of all tracks...');

    // Clear caches so we fetch fresh IDs and resolve splits correctly
    _artistCache.clear();
    _albumCache.clear();

    final existingTracks = await _db.select(_db.tracks).get();
    if (existingTracks.isEmpty) {
      log.i('No tracks in database to re-index.');
      return;
    }

    final total = existingTracks.length;
    int processed = 0;

    onProgress?.call(processed, total);

    for (final track in existingTracks) {
      final file = File(track.filePath);
      if (!await file.exists()) {
        processed++;
        onProgress?.call(processed, total);
        continue;
      }

      try {
        final trackTag = await AudioTags.read(file.path);
        if (trackTag == null) {
          processed++;
          onProgress?.call(processed, total);
          continue;
        }

        final trackHash = _calculateFileHash(file);

        List<int> allArtistIds = await _splitArtistsAndGetOrCreateArtist(trackTag);
        final primaryArtistId = allArtistIds.first;

        int albumId = await _getOrCreateAlbum(trackTag, primaryArtistId);

        final artPath = await _saveAlbumArt(trackTag, albumId);
        if (artPath != null) {
          await (_db.update(
            _db.albums,
          )..where((a) => a.id.equals(albumId))).write(AlbumsCompanion(albumArtPath: Value(artPath)));
        }

        // =========================== Update Track in Database ===================================

        await _db.transaction(() async {
          // Update track info in-place
          await (_db.update(_db.tracks)..where((t) => t.id.equals(track.id))).write(
            TracksCompanion(
              title: Value(trackTag.title ?? p.basename(file.path)),
              trackNumber: Value(trackTag.trackNumber ?? 0),
              trackTotal: Value(trackTag.trackTotal ?? 0),
              discNumber: Value(trackTag.discNumber ?? 0),
              discTotal: Value(trackTag.discTotal ?? 0),
              durationMs: Value((trackTag.duration ?? 0) * 1000),
              genre: Value(trackTag.genre),
              fileSize: Value(file.lengthSync()),
              fileHash: Value(trackHash),
              artistId: Value(primaryArtistId),
              albumId: Value(albumId),
              isMissing: const Value(false),
            ),
          );

          // Clear old artist relations for this track
          await (_db.delete(_db.trackArtist)..where((ta) => ta.trackId.equals(track.id))).go();

          // Re-insert the updated artist relations
          for (final artistId in allArtistIds) {
            await _db
                .into(_db.trackArtist)
                .insert(
                  TrackArtistCompanion(trackId: Value(track.id), artistId: Value(artistId)),
                  mode: InsertMode.insertOrIgnore,
                );
          }
        });
      } catch (e) {
        log.e("Error re-indexing track ${track.filePath}: $e");
      }

      processed++;
      onProgress?.call(processed, total);
    }

    // Clean up orphaned artists and albums
    await _db.deleteOrphanedMetadata();
    log.i('Forced metadata re-indexing complete.');
  }

  // =========================================== Helper Function ======================================================

  Future<void> _indexTracks(List<File> files, {void Function(int processed, int total)? onProgress}) async {
    const int chunkSize = 50;
    final total = files.length;
    int processed = 0;

    onProgress?.call(0, total);

    for (var i = 0; i < files.length; i += chunkSize) {
      final end = (i + chunkSize < files.length) ? i + chunkSize : files.length;
      final chunk = files.sublist(i, end);

      await _indexTracksChunk(
        chunk,
        onProgress: (insertedInChunk) {
          onProgress?.call(processed + insertedInChunk, total);
        },
      );
      processed += chunk.length;
      onProgress?.call(processed, total);
    }
  }

  /// Indexes a chunk of track files in the database within a single transaction.
  ///
  /// Parses tag metadata for each file, resolves/inserts relevant artist and album records,
  /// extracts and saves album art, and writes the track and track-artist relations.
  Future<void> _indexTracksChunk(List<File> files, {void Function(int inserted)? onProgress}) async {
    // Read all metadata, put it in a list
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

    int insertedCount = 0;
    await _db.transaction(() async {
      for (var item in metadataList) {
        final trackPath = item.$1;
        final trackTag = item.$2;

        if (trackTag == null) {
          log.w("Skipped file due to parsing error: $trackPath");
          insertedCount++;
          onProgress?.call(insertedCount);
          continue;
        }

        final trackFile = File(trackPath);

        String trackHash = _calculateFileHash(trackFile);

        List<int> allArtistIds = await _splitArtistsAndGetOrCreateArtist(trackTag);
        final primaryArtistId = allArtistIds.first;

        int albumId = await _getOrCreateAlbum(trackTag, primaryArtistId);

        final artPath = await _saveAlbumArt(trackTag, albumId);
        if (artPath != null) {
          await (_db.update(
            _db.albums,
          )..where((a) => a.id.equals(albumId))).write(AlbumsCompanion(albumArtPath: Value(artPath)));
        }

        // =========================== Insert Track to Database ===================================

        final newTrackId = await _db
            .into(_db.tracks)
            .insert(
              TracksCompanion(
                title: Value(trackTag.title ?? p.basename(trackPath)),
                trackNumber: Value(trackTag.trackNumber ?? 0),
                trackTotal: Value(trackTag.trackTotal ?? 0),
                discNumber: Value(trackTag.discNumber ?? 0),
                discTotal: Value(trackTag.discTotal ?? 0),
                durationMs: Value((trackTag.duration ?? 0) * 1000),
                genre: Value(trackTag.genre),
                fileSize: Value(trackFile.lengthSync()),
                filePath: Value(trackFile.path),
                fileHash: Value(trackHash),
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

        insertedCount++;
        onProgress?.call(insertedCount);
      }
    });
  }

  Future<String?> _saveAlbumArt(Tag trackTag, int albumId) async {
    if (trackTag.pictures.isEmpty) return null;

    final cacheDir = await getApplicationCacheDirectory();
    final artDir = Directory(p.join(cacheDir.path, 'album_art'));
    if (!await artDir.exists()) {
      await artDir.create(recursive: true);
    }

    // Determine file extension from MIME type
    final picture = trackTag.pictures.first;
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

  // Generate file hash using FNV-1a + file size
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

      // Convert FNV-1a result to hexadecimal
      return '${hash.toRadixString(16)}_$size';
    } catch (e) {
      // Fallback to simple hash of path & size if file reading fails
      return '${file.path.hashCode.toRadixString(16)}_${file.lengthSync()}';
    }
  }

  /// Splits the artist string in [trackTag] using the configured artist delimiters, get or create the
  /// corresponding artist records, and returns their database IDs.
  /// The first element in the returned list is always the primary artist ID.
  Future<List<int>> _splitArtistsAndGetOrCreateArtist(Tag trackTag) async {
    final rawArtistString = trackTag.trackArtist ?? 'Unknown Artist';

    // Sort delimiters by length in descending order to avoid prefix matching issues (e.g. matching 'feat' before 'feat.')
    final sortedDelimiters = List<String>.from(_appConfig.artistDelimiters)
      ..sort((a, b) => b.length.compareTo(a.length));

    final String pattern = sortedDelimiters.map((d) => RegExp.escape(d)).join('|');
    final RegExp separator = RegExp('\\s*(?:$pattern)\\s*', caseSensitive: false);

    // Split, trim whitespace, and remove empty strings
    List<String> artistNames = rawArtistString
        .split(separator)
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (artistNames.isEmpty) artistNames = ['Unknown Artist'];

    final List<int> allArtistIds = [];

    // Resolve IDs for ALL artists found. Use a Set to avoid duplicates
    for (final name in artistNames.toSet()) {
      int id;
      if (_artistCache.containsKey(name)) {
        id = _artistCache[name]!;
      } else {
        final existing = await (_db.select(_db.artists)..where((a) => a.name.equals(name))).getSingleOrNull();
        if (existing != null) {
          _artistCache[name] = existing.id;
          id = existing.id;
        } else {
          final newId = await _db.into(_db.artists).insert(ArtistsCompanion(name: Value(name)));
          _artistCache[name] = newId;
          id = newId;
        }
      }
      allArtistIds.add(id);
    }

    return allArtistIds;
  }

  /// Gets the database ID of the album in [trackTag] or create the album record if it doesn't exist.
  /// Returns the album id. Require primary artist id to avoid duplicate albums.
  Future<int> _getOrCreateAlbum(Tag trackTag, int primaryArtistId) async {
    int albumId;
    final albumTitle = trackTag.album ?? 'Unknown Album';
    final albumCacheKey = '$albumTitle-$primaryArtistId';

    if (_albumCache.containsKey(albumCacheKey)) {
      albumId = _albumCache[albumCacheKey]!;
    } else {
      final existing = await (_db.select(
        _db.albums,
      )..where((a) => a.title.equals(albumTitle) & a.artistId.equals(primaryArtistId))).getSingleOrNull();

      if (existing != null) {
        _albumCache[albumCacheKey] = existing.id;
        albumId = existing.id;
      } else {
        final newId = await _db
            .into(_db.albums)
            .insert(
              AlbumsCompanion(
                title: Value(albumTitle),
                artistId: Value(primaryArtistId),
                year: Value(trackTag.year ?? 0),
                albumArtist: Value(trackTag.albumArtist),
              ),
            );
        _albumCache[albumCacheKey] = newId;
        albumId = newId;
      }
    }

    return albumId;
  }
}
