import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nordplayer/database/schema.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

LazyDatabase openConection() {
  return LazyDatabase(() async {
    final dbPath = await getApplicationSupportDirectory();
    final file = File(p.join(dbPath.path, 'database.sqlite'));

    return NativeDatabase.createInBackground(
      file,
      setup: (database) {
        // Enable WAL (Write-Ahead Logging) Mode (Higher concurrency, less locking)
        database.execute('PRAGMA journal_mode=WAL;');
        // Synchronous Normal (Faster writes, slightly less safe on power loss)
        database.execute('PRAGMA synchronous=NORMAL;');
      },
    );
  });
}

@DriftDatabase(tables: [Tracks, Artists, Albums, Playlists, TrackArtist, PlaylistTrack, QueueEntries])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;

  // =========================================== Library Stats =======================================================

  Stream<LibraryStats> watchLibraryStats() {
    // We use a single raw SQL query to get all counts and sums at once for maximum performance.
    const query = '''
      SELECT
        (SELECT COUNT(*) FROM tracks) AS trackCount,
        (SELECT COUNT(*) FROM albums) AS albumCount,
        (SELECT COUNT(*) FROM artists) AS artistCount,
        (SELECT COUNT(*) FROM playlists) AS playlistCount,
        (SELECT COUNT(DISTINCT genre) FROM tracks WHERE genre IS NOT NULL AND genre != '') AS genreCount,
        (SELECT SUM(file_size) FROM tracks) AS totalSize,
        (SELECT SUM(duration_ms) FROM tracks) AS totalDuration
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
        .map((row) => row.readTable(artists))
        .where((a) => a.id != 0) // filter null-joined rows
        .fold<List<Artist>>([], (list, a) {
          if (!list.any((x) => x.id == a.id)) list.add(a);
          return list;
        });

    return TrackWithArtists(track: track, album: album, artists: artistList);
  }

  Stream<List<TrackWithArtists>> watchRecentlyAddedTracks({int limitAmount = 10}) {
    final query = select(tracks).join([
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
        final artist = row.readTable(artists);

        if (!groupedTracks.containsKey(track.id)) {
          groupedTracks[track.id] = TrackWithArtists(track: track, album: album, artists: []);
        }

        final currentArtists = groupedTracks[track.id]!.artists;
        if (!currentArtists.any((a) => a.id == artist.id)) {
          currentArtists.add(artist);
        }
      }

      // Enforce the strict limit after grouping the tracks
      return groupedTracks.values.take(limitAmount).toList();
    });
  }

  // ============================================= Albums Stuff =======================================================

  /// Fetches a list of random albums.
  /// Using a Future instead of a Stream prevents the UI from re-shuffling
  /// every time the database receives an update.
  Future<List<Album>> getRandomAlbums({int limitAmount = 10}) {
    final query = select(albums)
      // Use SQLite's native RANDOM() function to sort the rows arbitrarily
      ..orderBy([(a) => OrderingTerm(expression: const CustomExpression('RANDOM()'))])
      ..limit(limitAmount);

    return query.get();
  }

  // =========================================== Playlist Stuff =======================================================

  // -- PLAYLISTS TABLE CRUD --
  Stream<List<PlaylistWithDetails>> watchAllPlaylists() {
    final trackCount = playlistTrack.trackId.count();

    // Concat all album art paths into a single string separated by '||'
    final coverPaths = albums.albumArtPath.groupConcat(separator: '||');

    final query =
        select(playlists).join([
            leftOuterJoin(playlistTrack, playlistTrack.playlistId.equalsExp(playlists.id)),
            leftOuterJoin(tracks, tracks.id.equalsExp(playlistTrack.trackId)),
            leftOuterJoin(albums, albums.id.equalsExp(tracks.albumId)),
          ])
          ..addColumns([trackCount, coverPaths]) // Ask SQL for the concated string
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
    ])..where(playlistTrack.playlistId.equals(playlistId));

    final rows = await query.get();

    // Use a map to group artists back into their respective tracks
    final Map<int, TrackWithArtists> groupedTracks = {};

    for (final row in rows) {
      final track = row.readTable(tracks);
      final album = row.readTable(albums);
      final artist = row.readTable(artists);

      if (!groupedTracks.containsKey(track.id)) {
        groupedTracks[track.id] = TrackWithArtists(track: track, album: album, artists: []);
      }

      final currentArtists = groupedTracks[track.id]!.artists;
      if (!currentArtists.any((a) => a.id == artist.id)) {
        currentArtists.add(artist);
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
    ])..where(playlistTrack.playlistId.equals(playlistId));

    return query.watch().map((rows) {
      final Map<int, TrackWithArtists> groupedTracks = {};

      for (final row in rows) {
        final track = row.readTable(tracks);
        final album = row.readTable(albums);
        final artist = row.readTable(artists);

        if (!groupedTracks.containsKey(track.id)) {
          groupedTracks[track.id] = TrackWithArtists(track: track, album: album, artists: []);
        }

        final currentArtists = groupedTracks[track.id]!.artists;
        if (!currentArtists.any((a) => a.id == artist.id)) {
          currentArtists.add(artist);
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
        final isPlaying = originalQueue[i].track.filePath == currentlyPlayedTrackPath;

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

      if (track != null) {
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

// ================================================= Class ============================================================

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

  // Helper to format the size (e.g., "24.1 GB")
  String get formattedSize {
    if (totalSizeBytes == 0) return '0 GB';
    final gb = totalSizeBytes / (1024 * 1024 * 1024);
    if (gb >= 1) return '${gb.toStringAsFixed(1)} GB';

    // Fallback to MB if the library is small
    final mb = totalSizeBytes / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }

  // Helper to format playtime (e.g., "8.4 Days" or "12.2 Hours")
  String get formattedPlaytime {
    if (totalPlaytimeMs == 0) return '0 Mins';
    final days = totalPlaytimeMs / (1000 * 60 * 60 * 24);
    if (days >= 1) return '${days.toStringAsFixed(1)} Days';

    final hours = totalPlaytimeMs / (1000 * 60 * 60);
    return '${hours.toStringAsFixed(1)} Hours';
  }
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
}

//
// ================================================== Provider ========================================================
//

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase(openConection());
  ref.onDispose(() => database.close());

  return database;
});

final libraryStatsProvider = StreamProvider<LibraryStats>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchLibraryStats();
});

final libraryStreamProvider = StreamProvider<List<TrackWithArtists>>((ref) {
  final db = ref.watch(appDatabaseProvider);

  final query = db.select(db.tracks).join([
    leftOuterJoin(db.albums, db.albums.id.equalsExp(db.tracks.albumId)),
    leftOuterJoin(db.trackArtist, db.trackArtist.trackId.equalsExp(db.tracks.id)),
    leftOuterJoin(db.artists, db.artists.id.equalsExp(db.trackArtist.artistId)),
  ]);

  // Sort title ascending
  query.orderBy([OrderingTerm.asc(db.tracks.title.lower())]);

  // Return the stream and map the raw rows into grouped objects
  return query.watch().map((rows) {
    final Map<int, TrackWithArtists> groupedTracks = {};

    for (final row in rows) {
      final track = row.readTable(db.tracks);
      final album = row.readTable(db.albums);
      final artist = row.readTable(db.artists);

      // If track is new, create the entry
      if (!groupedTracks.containsKey(track.id)) {
        groupedTracks[track.id] = TrackWithArtists(track: track, album: album, artists: []);
      }

      // Add the artist from this row to the artists list
      // distinct check to avoid duplicates if query logic overlaps
      final currentArtists = groupedTracks[track.id]!.artists;
      if (!currentArtists.any((a) => a.id == artist.id)) {
        currentArtists.add(artist);
      }
    }

    return groupedTracks.values.toList();
  });
});

final recentlyAddedTracksProvider = StreamProvider<List<TrackWithArtists>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchRecentlyAddedTracks(limitAmount: 12);
});

final random6TracksProvider = Provider<List<TrackWithArtists>>((ref) {
  final libraryAsync = ref.watch(libraryStreamProvider);

  return libraryAsync.maybeWhen(
    data: (allTracks) {
      if (allTracks.isEmpty) return [];

      // Create a copy of the list, shuffle it, and take the first 5
      final shuffledTracks = List<TrackWithArtists>.from(allTracks)..shuffle();
      return shuffledTracks.take(6).toList();
    },
    orElse: () => [],
  );
});

final randomAlbumsProvider = FutureProvider<List<Album>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.getRandomAlbums(limitAmount: 10);
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
