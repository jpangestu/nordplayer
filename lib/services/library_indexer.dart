import 'dart:io';

import 'package:audiotags/audiotags.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nordplayer/database/app_database.dart';
import 'package:nordplayer/models/app_config.dart';
import 'package:nordplayer/services/background_task_service.dart';
import 'package:nordplayer/services/config_service.dart';
import 'package:nordplayer/services/logger.dart';
import 'package:nordplayer/services/player_service.dart';
import 'package:nordplayer/utils/audio_metadata_hasher.dart';
import 'package:nordplayer/utils/string_extension.dart';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

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
  // Map<"AlbumName-AlbumArtist", AlbumId>
  final Map<String, int> _albumCache = {};
  // Cache of lowercase exclusions for the current scan
  Set<String>? _exclusionSetCache;

  // ============================================= Main Function ======================================================

  /// Scans music directories, updates database track statuses (handles moved/missing files),
  /// indexes new tracks, and reports progress via [onProgress].
  Future<void> scanLibrary({void Function(int processed, int total)? onProgress}) async {
    log.i('Starting full library scan...');
    onProgress?.call(0, 0);

    final taskService = _ref.read(backgroundTaskServiceProvider.notifier);
    taskService.startTask(
      id: 'library-scan',
      name: 'Scanning Library',
      message: 'Scanning folders for audio files...',
      isIndeterminate: true,
    );

    try {
      _exclusionSetCache = null;

      // Maps normalized (lowercase, standard slash) paths to Track objects to prevent duplicate
      // inserts, safely target records during updates/deletes, and check for in-place updates.
      final existingTracks = await _db.select(_db.tracks).get();
      final Map<String, Track> existingTracksMap = {
        for (final track in existingTracks) track.filePath.normalizePath().toLowerCase(): track,
      };
      // Fast O(1) lookup set of normalized paths to quickly identify new files and perform set difference logic for
      // missing tracks.
      final Set<String> existingTracksPathNormalized = existingTracksMap.keys.toSet();
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
            } else {
              // Check if the file tag was modified (hash mismatch)
              final track = existingTracksMap[normalizedEntityPath]!;
              final currentHash = AudioMetadataHasher.calculateHash(entity);
              if (currentHash != track.fileHash) {
                log.i("Detected file tag modification for '${entity.path}' during library scan. Updating metadata...");
                try {
                  final trackTag = await AudioTags.read(entity.path);
                  if (trackTag != null) {
                    await _updateTrackMetadataInTransaction(
                      trackId: track.id,
                      file: entity,
                      trackTag: trackTag,
                      trackHash: currentHash,
                    );
                  } else {
                    log.w("Failed to read tags for modified file: ${entity.path}");
                  }
                } catch (e) {
                  log.e("Failed to update metadata for '${entity.path}': $e");
                }
              }
            }
          }
        }
      }

      // Tracks exist in database but not in supportedFilesFoundOnDisk
      final tracksToMarkAsMissingNormalized = existingTracksPathNormalized.difference(supportedFilesFoundOnDisk);
      final tracksToMarkAsMissing = tracksToMarkAsMissingNormalized
          .map((path) => existingTracksMap[path]!.filePath)
          .toList();

      final missingTracks = await (_db.select(_db.tracks)..where((t) => t.filePath.isIn(tracksToMarkAsMissing))).get();

      if (newTracksToProcess.isNotEmpty && tracksToMarkAsMissingNormalized.isNotEmpty) {
        Map<String, Track> missingTracksByHash = {for (final track in missingTracks) track.fileHash: track};
        List<File> remainingNewTracks = [];

        for (File newTrack in newTracksToProcess) {
          final newTrackHash = AudioMetadataHasher.calculateHash(newTrack);

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

        await _indexTracks(
          newTracksToProcess,
          onProgress: (processed, total) {
            onProgress?.call(processed, total);
            taskService.updateProgress(
              'library-scan',
              processed: processed,
              total: total,
              message: 'Processing track $processed of $total...',
              isIndeterminate: false,
            );
          },
        );
      } else {
        log.i('No new tracks found. Library is up to date');
      }

      // Mark all found tracks as not missing
      if (supportedFilesFoundOnDisk.isNotEmpty) {
        final foundPathsInDb = supportedFilesFoundOnDisk
            .map((path) => existingTracksMap[path]?.filePath)
            .whereType<String>()
            .toList();
        if (foundPathsInDb.isNotEmpty) {
          await (_db.update(_db.tracks)..where((track) => track.filePath.isIn(foundPathsInDb))).write(
            const TracksCompanion(isMissing: Value(false)),
          );
        }
      }

      taskService.completeTask('library-scan');
    } catch (e, s) {
      log.e("Error scanning library: $e", error: e, stackTrace: s);
      taskService.failTask('library-scan', e.toString());
      rethrow;
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
    final String separator = p.separator;
    final String queryPrefix = normalizedDir.endsWith(separator) ? normalizedDir : '$normalizedDir$separator';

    // Get all track paths under this directory first to remove them from the queue
    final tracksInDir = await (_db.select(
      _db.tracks,
    )..where((track) => track.filePath.lower().like('$queryPrefix%'))).get();

    await (_db.update(_db.tracks)..where((track) => track.filePath.lower().like('$queryPrefix%'))).write(
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

    final trackHash = AudioMetadataHasher.calculateHash(file);

    // Check if the file was moved/renamed (hash matches an existing track)
    final existingTrackByHash = await (_db.select(
      _db.tracks,
    )..where((t) => t.fileHash.equals(trackHash))).getSingleOrNull();

    final normalizedPath = file.path.normalizePath().toLowerCase();

    if (existingTrackByHash != null) {
      final normalizedDbPath = existingTrackByHash.filePath.normalizePath().toLowerCase();
      if (normalizedDbPath != normalizedPath) {
        log.i(
          "Detected file moved/renamed via watcher: '${existingTrackByHash.filePath}' -> '${file.path}'. Reconnecting database entry...",
        );
      }
      await (_db.update(_db.tracks)..where((t) => t.id.equals(existingTrackByHash.id))).write(
        TracksCompanion(filePath: Value(file.path), isMissing: const Value(false)),
      );
      return;
    }

    // Check if the file already exists in the database by path (potential tag edit)
    final existingTrackByPath =
        await (_db.select(_db.tracks)
              ..where((t) => t.filePath.lower().equals(normalizedPath) & t.isMissing.equals(false))
              ..limit(1))
            .getSingleOrNull();

    if (existingTrackByPath != null) {
      try {
        final trackTag = await AudioTags.read(file.path);
        if (trackTag != null) {
          // Safeguard: Verify if it is the same audio file by checking if the duration matches (within 1 second)
          // Should be replaced with audio fingerprint instead
          final newDurationMs = (trackTag.duration ?? 0) * 1000;
          final durationDifferenceMs = (existingTrackByPath.durationMs - newDurationMs).abs();

          if (durationDifferenceMs <= 1000) {
            log.i("Detected file modified in-place: '${file.path}'. Updating metadata...");
            await _updateTrackMetadataInTransaction(
              trackId: existingTrackByPath.id,
              file: file,
              trackTag: trackTag,
              trackHash: trackHash,
            );
          } else {
            log.i(
              "File at '${file.path}' was replaced with different audio content (duration mismatch: DB has ${existingTrackByPath.durationMs}ms, file has ${newDurationMs}ms). Re-indexing as new...",
            );
            // Soft-delete the old track record
            await markTrackAsMissing(file.path);
            // Index the new file as a brand new track
            await _indexTracks([file]);
          }
        } else {
          log.w("Failed to read tags for modified file: ${file.path}");
        }
      } catch (e) {
        log.e("Error processing tag updates for modified file: $e");
      }
      return;
    }

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

    final taskService = _ref.read(backgroundTaskServiceProvider.notifier);
    taskService.startTask(
      id: 'metadata-reindex',
      name: 'Reindexing Metadata',
      message: 'Fetching track list...',
      isIndeterminate: true,
    );

    try {
      // Clear caches so we fetch fresh IDs and resolve splits correctly
      _artistCache.clear();
      _albumCache.clear();
      _exclusionSetCache = null;

      final existingTracks = await _db.select(_db.tracks).get();
      if (existingTracks.isEmpty) {
        log.i('No tracks in database to re-index.');
        taskService.completeTask('metadata-reindex');
        return;
      }

      final total = existingTracks.length;
      int processed = 0;

      onProgress?.call(processed, total);
      taskService.updateProgress(
        'metadata-reindex',
        processed: processed,
        total: total,
        message: 'Re-indexing track $processed of $total...',
        isIndeterminate: false,
      );

      for (final track in existingTracks) {
        final file = File(track.filePath);
        if (!await file.exists()) {
          processed++;
          onProgress?.call(processed, total);
          taskService.updateProgress(
            'metadata-reindex',
            processed: processed,
            total: total,
            message: 'Re-indexing track $processed of $total...',
          );
          continue;
        }

        try {
          final trackTag = await AudioTags.read(file.path);
          if (trackTag == null) {
            processed++;
            onProgress?.call(processed, total);
            taskService.updateProgress(
              'metadata-reindex',
              processed: processed,
              total: total,
              message: 'Re-indexing track $processed of $total...',
            );
            continue;
          }

          final trackHash = AudioMetadataHasher.calculateHash(file);

          await _updateTrackMetadataInTransaction(
            trackId: track.id,
            file: file,
            trackTag: trackTag,
            trackHash: trackHash,
          );
        } catch (e) {
          log.e("Error re-indexing track ${track.filePath}: $e");
        }

        processed++;
        onProgress?.call(processed, total);
        taskService.updateProgress(
          'metadata-reindex',
          processed: processed,
          total: total,
          message: 'Re-indexing track $processed of $total...',
        );
      }

      // Clean up orphaned artists and albums
      await _db.deleteOrphanedMetadata();
      log.i('Forced metadata re-indexing complete.');
      taskService.completeTask('metadata-reindex');
    } catch (e, s) {
      log.e("Error during metadata re-indexing: $e", error: e, stackTrace: s);
      taskService.failTask('metadata-reindex', e.toString());
      rethrow;
    }
  }

  // =========================================== Helper Function ======================================================

  /// Updates a track's metadata, album, and artist relations in the database in a transaction.
  Future<void> _updateTrackMetadataInTransaction({
    required int trackId,
    required File file,
    required Tag trackTag,
    required String trackHash,
  }) async {
    List<int> allArtistIds = await _splitArtistsAndGetOrCreateArtist(trackTag);
    final primaryArtistId = allArtistIds.first;

    int albumId = await _getOrCreateAlbum(trackTag, primaryArtistId);

    final artPath = await _saveAlbumArt(trackTag, albumId);
    if (artPath != null) {
      await (_db.update(
        _db.albums,
      )..where((a) => a.id.equals(albumId))).write(AlbumsCompanion(albumArtPath: Value(artPath)));
    }

    await _db.transaction(() async {
      // Update track info in-place
      await (_db.update(_db.tracks)..where((t) => t.id.equals(trackId))).write(
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
      await (_db.delete(_db.trackArtist)..where((ta) => ta.trackId.equals(trackId))).go();

      // Re-insert the updated artist relations
      for (final artistId in allArtistIds) {
        await _db
            .into(_db.trackArtist)
            .insert(
              TrackArtistCompanion(trackId: Value(trackId), artistId: Value(artistId)),
              mode: InsertMode.insertOrIgnore,
            );
      }
    });
  }

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

        String trackHash = AudioMetadataHasher.calculateHash(trackFile);

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

  /// Splits the artist string in [trackTag] using the configured artist delimiters, get or create the
  /// corresponding artist records, and returns their database IDs.
  /// The first element in the returned list is always the primary artist ID.
  Future<List<int>> _splitArtistsAndGetOrCreateArtist(Tag trackTag) async {
    final rawArtistString = trackTag.trackArtist ?? 'Unknown Artist';
    final trimmedRaw = rawArtistString.trim();

    final exclusions = _exclusionSetCache ??= _appConfig.artistExclusions.map((e) => e.toLowerCase().trim()).toSet();
    if (exclusions.contains(trimmedRaw.toLowerCase())) {
      final id = await _getOrCreateSingleArtist(trimmedRaw);
      return [id];
    }

    // Sort delimiters by length in descending order to avoid prefix matching issues
    // (e.g. matching 'feat' before 'feat.' would leave a stray dot behind).
    final sortedDelimiters = List<String>.from(_appConfig.artistDelimiters)
      ..sort((a, b) => b.length.compareTo(a.length));

    // Build the regex parts, wrapping alphabetical word-based delimiters (like 'feat' or 'ft')
    // in word boundaries (\b) to prevent splitting inside normal words (like 'After' or 'Left').
    final List<String> regexParts = [];
    for (final delimiter in sortedDelimiters) {
      final escaped = RegExp.escape(delimiter);
      final startsWithWordChar = RegExp(r'^\w').hasMatch(delimiter);
      final endsWithWordChar = RegExp(r'\w$').hasMatch(delimiter);
      String part = escaped;
      if (startsWithWordChar) {
        part = '\\b$part';
      }
      if (endsWithWordChar) {
        part = '$part\\b';
      }
      regexParts.add(part);
    }

    // Join with OR (|) and match optional surrounding whitespace.
    final String pattern = regexParts.join('|');
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

  /// Determines if [albumArtist] represents a multi-artist release or compilation
  /// by evaluating configured split delimiters and compilation keywords.
  bool _isMultiArtistOrCompilation(String albumArtist) {
    final lower = albumArtist.toLowerCase().trim();
    if (lower == 'various artists' || lower == 'various' || lower == 'soundtrack') {
      return true;
    }

    final exclusions = _exclusionSetCache ??= _appConfig.artistExclusions.map((e) => e.toLowerCase().trim()).toSet();
    if (exclusions.contains(lower)) {
      return false;
    }

    // Sort delimiters by length in descending order to avoid prefix matching issues.
    final sortedDelimiters = List<String>.from(_appConfig.artistDelimiters)
      ..sort((a, b) => b.length.compareTo(a.length));

    // Evaluate each delimiter, ensuring word-based delimiters (like 'feat' or 'ft')
    // use word boundaries (\b) so we don't accidentally match normal words (like 'After').
    for (final delimiter in sortedDelimiters) {
      final escaped = RegExp.escape(delimiter);
      final startsWithWordChar = RegExp(r'^\w').hasMatch(delimiter);
      final endsWithWordChar = RegExp(r'\w$').hasMatch(delimiter);
      String part = escaped;
      if (startsWithWordChar) {
        part = '\\b$part';
      }
      if (endsWithWordChar) {
        part = '$part\\b';
      }
      // Match the delimiter surrounded by optional whitespace
      final regex = RegExp('\\s*(?:$part)\\s*', caseSensitive: false);
      if (regex.hasMatch(albumArtist)) {
        return true;
      }
    }
    return false;
  }

  /// Resolves or inserts a single artist record by name and returns its database ID.
  Future<int> _getOrCreateSingleArtist(String name) async {
    final trimmedName = name.trim();
    if (_artistCache.containsKey(trimmedName)) {
      return _artistCache[trimmedName]!;
    }

    final existing = await (_db.select(_db.artists)..where((a) => a.name.equals(trimmedName))).getSingleOrNull();
    if (existing != null) {
      _artistCache[trimmedName] = existing.id;
      return existing.id;
    } else {
      final newId = await _db.into(_db.artists).insert(ArtistsCompanion(name: Value(trimmedName)));
      _artistCache[trimmedName] = newId;
      return newId;
    }
  }

  /// Gets the database ID of the album in [trackTag] or create the album record if it doesn't exist.
  /// Returns the album id. Uses text-based album grouping for deduplication.
  Future<int> _getOrCreateAlbum(Tag trackTag, int primaryArtistId) async {
    int albumId;
    final albumTitle = trackTag.album ?? 'Unknown Album';
    final albumArtist = trackTag.albumArtist ?? trackTag.trackArtist ?? 'Unknown Artist';
    final albumCacheKey = '$albumTitle-$albumArtist';

    if (_albumCache.containsKey(albumCacheKey)) {
      albumId = _albumCache[albumCacheKey]!;
    } else {
      final existingAlbumArtist = await (_db.select(
        _db.albums,
      )..where((a) => a.title.equals(albumTitle) & a.albumArtist.equals(albumArtist))).getSingleOrNull();

      if (existingAlbumArtist != null) {
        _albumCache[albumCacheKey] = existingAlbumArtist.id;
        albumId = existingAlbumArtist.id;
      } else {
        final bool isMulti = _isMultiArtistOrCompilation(albumArtist);
        int? targetArtistId;
        if (!isMulti) {
          targetArtistId = await _getOrCreateSingleArtist(albumArtist);
        }

        final newId = await _db
            .into(_db.albums)
            .insert(
              AlbumsCompanion(
                title: Value(albumTitle),
                year: Value(trackTag.year ?? 0),
                albumArtist: Value(albumArtist),
                albumArtistId: Value(targetArtistId),
              ),
            );
        _albumCache[albumCacheKey] = newId;
        albumId = newId;
      }
    }

    return albumId;
  }
}
