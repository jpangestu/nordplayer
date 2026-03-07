import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nordplayer/database/schema.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'app_database.g.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase(openConection());
  ref.onDispose(() => database.close());

  return database;
});

final libraryStreamProvider = StreamProvider<List<TrackWithArtists>>((ref) {
  final db = ref.watch(appDatabaseProvider);

  final query = db.select(db.tracks).join([
    leftOuterJoin(db.albums, db.albums.id.equalsExp(db.tracks.albumId)),
    leftOuterJoin(
      db.trackArtist,
      db.trackArtist.trackId.equalsExp(db.tracks.id),
    ),
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
        groupedTracks[track.id] = TrackWithArtists(
          track: track,
          album: album,
          artists: [],
        );
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

final playlistsStreamProvider = StreamProvider<List<PlaylistWithDetails>>((
  ref,
) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchAllPlaylists();
});

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

@DriftDatabase(
  tables: [Tracks, Artists, Albums, Playlists, TrackArtist, PlaylistTrack],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;

  // -- PLAYLISTS TABLE CRUD --
  Stream<List<PlaylistWithDetails>> watchAllPlaylists() {
    final trackCount = playlistTrack.trackId.count();

    // Concat all album art paths into a single string separated by '||'
    final coverPaths = albums.albumArtPath.groupConcat(separator: '||');

    final query =
        select(playlists).join([
            // 1. Join Junction Table
            leftOuterJoin(
              playlistTrack,
              playlistTrack.playlistId.equalsExp(playlists.id),
            ),
            // 2. Join Tracks to get the track details
            leftOuterJoin(tracks, tracks.id.equalsExp(playlistTrack.trackId)),
            // 3. Join Albums to get the actual cover art path
            leftOuterJoin(albums, albums.id.equalsExp(tracks.albumId)),
          ])
          ..addColumns([
            trackCount,
            coverPaths,
          ]) // Ask SQL for the concated string
          ..groupBy([playlists.id])
          ..orderBy([
            OrderingTerm(expression: playlists.name, mode: OrderingMode.asc),
          ]);

    return query.watch().map((rows) {
      return rows.map((row) {
        final pathsString = row.read(coverPaths);

        List<String> covers = [];
        if (pathsString != null && pathsString.isNotEmpty) {
          covers = pathsString
              .split('||')
              .where((path) => path.trim().isNotEmpty)
              .toSet() // Use a Set to prevent duplicate covers
              .take(5) // Only take as many as your AlbumArtStack needs
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
        groupedTracks[track.id] = TrackWithArtists(
          track: track,
          album: album,
          artists: [],
        );
      }

      final currentArtists = groupedTracks[track.id]!.artists;
      if (!currentArtists.any((a) => a.id == artist.id)) {
        currentArtists.add(artist);
      }
    }

    return groupedTracks.values.toList();
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
        trackIds
            .map(
              (id) => PlaylistTrackCompanion.insert(
                playlistId: playlistId,
                trackId: id,
              ),
            )
            .toList(),
        mode: InsertMode.insertOrIgnore,
      );
    });
  }

  Future<int> renamePlaylist(int playlistId, String newName) {
    return (update(playlists)..where((p) => p.id.equals(playlistId))).write(
      PlaylistsCompanion(name: Value(newName)),
    );
  }
}

class TrackWithArtists {
  final Track track;
  final Album album;
  final List<Artist> artists;

  TrackWithArtists({
    required this.track,
    required this.album,
    required this.artists,
  });
}

class PlaylistWithDetails {
  final PlaylistData playlist;
  final int trackCount;
  final List<String> imageUrls;

  PlaylistWithDetails({
    required this.playlist,
    required this.trackCount,
    required this.imageUrls,
  });
}
