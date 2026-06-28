import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nordplayer/database/schema.dart';
import 'package:nordplayer/utils/directory_helper.dart';
import 'package:nordplayer/utils/string_extension.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Tracks,
    Artists,
    Albums,
    Playlists,
    TrackArtist,
    PlaylistTrack,
    QueueEntries,
    PlayHistory,
    SourcePriorities,
    ArtistMetadata,
    AlbumMetadata,
    UserFavorites,
    UserBlacklist,
    UserPins,
    IgnoredPaths,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) async {
        await m.createAll();
      },
      onUpgrade: (migrator, from, to) async {
        if (from < 2) {
          await migrator.addColumn(artists, artists.artistImgPath);
          await migrator.addColumn(albums, albums.albumArtistId);
          await migrator.addColumn(tracks, tracks.fileHash);
          await migrator.addColumn(tracks, tracks.audioFingerprint);
          await migrator.addColumn(tracks, tracks.isMissing);

          await migrator.createTable(playHistory);
          await migrator.createTable(sourcePriorities);
          await migrator.createTable(artistMetadata);
          await migrator.createTable(albumMetadata);
          await migrator.createTable(userFavorites);
          await migrator.createTable(userBlacklist);
          await migrator.createTable(userPins);
          await migrator.createTable(ignoredPaths);
        }
      },
    );
  }

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'database',
      native: DriftNativeOptions(
        databaseDirectory: getDatabaseDirectory,
        setup: (db) {
          // Enable WAL (Write-Ahead Logging) Mode (Higher concurrency, less locking)
          db.execute('PRAGMA journal_mode=WAL;');
          // Synchronous Normal (Faster writes, slightly less safe on power loss)
          db.execute('PRAGMA synchronous=NORMAL;');
        },
      ),
    );
  }

  Future<void> clearAllData() async {
    await customStatement('PRAGMA foreign_keys = OFF;');

    try {
      await transaction(() async {
        await customStatement('DELETE FROM queue_entries;');
        await customStatement('DELETE FROM playlist_track;');
        await customStatement('DELETE FROM track_artist;');

        await customStatement('DELETE FROM playlists;');
        await customStatement('DELETE FROM tracks;');
        await customStatement('DELETE FROM albums;');
        await customStatement('DELETE FROM artists;');
        await customStatement('DELETE FROM ignored_paths;');
      });

      await customStatement('PRAGMA foreign_keys = ON;');

      // Reclaim empty disk spaces and reduce file size back to zero
      await customStatement('VACUUM;');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteOrphanedMetadata() async {
    await transaction(() async {
      // Delete albums that no longer have any tracks pointing to them
      await customStatement('''
      DELETE FROM albums 
      WHERE id NOT IN (SELECT DISTINCT album_id FROM tracks WHERE album_id IS NOT NULL);
    ''');

      // Delete artists who no longer have any tracks OR albums OR track_artist relations pointing to them
      await customStatement('''
      DELETE FROM artists 
      WHERE id NOT IN (SELECT DISTINCT artist_id FROM tracks WHERE artist_id IS NOT NULL)
        AND id NOT IN (SELECT DISTINCT album_artist_id FROM albums WHERE album_artist_id IS NOT NULL)
        AND id NOT IN (SELECT DISTINCT artist_id FROM track_artist);
    ''');
    });
  }

  // =========================================== Library Stats =======================================================

  Stream<LibraryStats> watchLibraryStats() {
    // We use a single raw SQL query to get all counts and sums at once for maximum performance.
    const query = '''
      SELECT
        (SELECT COUNT(*) FROM tracks WHERE is_missing = 0) AS trackCount,
        (SELECT COUNT(DISTINCT album_id) FROM tracks WHERE album_id IS NOT NULL AND is_missing = 0) AS albumCount,
        (SELECT COUNT(DISTINCT track_artist.artist_id) FROM track_artist INNER JOIN tracks ON tracks.id = track_artist.track_id WHERE tracks.is_missing = 0) AS artistCount,
        (SELECT COUNT(*) FROM playlists) AS playlistCount,
        (SELECT COUNT(DISTINCT genre) FROM tracks WHERE genre IS NOT NULL AND genre != '' AND is_missing = 0) AS genreCount,
        (SELECT SUM(file_size) FROM tracks WHERE is_missing = 0) AS totalSize,
        (SELECT SUM(duration_ms) FROM tracks WHERE is_missing = 0) AS totalDuration
    ''';

    return customSelect(
      query,
      // By passing the tables here, Drift knows to automatically push new stream events
      // whenever ANY of these tables are modified (like adding a new track or playlist).
      readsFrom: {tracks, albums, artists, playlists},
    ).watchSingle().map((row) {
      return LibraryStats(
        trackCount: row.read<int>('trackCount'),
        albumCount: row.read<int>('albumCount'),
        artistCount: row.read<int>('artistCount'),
        playlistCount: row.read<int>('playlistCount'),
        genreCount: row.read<int>('genreCount'),
        // SUM can return null if the table is completely empty, so we fallback to 0
        totalSizeBytes: row.read<int?>('totalSize') ?? 0,
        totalPlaytimeMs: row.read<int?>('totalDuration') ?? 0,
      );
    });
  }

  // ============================================= Tracks Stuff =======================================================

  /// Watch all tracks in the library, sorted alphabetically.
  Stream<List<TrackWithArtists>> watchAllTracks() {
    final query = (select(tracks)..where((t) => t.isMissing.equals(false))).join([
      leftOuterJoin(albums, albums.id.equalsExp(tracks.albumId)),
      leftOuterJoin(trackArtist, trackArtist.trackId.equalsExp(tracks.id)),
      leftOuterJoin(artists, artists.id.equalsExp(trackArtist.artistId)),
    ])..orderBy([OrderingTerm.asc(tracks.title.lower())]);

    return query.watch().map((rows) {
      final Map<int, TrackWithArtists> groupedTracks = {};

      for (final row in rows) {
        final track = row.readTable(tracks);
        final album = row.readTable(albums);
        final artist = row.readTableOrNull(artists);

        // If track is new, create the entry
        if (!groupedTracks.containsKey(track.id)) {
          groupedTracks[track.id] = TrackWithArtists(track: track, album: album, artists: []);
        }

        // Add the artist from this row to the artists list
        // distinct check to avoid duplicates if query logic overlaps
        final currentArtists = groupedTracks[track.id]!.artists;

        // Safety check: Because it's a leftOuterJoin, ensure we don't add a null/empty artist
        if (artist != null && artist.id != 0 && !currentArtists.any((a) => a.id == artist.id)) {
          currentArtists.add(artist);
        }
      }

      return groupedTracks.values.toList();
    });
  }

  Future<TrackWithArtists?> getTrackWithArtistsById(int id) async {
    final query = select(tracks).join([
      leftOuterJoin(albums, albums.id.equalsExp(tracks.albumId)),
      leftOuterJoin(trackArtist, trackArtist.trackId.equalsExp(tracks.id)),
      leftOuterJoin(artists, artists.id.equalsExp(trackArtist.artistId)),
    ])..where(tracks.id.equals(id));

    final rows = await query.get();
    if (rows.isEmpty) return null;

    final track = rows.first.readTable(tracks);
    final album = rows.first.readTable(albums);
    final artistList = rows
        .map((row) => row.readTableOrNull(artists))
        .whereType<Artist>()
        .where((a) => a.id != 0) // filter null-joined rows
        .fold<List<Artist>>([], (list, a) {
          if (!list.any((x) => x.id == a.id)) list.add(a);
          return list;
        });

    return TrackWithArtists(track: track, album: album, artists: artistList);
  }

  Stream<List<TrackWithArtists>> watchRecentlyAddedTracks({int limitAmount = 10}) {
    final query = (select(tracks)..where((t) => t.isMissing.equals(false))).join([
      leftOuterJoin(albums, albums.id.equalsExp(tracks.albumId)),
      leftOuterJoin(trackArtist, trackArtist.trackId.equalsExp(tracks.id)),
      leftOuterJoin(artists, artists.id.equalsExp(trackArtist.artistId)),
    ]);

    // Order by the date they were added, newest first
    query.orderBy([OrderingTerm.desc(tracks.dateAdded)]);

    // Buffer the SQL limit to account for tracks with multiple artists (e.g., 10 tracks * up to 4 artists = 40 rows max)
    query.limit(limitAmount * 4);

    return query.watch().map((rows) {
      final Map<int, TrackWithArtists> groupedTracks = {};

      for (final row in rows) {
        final track = row.readTable(tracks);
        final album = row.readTable(albums);
        final artist = row.readTableOrNull(artists);

        if (!groupedTracks.containsKey(track.id)) {
          groupedTracks[track.id] = TrackWithArtists(track: track, album: album, artists: []);
        }

        if (artist != null && artist.id != 0) {
          final currentArtists = groupedTracks[track.id]!.artists;
          if (!currentArtists.any((a) => a.id == artist.id)) {
            currentArtists.add(artist);
          }
        }
      }

      // Enforce the strict limit after grouping the tracks
      return groupedTracks.values.take(limitAmount).toList();
    });
  }

  // ============================================= Albums Stuff =======================================================

  /// Get all albums
  /// Usage: main album page
  Stream<List<Album>> watchAlbums() {
    final query =
        select(albums).join([innerJoin(tracks, tracks.albumId.equalsExp(albums.id) & tracks.isMissing.equals(false))])
          ..groupBy([albums.id])
          ..orderBy([OrderingTerm.asc(albums.title)]);

    return query.watch().map((rows) {
      return rows.map((row) => row.readTable(albums)).toList();
    });
  }

  Stream<AlbumWithTracks?> watchAlbumWithTracks(int albumId) {
    final query = select(albums).join([
      leftOuterJoin(tracks, tracks.albumId.equalsExp(albums.id) & tracks.isMissing.equals(false)),
      leftOuterJoin(trackArtist, trackArtist.trackId.equalsExp(tracks.id)),
      leftOuterJoin(artists, artists.id.equalsExp(trackArtist.artistId)),
    ])..where(albums.id.equals(albumId));

    query.orderBy([OrderingTerm.asc(tracks.trackNumber)]);

    return query.watch().map((rows) {
      if (rows.isEmpty) return null;

      final album = rows.first.readTable(albums);

      // Use a Map to group the rows by track ID.
      // If a track has 3 artists, it returns 3 rows, should group them to avoid duplicates.
      final Map<int, TrackWithArtists> groupedTracks = {};
      int tracksLengthMs = 0;

      for (final row in rows) {
        final track = row.readTableOrNull(tracks);

        if (track != null) {
          if (!groupedTracks.containsKey(track.id)) {
            groupedTracks[track.id] = TrackWithArtists(track: track, album: album, artists: []);
            tracksLengthMs += track.durationMs;
          }

          final artist = row.readTableOrNull(artists);
          if (artist != null && artist.id != 0) {
            final currentArtists = groupedTracks[track.id]!.artists;
            if (!currentArtists.any((a) => a.id == artist.id)) {
              currentArtists.add(artist);
            }
          }
        }
      }

      return AlbumWithTracks(album: album, tracks: groupedTracks.values.toList(), tracksLengthMs: tracksLengthMs);
    });
  }

  Future<List<Artist>> getTrackArtists({required int albumId}) {
    final query =
        select(artists, distinct: true).join([
            innerJoin(trackArtist, trackArtist.artistId.equalsExp(artists.id)),
            innerJoin(tracks, tracks.id.equalsExp(trackArtist.trackId)),
          ])
          ..where(tracks.albumId.equals(albumId) & tracks.isMissing.equals(false))
          ..orderBy([OrderingTerm.asc(artists.name)]);

    return query.get().then((rows) => rows.map((row) => row.readTable(artists)).toList());
  }

  /// Fetches a list of random albums.
  /// Using a Future instead of a Stream prevents the UI from re-shuffling every time the database receives an update.
  Future<List<Album>> getRandomAlbums({int limitAmount = 10}) {
    final query =
        select(albums).join([innerJoin(tracks, tracks.albumId.equalsExp(albums.id) & tracks.isMissing.equals(false))])
          ..groupBy([albums.id])
          ..orderBy([OrderingTerm(expression: const CustomExpression('RANDOM()'))])
          ..limit(limitAmount);

    return query.get().then((rows) => rows.map((row) => row.readTable(albums)).toList());
  }

  // ============================================= Artists Stuff ====================================================

  /// Get all albums
  /// Usage: main album page
  Stream<List<Artist>> watchArtists() {
    final query =
        select(artists).join([
            innerJoin(trackArtist, trackArtist.artistId.equalsExp(artists.id)),
            innerJoin(tracks, tracks.id.equalsExp(trackArtist.trackId) & tracks.isMissing.equals(false)),
          ])
          ..groupBy([artists.id])
          ..orderBy([OrderingTerm.asc(artists.name)]);

    return query.watch().map((rows) {
      return rows.map((row) => row.readTable(artists)).toList();
    });
  }

  // =========================================== Playlist Stuff =======================================================

  /// Watch a playlists with 5 albums art from this playlist
  /// Used in playlist card
  Stream<List<PlaylistWithDetails>> watchAllPlaylists() {
    final trackCount = playlistTrack.trackId.count();

    // Concat all album art paths into a single string separated by '||'
    final coverPaths = albums.albumArtPath.groupConcat(separator: '||');

    final query =
        select(playlists).join([
            leftOuterJoin(playlistTrack, playlistTrack.playlistId.equalsExp(playlists.id)),
            leftOuterJoin(tracks, tracks.id.equalsExp(playlistTrack.trackId) & tracks.isMissing.equals(false)),
            leftOuterJoin(albums, albums.id.equalsExp(tracks.albumId)),
          ])
          ..addColumns([trackCount, coverPaths]) // Ask SQL for the concatenated string
          ..groupBy([playlists.id])
          ..orderBy([OrderingTerm(expression: playlists.name, mode: OrderingMode.asc)]);

    return query.watch().map((rows) {
      return rows.map((row) {
        final pathsString = row.read(coverPaths);

        List<String> covers = [];
        if (pathsString != null && pathsString.isNotEmpty) {
          covers = pathsString
              .split('||')
              .where((path) => path.trim().isNotEmpty)
              .toSet() // Use a Set to prevent duplicate covers
              .take(5)
              .toList();
        }

        return PlaylistWithDetails(
          playlist: row.readTable(playlists),
          trackCount: row.read(trackCount) ?? 0,
          imageUrls: covers,
        );
      }).toList();
    });
  }

  Future<List<TrackWithArtists>> getPlaylistTracks(int playlistId) async {
    final query = select(tracks).join([
      // Join junction table, filtering strictly to this playlist
      innerJoin(playlistTrack, playlistTrack.trackId.equalsExp(tracks.id)),
      // Join Albums to get the cover art
      leftOuterJoin(albums, albums.id.equalsExp(tracks.albumId)),
      // Join Artists
      leftOuterJoin(trackArtist, trackArtist.trackId.equalsExp(tracks.id)),
      leftOuterJoin(artists, artists.id.equalsExp(trackArtist.artistId)),
    ])..where(playlistTrack.playlistId.equals(playlistId) & tracks.isMissing.equals(false));

    final rows = await query.get();
    final Map<int, TrackWithArtists> groupedTracks = {};

    for (final row in rows) {
      var track = row.readTable(tracks);
      final pt = row.readTable(playlistTrack);
      // Overwrite the library date added with the playlist date added
      track = track.copyWith(dateAdded: pt.dateAdded);

      final album = row.readTable(albums);
      final artist = row.readTableOrNull(artists);

      if (!groupedTracks.containsKey(track.id)) {
        groupedTracks[track.id] = TrackWithArtists(track: track, album: album, artists: []);
      }

      if (artist != null && artist.id != 0) {
        final currentArtists = groupedTracks[track.id]!.artists;
        if (!currentArtists.any((a) => a.id == artist.id)) {
          currentArtists.add(artist);
        }
      }
    }

    return groupedTracks.values.toList();
  }

  Stream<List<TrackWithArtists>> watchPlaylistTracks(int playlistId) {
    final query = select(tracks).join([
      innerJoin(playlistTrack, playlistTrack.trackId.equalsExp(tracks.id)),
      leftOuterJoin(albums, albums.id.equalsExp(tracks.albumId)),
      leftOuterJoin(trackArtist, trackArtist.trackId.equalsExp(tracks.id)),
      leftOuterJoin(artists, artists.id.equalsExp(trackArtist.artistId)),
    ])..where(playlistTrack.playlistId.equals(playlistId) & tracks.isMissing.equals(false));

    return query.watch().map((rows) {
      final Map<int, TrackWithArtists> groupedTracks = {};

      for (final row in rows) {
        var track = row.readTable(tracks);
        final pt = row.readTable(playlistTrack);
        // Overwrite the library date added with the playlist date added
        track = track.copyWith(dateAdded: pt.dateAdded);

        final album = row.readTable(albums);
        final artist = row.readTableOrNull(artists);

        if (!groupedTracks.containsKey(track.id)) {
          groupedTracks[track.id] = TrackWithArtists(track: track, album: album, artists: []);
        }

        if (artist != null && artist.id != 0) {
          final currentArtists = groupedTracks[track.id]!.artists;
          if (!currentArtists.any((a) => a.id == artist.id)) {
            currentArtists.add(artist);
          }
        }
      }

      return groupedTracks.values.toList();
    });
  }

  Future<int> addPlaylist(PlaylistsCompanion playlist) {
    return into(playlists).insert(playlist);
  }

  Future<int> deletePlaylist(int playlistId) {
    return (delete(playlists)..where((p) => p.id.equals(playlistId))).go();
  }

  Future<void> addTracksToPlaylist(int playlistId, List<int> trackIds) async {
    await batch((batch) {
      batch.insertAll(
        playlistTrack,
        trackIds.map((id) => PlaylistTrackCompanion.insert(playlistId: playlistId, trackId: id)).toList(),
        mode: InsertMode.insertOrIgnore,
      );
    });
  }

  Future<int> renamePlaylist(int playlistId, String newName) {
    return (update(playlists)..where((p) => p.id.equals(playlistId))).write(PlaylistsCompanion(name: Value(newName)));
  }

  // ============================================= Search Stuff =======================================================

  Stream<List<TrackWithArtists>> searchTracks(String queryStr) {
    // Add SQL wildcards to the start and end of the search string
    final searchTerm = '%$queryStr%';

    final query =
        select(tracks).join([
          leftOuterJoin(albums, albums.id.equalsExp(tracks.albumId)),
          leftOuterJoin(trackArtist, trackArtist.trackId.equalsExp(tracks.id)),
          leftOuterJoin(artists, artists.id.equalsExp(trackArtist.artistId)),
        ])..where(
          // Use the | operator for SQL OR to search across multiple tables
          (tracks.title.like(searchTerm) | albums.title.like(searchTerm) | artists.name.like(searchTerm)) &
              tracks.isMissing.equals(false),
        );

    // Order alphabetically by track title
    query.orderBy([OrderingTerm.asc(tracks.title.lower())]);

    return query.watch().map((rows) {
      final Map<int, TrackWithArtists> groupedTracks = {};

      for (final row in rows) {
        final track = row.readTable(tracks);
        final album = row.readTable(albums);
        final artist = row.readTableOrNull(artists);

        if (!groupedTracks.containsKey(track.id)) {
          groupedTracks[track.id] = TrackWithArtists(track: track, album: album, artists: []);
        }

        if (artist != null && artist.id != 0) {
          final currentArtists = groupedTracks[track.id]!.artists;
          if (!currentArtists.any((a) => a.id == artist.id)) {
            currentArtists.add(artist);
          }
        }
      }

      return groupedTracks.values.toList();
    });
  }

  // =================================== Queue Saving & Restoration ===================================================

  /// Saves the app current queue state to the database
  ///
  /// **Parameters:**
  /// * [originalQueue]: The list of tracks in original, unshuffled order.
  /// * [currentlyPlayedTrackPath]: The path of the currently playing track *inside the engine*.
  /// * [resumePositionMs]: The exact playback timestamp.
  /// * [playbackContextType]: E.g., 'album', 'playlist', 'all_tracks'.
  /// * [playbackContextId]: The specific ID (null for 'all_tracks').
  Future<void> saveQueue(
    List<TrackWithArtists> originalQueue,
    String? currentlyPlayedTrackPath,
    Duration resumePositionMs,
    String playbackContextType,
    int? playbackContextId,
  ) async {
    await transaction(() async {
      await delete(queueEntries).go();
      final companions = <QueueEntriesCompanion>[];

      for (var i = 0; i < originalQueue.length; i++) {
        // Check if this specific track's file path matches the one actively playing in the engine
        final isPlaying =
            currentlyPlayedTrackPath != null &&
            originalQueue[i].track.filePath.normalizePath().toLowerCase() ==
                currentlyPlayedTrackPath.normalizePath().toLowerCase();

        companions.add(
          QueueEntriesCompanion.insert(
            originalQueueIndex: Value(i),
            trackId: originalQueue[i].track.id,
            isCurrentlyPlaying: Value(isPlaying),
            resumePositionMs: Value(isPlaying ? resumePositionMs.inMilliseconds : 0),
            playbackContextType: playbackContextType,
            playbackContextId: Value(playbackContextId),
          ),
        );
      }

      await batch((batch) {
        batch.insertAll(queueEntries, companions);
      });
    });
  }

  /// Load last saved queue state from the database
  ///
  /// **Returns a Tuple containing:**
  /// * `List<TrackWithArtists>`: The list of tracks in original, unshuffled order.
  /// * `int`: The index of the track that was playing (relative to engine queue)
  /// * `Duration`: The exact timestamp to resume playback from
  /// * `String`: Context Type ('album', 'playlist')
  /// * `int?`: Context ID
  Future<(List<TrackWithArtists>, int, Duration, String, int?)> loadQueue() async {
    final entries = await (select(queueEntries)..orderBy([(t) => OrderingTerm.asc(t.originalQueueIndex)])).get();

    final originalQueue = <TrackWithArtists>[];
    int lastPlayedIndex = 0;
    Duration lastPosition = Duration.zero;
    String playbackContextType = '';
    int? playbackContextId;

    for (final entry in entries) {
      // Grab the context metadata (only needs to be set once)
      if (playbackContextType.isEmpty) {
        playbackContextType = entry.playbackContextType;
      }
      if (entry.playbackContextId != null && playbackContextId == null) {
        playbackContextId = entry.playbackContextId;
      }

      // Reconstruct the actual track data from the metadata tables
      final track = await getTrackWithArtistsById(entry.trackId);

      if (track != null && !track.track.isMissing) {
        originalQueue.add(track);
        if (entry.isCurrentlyPlaying) {
          lastPlayedIndex = originalQueue.length - 1;
          lastPosition = Duration(milliseconds: entry.resumePositionMs);
        }
      }
    }

    return (originalQueue, lastPlayedIndex, lastPosition, playbackContextType, playbackContextId);
  }

  /// Updates the resume timestamp of the currently active track.
  ///
  /// **Use Case:**
  /// Fired every 5 seconds by `PlayerService` during active playback. Only
  /// update the `resumePositionMs` for the row flagged as `isCurrentlyPlaying`
  /// to minimize database write times and prevent full table locks.
  Future<void> updateCurrentPosition(int positionInMs) async {
    await (update(queueEntries)..where((t) => t.isCurrentlyPlaying.equals(true))).write(
      QueueEntriesCompanion(resumePositionMs: Value(positionInMs)),
    );
  }
}

// =============================================== Class Stuf =========================================================

class LibraryStats {
  final int trackCount;
  final int albumCount;
  final int artistCount;
  final int playlistCount;
  final int genreCount;
  final int totalSizeBytes;
  final int totalPlaytimeMs;

  LibraryStats({
    required this.trackCount,
    required this.albumCount,
    required this.artistCount,
    required this.playlistCount,
    required this.genreCount,
    required this.totalSizeBytes,
    required this.totalPlaytimeMs,
  });
}

class TrackWithArtists {
  final Track track;
  final Album album;
  final List<Artist> artists;

  TrackWithArtists({required this.track, required this.album, required this.artists});

  // Helper to check whether this object is empty.
  // Has to be set because dart won't know it otherwise since it's a custom object.
  // TrackWithArtists is empty if it has no valid database ID (SQLite autoincrement start with 1) and filePath is empty
  bool get isEmpty => track.id == 0 || track.filePath.isEmpty;

  bool get isNotEmpty => !isEmpty;
}

class AlbumWithTracks {
  final Album album;
  final List<TrackWithArtists> tracks;
  final int tracksLengthMs;

  AlbumWithTracks({required this.album, required this.tracks, required this.tracksLengthMs});
}

class PlaylistWithDetails {
  final PlaylistData playlist;
  final int trackCount;
  final List<String> imageUrls;

  PlaylistWithDetails({required this.playlist, required this.trackCount, required this.imageUrls});
}

class PlaylistWithTracks {
  final PlaylistData playlist;
  final List<TrackWithArtists> tracks;

  PlaylistWithTracks({required this.playlist, required this.tracks});

  // Helper to check whether this object is empty.
  bool get isEmpty => tracks.isEmpty;
  bool get isNotEmpty => tracks.isNotEmpty;
}

//
// ================================================== Provider ========================================================
//

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(() => database.close());

  return database;
});

final libraryStatsProvider = StreamProvider<LibraryStats>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchLibraryStats();
});

final libraryStreamProvider = StreamProvider<List<TrackWithArtists>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchAllTracks();
});

final recentlyAddedTracksProvider = StreamProvider<List<TrackWithArtists>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchRecentlyAddedTracks(limitAmount: 12);
});

final albumsProvider = StreamProvider<List<Album>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchAlbums();
});

/// Watch an album and its tracks + total duration in ms
final albumWithTracksProvider = StreamProvider.family<AlbumWithTracks?, int>((ref, albumId) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchAlbumWithTracks(albumId);
});

final trackArtistsProvider = FutureProvider.family<List<Artist>, int>((ref, albumId) {
  final db = ref.watch(appDatabaseProvider);
  return db.getTrackArtists(albumId: albumId);
});

final randomAlbumsProvider = FutureProvider<List<Album>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.getRandomAlbums(limitAmount: 10);
});

final artistsProvider = StreamProvider<List<Artist>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchArtists();
});

final playlistsStreamProvider = StreamProvider<List<PlaylistWithDetails>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchAllPlaylists();
});

// Watches just the playlist metadata (name, id)
final singlePlaylistStreamProvider = StreamProvider.family<PlaylistData, int>((ref, playlistId) {
  final db = ref.watch(appDatabaseProvider);
  return (db.select(db.playlists)..where((p) => p.id.equals(playlistId))).watchSingle();
});

// Watches just the tracks for this playlist
final playlistTracksStreamProvider = StreamProvider.family<List<TrackWithArtists>, int>((ref, playlistId) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchPlaylistTracks(playlistId);
});

final playlistWithTracksProvider = Provider.family<AsyncValue<PlaylistWithTracks>, int>((ref, playlistId) {
  final playlistAsync = ref.watch(singlePlaylistStreamProvider(playlistId));
  final tracksAsync = ref.watch(playlistTracksStreamProvider(playlistId));

  // Bubble up any errors
  if (playlistAsync is AsyncError) {
    return AsyncError(playlistAsync.error!, playlistAsync.stackTrace!);
  }
  if (tracksAsync is AsyncError) {
    return AsyncError(tracksAsync.error!, tracksAsync.stackTrace!);
  }

  // Show loading state until BOTH streams have emitted their first value
  if (playlistAsync.isLoading || tracksAsync.isLoading || !playlistAsync.hasValue || !tracksAsync.hasValue) {
    return const AsyncLoading();
  }

  // Once both are ready, return the combined data
  return AsyncData(PlaylistWithTracks(playlist: playlistAsync.value!, tracks: tracksAsync.value!));
});

final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(SearchQueryNotifier.new);

class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void updateQuery(String query) {
    state = query;
  }

  void clear() {
    state = '';
  }
}

final searchResultsProvider = StreamProvider<List<TrackWithArtists>>((ref) {
  final query = ref.watch(searchQueryProvider);
  final db = ref.watch(appDatabaseProvider);

  if (query.trim().isEmpty) {
    return Stream.value([]);
  }

  return db.searchTracks(query);
});
