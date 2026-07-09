import 'dart:io';
import 'dart:isolate';

import 'package:audiotags/audiotags.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nordplayer/database/app_database.dart';
import 'package:nordplayer/models/app_config.dart';
import 'package:nordplayer/services/background_task_service.dart';
import 'package:nordplayer/services/config_service.dart';
import 'package:nordplayer/services/logger.dart';
import 'package:nordplayer/utils/audio_metadata_hasher.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class TrackIndexer with LoggerMixin {
  TrackIndexer(this._ref, this._db, this._onCancelFingerprintTask);

  final Ref _ref;
  final AppDatabase _db;
  final VoidCallback _onCancelFingerprintTask;

  AppConfig get _appConfig => _ref.read(configServiceProvider).requireValue;

  // Map<ArtistName, ArtistId>
  final Map<String, int> _artistCache = {};
  // Map<"AlbumName-AlbumArtist", AlbumId>
  final Map<String, int> _albumCache = {};

  Future<void> indexTracks(List<(File, String)> files, {void Function(int processed, int total)? onProgress}) async {
    const int chunkSize = 50;
    final total = files.length;
    int processed = 0;

    onProgress?.call(0, total);

    for (var i = 0; i < files.length; i += chunkSize) {
      final end = (i + chunkSize < files.length) ? i + chunkSize : files.length;
      final chunk = files.sublist(i, end);

      await indexTracksChunk(
        chunk,
        onProgress: (insertedInChunk) {
          onProgress?.call(processed + insertedInChunk, total);
        },
      );
      processed += chunk.length;
      onProgress?.call(processed, total);
    }
  }

  Future<void> indexTracksChunk(List<(File, String)> files, {void Function(int inserted)? onProgress}) async {
    // Read all metadata on the main thread
    final metadataList = await Future.wait(
      files.map((item) async {
        final file = item.$1;
        final hash = item.$2;
        try {
          final tag = await AudioTags.read(file.path);
          return (file.path, hash, tag);
        } catch (e) {
          log.e("Error parsing ${file.path}: $e");
          return (file.path, hash, null);
        }
      }),
    );

    int insertedCount = 0;
    final cacheDir = await getApplicationCacheDirectory();

    final request = IndexTracksChunkIsolateRequest(
      metadataList: metadataList,
      artistExclusions: _appConfig.artistExclusions.map((e) => e.toLowerCase().trim()).toSet(),
      artistDelimiters: _appConfig.artistDelimiters.toList(),
      artistCache: Map<String, int>.from(_artistCache),
      albumCache: Map<String, int>.from(_albumCache),
      cacheDirPath: cacheDir.path,
      token: RootIsolateToken.instance,
    );

    try {
      final response = await Isolate.run(_buildIndexTracksIsolateClosure(request));

      _artistCache.addAll(response.artistCache);
      _albumCache.addAll(response.albumCache);

      for (var i = 0; i < files.length; i++) {
        insertedCount++;
        onProgress?.call(insertedCount);
      }
    } catch (e) {
      log.e("Failed to run chunk indexing in background isolate: $e");
    }
  }

  Future<void> reindexTracks({void Function(int processed, int total)? onProgress, VoidCallback? onComplete}) async {
    _onCancelFingerprintTask();
    log.i('Starting forced in-place metadata re-indexing of all tracks...');

    final bgTaskService = _ref.read(backgroundTaskServiceProvider.notifier);
    bgTaskService.startTask(
      id: 'metadata-reindex',
      name: 'Reindexing Metadata',
      message: 'Fetching track list...',
      isIndeterminate: true,
    );

    try {
      _artistCache.clear();
      _albumCache.clear();

      final existingTracks = await _db.select(_db.tracks).get();
      if (existingTracks.isEmpty) {
        log.i('No tracks in database to re-index.');
        bgTaskService.completeTask('metadata-reindex');
        return;
      }

      final total = existingTracks.length;
      int processed = 0;

      onProgress?.call(processed, total);
      bgTaskService.updateProgress(
        'metadata-reindex',
        processed: processed,
        total: total,
        message: 'Re-indexing track: $processed of $total',
        isIndeterminate: false,
      );

      const int chunkSize = 50;

      for (var i = 0; i < existingTracks.length; i += chunkSize) {
        final end = (i + chunkSize < existingTracks.length) ? i + chunkSize : existingTracks.length;
        final chunk = existingTracks.sublist(i, end);

        final chunkTracksPayload = chunk.map((t) => (t.id, t.filePath, t.audioFingerprint)).toList();

        await reindexTracksChunk(chunkTracksPayload);

        processed += chunk.length;
        onProgress?.call(processed, total);
        bgTaskService.updateProgress(
          'metadata-reindex',
          processed: processed,
          total: total,
          message: 'Re-indexing track: $processed of $total',
        );
      }

      // Clean up orphaned artists and albums
      await _db.deleteOrphanedMetadata();
      log.i('Forced metadata re-indexing complete.');
      bgTaskService.completeTask('metadata-reindex');

      onComplete?.call();
    } catch (e, s) {
      log.e("Error during metadata re-indexing: $e", error: e, stackTrace: s);
      bgTaskService.failTask('metadata-reindex', e.toString());
      rethrow;
    }
  }

  Future<void> reindexTracksChunk(List<(int, String, Uint8List?)> tracks) async {
    final cacheDir = await getApplicationCacheDirectory();

    final request = ReindexTracksChunkIsolateRequest(
      tracks: tracks,
      artistExclusions: _appConfig.artistExclusions.map((e) => e.toLowerCase().trim()).toSet(),
      artistDelimiters: _appConfig.artistDelimiters.toList(),
      artistCache: Map<String, int>.from(_artistCache),
      albumCache: Map<String, int>.from(_albumCache),
      cacheDirPath: cacheDir.path,
      token: RootIsolateToken.instance,
    );

    try {
      final response = await Isolate.run(_buildReindexTracksIsolateClosure(request));
      _artistCache.addAll(response.artistCache);
      _albumCache.addAll(response.albumCache);
    } catch (e) {
      log.e("Failed to run reindex chunk in background isolate: $e");
    }
  }
}

class IndexTracksChunkIsolateRequest {
  const IndexTracksChunkIsolateRequest({
    required this.metadataList,
    required this.artistExclusions,
    required this.artistDelimiters,
    required this.artistCache,
    required this.albumCache,
    required this.cacheDirPath,
    required this.token,
  });
  final List<(String, String, Tag?)> metadataList;
  final Set<String> artistExclusions;
  final List<String> artistDelimiters;
  final Map<String, int> artistCache;
  final Map<String, int> albumCache;
  final String cacheDirPath;
  final RootIsolateToken? token;
}

class TrackIndexerIsolateResponse {
  const TrackIndexerIsolateResponse({required this.artistCache, required this.albumCache});

  final Map<String, int> artistCache;
  final Map<String, int> albumCache;
}

class ReindexTracksChunkIsolateRequest {
  const ReindexTracksChunkIsolateRequest({
    required this.tracks,
    required this.artistExclusions,
    required this.artistDelimiters,
    required this.artistCache,
    required this.albumCache,
    required this.cacheDirPath,
    required this.token,
  });

  final List<(int, String, Uint8List?)> tracks; // (id, filePath, audioFingerprint)
  final Set<String> artistExclusions;
  final List<String> artistDelimiters;
  final Map<String, int> artistCache;
  final Map<String, int> albumCache;
  final String cacheDirPath;
  final RootIsolateToken? token;
}

Future<TrackIndexerIsolateResponse> Function() _buildIndexTracksIsolateClosure(IndexTracksChunkIsolateRequest request) {
  return () => _indexTracksChunkIsolate(request);
}

Future<TrackIndexerIsolateResponse> Function() _buildReindexTracksIsolateClosure(
  ReindexTracksChunkIsolateRequest request,
) {
  return () => _reindexTracksChunkIsolate(request);
}

Future<TrackIndexerIsolateResponse> _indexTracksChunkIsolate(IndexTracksChunkIsolateRequest request) async {
  if (request.token != null) {
    BackgroundIsolateBinaryMessenger.ensureInitialized(request.token!);
  }
  final db = AppDatabase();
  final artistCache = Map<String, int>.from(request.artistCache);
  final albumCache = Map<String, int>.from(request.albumCache);

  await db.transaction(() async {
    for (var item in request.metadataList) {
      final trackPath = item.$1;
      final trackHash = item.$2;
      final trackTag = item.$3;

      if (trackTag == null) {
        continue;
      }

      final trackFile = File(trackPath);

      final List<int> allArtistIds = await _splitArtistsAndGetOrCreateArtistIsolate(
        db,
        trackTag,
        request.artistExclusions,
        request.artistDelimiters,
        artistCache,
      );
      final primaryArtistId = allArtistIds.first;

      final int albumId = await _getOrCreateAlbumIsolate(
        db,
        trackTag,
        primaryArtistId,
        request.artistExclusions,
        request.artistDelimiters,
        artistCache,
        albumCache,
      );

      final artPath = await _saveAlbumArtIsolate(trackTag, albumId, request.cacheDirPath);
      if (artPath != null) {
        await (db.update(
          db.albums,
        )..where((a) => a.id.equals(albumId))).write(AlbumsCompanion(albumArtPath: Value(artPath)));
      }

      final newTrackId = await db
          .into(db.tracks)
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
        await db
            .into(db.trackArtist)
            .insert(
              TrackArtistCompanion(trackId: Value(newTrackId), artistId: Value(artistId)),
              mode: InsertMode.insertOrIgnore,
            );
      }
    }
  });

  await db.close();

  return TrackIndexerIsolateResponse(artistCache: artistCache, albumCache: albumCache);
}

Future<TrackIndexerIsolateResponse> _reindexTracksChunkIsolate(ReindexTracksChunkIsolateRequest request) async {
  if (request.token != null) {
    BackgroundIsolateBinaryMessenger.ensureInitialized(request.token!);
  }
  final db = AppDatabase();
  final artistCache = Map<String, int>.from(request.artistCache);
  final albumCache = Map<String, int>.from(request.albumCache);

  await db.transaction(() async {
    for (final item in request.tracks) {
      final trackId = item.$1;
      final trackPath = item.$2;
      final audioFingerprint = item.$3;

      final file = File(trackPath);
      if (!await file.exists()) continue;

      try {
        final trackTag = await AudioTags.read(trackPath);
        if (trackTag == null) continue;

        final trackHash = AudioMetadataHasher.calculateHash(file);

        final List<int> allArtistIds = await _splitArtistsAndGetOrCreateArtistIsolate(
          db,
          trackTag,
          request.artistExclusions,
          request.artistDelimiters,
          artistCache,
        );
        final primaryArtistId = allArtistIds.first;

        final int albumId = await _getOrCreateAlbumIsolate(
          db,
          trackTag,
          primaryArtistId,
          request.artistExclusions,
          request.artistDelimiters,
          artistCache,
          albumCache,
        );

        final artPath = await _saveAlbumArtIsolate(trackTag, albumId, request.cacheDirPath);
        if (artPath != null) {
          await (db.update(
            db.albums,
          )..where((a) => a.id.equals(albumId))).write(AlbumsCompanion(albumArtPath: Value(artPath)));
        }

        // Update track metadata in-place
        await (db.update(db.tracks)..where((t) => t.id.equals(trackId))).write(
          TracksCompanion(
            title: Value(trackTag.title ?? p.basename(trackPath)),
            trackNumber: Value(trackTag.trackNumber ?? 0),
            trackTotal: Value(trackTag.trackTotal ?? 0),
            discNumber: Value(trackTag.discNumber ?? 0),
            discTotal: Value(trackTag.discTotal ?? 0),
            durationMs: Value((trackTag.duration ?? 0) * 1000),
            genre: Value(trackTag.genre),
            fileSize: Value(file.lengthSync()),
            fileHash: Value(trackHash),
            audioFingerprint: Value(audioFingerprint),
            artistId: Value(primaryArtistId),
            albumId: Value(albumId),
            isMissing: const Value(false),
          ),
        );

        // Update artist relations for this track
        await (db.delete(db.trackArtist)..where((ta) => ta.trackId.equals(trackId))).go();
        for (final artistId in allArtistIds) {
          await db
              .into(db.trackArtist)
              .insert(
                TrackArtistCompanion(trackId: Value(trackId), artistId: Value(artistId)),
                mode: InsertMode.insertOrIgnore,
              );
        }
      } catch (e) {
        debugPrint("Error re-indexing track $trackPath in isolate: $e");
      }
    }
  });

  await db.close();

  return TrackIndexerIsolateResponse(artistCache: artistCache, albumCache: albumCache);
}

Future<List<int>> _splitArtistsAndGetOrCreateArtistIsolate(
  AppDatabase db,
  Tag trackTag,
  Set<String> exclusions,
  List<String> delimiters,
  Map<String, int> artistCache,
) async {
  final rawArtistString = trackTag.trackArtist ?? 'Unknown Artist';
  final trimmedRaw = rawArtistString.trim();

  if (exclusions.contains(trimmedRaw.toLowerCase())) {
    final id = await _getOrCreateSingleArtistIsolate(db, trimmedRaw, artistCache);
    return [id];
  }

  final sortedDelimiters = List<String>.from(delimiters)..sort((a, b) => b.length.compareTo(a.length));

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

  final String pattern = regexParts.join('|');
  final RegExp separator = RegExp('\\s*(?:$pattern)\\s*', caseSensitive: false);

  List<String> artistNames = rawArtistString.split(separator).map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

  if (artistNames.isEmpty) artistNames = ['Unknown Artist'];

  final List<int> allArtistIds = [];

  for (final name in artistNames.toSet()) {
    int id;
    if (artistCache.containsKey(name)) {
      id = artistCache[name]!;
    } else {
      final existing = await (db.select(db.artists)..where((a) => a.name.equals(name))).getSingleOrNull();
      if (existing != null) {
        artistCache[name] = existing.id;
        id = existing.id;
      } else {
        final newId = await db.into(db.artists).insert(ArtistsCompanion(name: Value(name)));
        artistCache[name] = newId;
        id = newId;
      }
    }
    allArtistIds.add(id);
  }

  return allArtistIds;
}

Future<int> _getOrCreateSingleArtistIsolate(AppDatabase db, String name, Map<String, int> artistCache) async {
  final trimmedName = name.trim();
  if (artistCache.containsKey(trimmedName)) {
    return artistCache[trimmedName]!;
  }

  final existing = await (db.select(db.artists)..where((a) => a.name.equals(trimmedName))).getSingleOrNull();
  if (existing != null) {
    artistCache[trimmedName] = existing.id;
    return existing.id;
  } else {
    final newId = await db.into(db.artists).insert(ArtistsCompanion(name: Value(trimmedName)));
    artistCache[trimmedName] = newId;
    return newId;
  }
}

bool _isMultiArtistOrCompilationIsolate(String albumArtist, Set<String> exclusions, List<String> delimiters) {
  final lower = albumArtist.toLowerCase().trim();
  if (lower == 'various artists' || lower == 'various' || lower == 'soundtrack') {
    return true;
  }

  if (exclusions.contains(lower)) {
    return false;
  }

  final sortedDelimiters = List<String>.from(delimiters)..sort((a, b) => b.length.compareTo(a.length));

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
    final regex = RegExp('\\s*(?:$part)\\s*', caseSensitive: false);
    if (regex.hasMatch(albumArtist)) {
      return true;
    }
  }
  return false;
}

Future<int> _getOrCreateAlbumIsolate(
  AppDatabase db,
  Tag trackTag,
  int primaryArtistId,
  Set<String> exclusions,
  List<String> delimiters,
  Map<String, int> artistCache,
  Map<String, int> albumCache,
) async {
  int albumId;
  final albumTitle = trackTag.album ?? 'Unknown Album';
  final albumArtist = trackTag.albumArtist ?? trackTag.trackArtist ?? 'Unknown Artist';
  final albumCacheKey = '$albumTitle-$albumArtist';

  if (albumCache.containsKey(albumCacheKey)) {
    albumId = albumCache[albumCacheKey]!;
  } else {
    final existingAlbumArtist = await (db.select(
      db.albums,
    )..where((a) => a.title.equals(albumTitle) & a.albumArtist.equals(albumArtist))).getSingleOrNull();

    if (existingAlbumArtist != null) {
      albumCache[albumCacheKey] = existingAlbumArtist.id;
      albumId = existingAlbumArtist.id;
    } else {
      final bool isMulti = _isMultiArtistOrCompilationIsolate(albumArtist, exclusions, delimiters);
      int? targetArtistId;
      if (!isMulti) {
        targetArtistId = await _getOrCreateSingleArtistIsolate(db, albumArtist, artistCache);
      }

      final newId = await db
          .into(db.albums)
          .insert(
            AlbumsCompanion(
              title: Value(albumTitle),
              year: Value(trackTag.year ?? 0),
              albumArtist: Value(albumArtist),
              albumArtistId: Value(targetArtistId),
            ),
          );
      albumCache[albumCacheKey] = newId;
      albumId = newId;
    }
  }

  return albumId;
}

Future<String?> _saveAlbumArtIsolate(Tag trackTag, int albumId, String cacheDirPath) async {
  if (trackTag.pictures.isEmpty) return null;

  final artDir = Directory(p.join(cacheDirPath, 'album_art'));
  if (!artDir.existsSync()) {
    artDir.createSync(recursive: true);
  }

  final picture = trackTag.pictures.first;
  final String ext = picture.mimeType == MimeType.png ? '.png' : '.jpg';

  final String fileName = "album_$albumId$ext";
  final String fullPath = p.join(artDir.path, fileName);

  if (File(fullPath).existsSync()) {
    return fullPath;
  }

  try {
    File(fullPath).writeAsBytesSync(picture.bytes);
    return fullPath;
  } catch (e) {
    debugPrint("Failed to save album art in isolate: $e");
    return null;
  }
}
