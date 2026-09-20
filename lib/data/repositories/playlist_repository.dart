import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nordplayer/core/database/app_database.dart';

/// Repository interface abstracting playlist queries, mutations, and track associations.
abstract interface class PlaylistRepository {
  /// Watches all playlists with their aggregate track count and preview album art collage.
  Stream<List<PlaylistWithDetails>> watchAllPlaylists();

  /// Watches metadata for a single playlist by ID.
  Stream<PlaylistData> watchPlaylist(int playlistId);

  /// Retrieves the ordered list of tracks belonging to a playlist.
  Future<List<TrackWithArtists>> getPlaylistTracks(int playlistId);

  /// Watches the ordered list of tracks belonging to a playlist in real-time.
  Stream<List<TrackWithArtists>> watchPlaylistTracks(int playlistId);

  /// Creates a new playlist with the given [name], optionally adding initial [trackIds] atomically.
  Future<int> createPlaylist(String name, {List<int>? trackIds});

  /// Renames an existing playlist.
  Future<void> renamePlaylist(int playlistId, String newName);

  /// Deletes a playlist and its track associations.
  Future<void> deletePlaylist(int playlistId);

  /// Appends tracks to a playlist, ignoring duplicates.
  Future<void> addTracksToPlaylist(int playlistId, List<int> trackIds);

  /// Removes a specific track from a playlist.
  Future<void> removeTrackFromPlaylist(int playlistId, int trackId);
}

/// Drift/SQLite implementation of [PlaylistRepository].
class const DriftPlaylistRepository(final AppDatabase _db) implements PlaylistRepository {

  @override
  Stream<List<PlaylistWithDetails>> watchAllPlaylists() {
    final trackCount = _db.playlistTrack.trackId.count();
    final coverPaths = _db.albums.albumArtPath.groupConcat(separator: '||');

    final query = _db.select(_db.playlists).join([
      leftOuterJoin(
        _db.playlistTrack,
        _db.playlistTrack.playlistId.equalsExp(_db.playlists.id),
      ),
      leftOuterJoin(
        _db.tracks,
        _db.tracks.id.equalsExp(_db.playlistTrack.trackId) & _db.tracks.isMissing.equals(false),
      ),
      leftOuterJoin(_db.albums, _db.albums.id.equalsExp(_db.tracks.albumId)),
    ])
      ..addColumns([trackCount, coverPaths])
      ..groupBy([_db.playlists.id])
      ..orderBy([OrderingTerm.asc(_db.playlists.name.lower())]);

    return query.watch().map((rows) {
      return rows.map((row) {
        final pathsString = row.read(coverPaths);
        List<String> covers = [];
        if (pathsString != null && pathsString.isNotEmpty) {
          covers = pathsString
              .split('||')
              .where((path) => path.trim().isNotEmpty)
              .toSet()
              .take(5)
              .toList();
        }

        return PlaylistWithDetails(
          playlist: row.readTable(_db.playlists),
          trackCount: row.read(trackCount) ?? 0,
          imageUrls: covers,
        );
      }).toList();
    });
  }

  @override
  Stream<PlaylistData> watchPlaylist(int playlistId) {
    return (_db.select(_db.playlists)..where((p) => p.id.equals(playlistId))).watchSingle();
  }

  @override
  Future<List<TrackWithArtists>> getPlaylistTracks(int playlistId) async {
    final query = _db.select(_db.tracks).join([
      innerJoin(_db.playlistTrack, _db.playlistTrack.trackId.equalsExp(_db.tracks.id)),
      leftOuterJoin(_db.albums, _db.albums.id.equalsExp(_db.tracks.albumId)),
      leftOuterJoin(_db.trackArtist, _db.trackArtist.trackId.equalsExp(_db.tracks.id)),
      leftOuterJoin(_db.artists, _db.artists.id.equalsExp(_db.trackArtist.artistId)),
    ])
      ..where(_db.playlistTrack.playlistId.equals(playlistId) & _db.tracks.isMissing.equals(false))
      ..orderBy([OrderingTerm.asc(_db.playlistTrack.dateAdded)]);

    final rows = await query.get();
    return _groupPlaylistTrackRows(rows);
  }

  @override
  Stream<List<TrackWithArtists>> watchPlaylistTracks(int playlistId) {
    final query = _db.select(_db.tracks).join([
      innerJoin(_db.playlistTrack, _db.playlistTrack.trackId.equalsExp(_db.tracks.id)),
      leftOuterJoin(_db.albums, _db.albums.id.equalsExp(_db.tracks.albumId)),
      leftOuterJoin(_db.trackArtist, _db.trackArtist.trackId.equalsExp(_db.tracks.id)),
      leftOuterJoin(_db.artists, _db.artists.id.equalsExp(_db.trackArtist.artistId)),
    ])
      ..where(_db.playlistTrack.playlistId.equals(playlistId) & _db.tracks.isMissing.equals(false))
      ..orderBy([OrderingTerm.asc(_db.playlistTrack.dateAdded)]);

    return query.watch().map(_groupPlaylistTrackRows);
  }

  @override
  Future<int> createPlaylist(String name, {List<int>? trackIds}) {
    return _db.transaction(() async {
      final playlistId = await _db.into(_db.playlists).insert(PlaylistsCompanion.insert(name: name));

      if (trackIds != null && trackIds.isNotEmpty) {
        await _db.batch((batch) {
          batch.insertAll(
            _db.playlistTrack,
            trackIds.map((id) => PlaylistTrackCompanion.insert(playlistId: playlistId, trackId: id)).toList(),
            mode: InsertMode.insertOrIgnore,
          );
        });
      }

      return playlistId;
    });
  }

  @override
  Future<void> renamePlaylist(int playlistId, String newName) async {
    await (_db.update(_db.playlists)..where((p) => p.id.equals(playlistId))).write(
      PlaylistsCompanion(name: Value(newName)),
    );
  }

  @override
  Future<void> deletePlaylist(int playlistId) async {
    await (_db.delete(_db.playlists)..where((p) => p.id.equals(playlistId))).go();
  }

  @override
  Future<void> addTracksToPlaylist(int playlistId, List<int> trackIds) async {
    if (trackIds.isEmpty) return;
    await _db.batch((batch) {
      batch.insertAll(
        _db.playlistTrack,
        trackIds.map((id) => PlaylistTrackCompanion.insert(playlistId: playlistId, trackId: id)).toList(),
        mode: InsertMode.insertOrIgnore,
      );
    });
  }

  @override
  Future<void> removeTrackFromPlaylist(int playlistId, int trackId) async {
    await (_db.delete(_db.playlistTrack)
          ..where((pt) => pt.playlistId.equals(playlistId) & pt.trackId.equals(trackId)))
        .go();
  }

  /// Groups flattened playlist track join rows into composite [TrackWithArtists] domain entities.
  List<TrackWithArtists> _groupPlaylistTrackRows(List<TypedResult> rows) {
    final Map<int, TrackWithArtists> groupedTracks = {};

    for (final row in rows) {
      var track = row.readTable(_db.tracks);
      final pt = row.readTable(_db.playlistTrack);
      track = track.copyWith(dateAdded: pt.dateAdded);

      final album = row.readTable(_db.albums);
      final artist = row.readTableOrNull(_db.artists);

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
}

/// Riverpod provider exposing the default [PlaylistRepository] implementation.
final playlistRepositoryProvider = Provider<PlaylistRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return DriftPlaylistRepository(db);
});

final playlistsStreamProvider = StreamProvider<List<PlaylistWithDetails>>((ref) {
  return ref.watch(playlistRepositoryProvider).watchAllPlaylists();
});

final singlePlaylistStreamProvider = StreamProvider.autoDispose.family<PlaylistData, int>((ref, playlistId) {
  return ref.watch(playlistRepositoryProvider).watchPlaylist(playlistId);
});

final playlistTracksStreamProvider = StreamProvider.autoDispose.family<List<TrackWithArtists>, int>((ref, playlistId) {
  return ref.watch(playlistRepositoryProvider).watchPlaylistTracks(playlistId);
});

final playlistWithTracksProvider = Provider.autoDispose.family<AsyncValue<PlaylistWithTracks>, int>((ref, playlistId) {
  final playlistAsync = ref.watch(singlePlaylistStreamProvider(playlistId));
  final tracksAsync = ref.watch(playlistTracksStreamProvider(playlistId));

  return switch ((playlistAsync, tracksAsync)) {
    (AsyncError(:final error, :final stackTrace), _) => AsyncError(error, stackTrace),
    (_, AsyncError(:final error, :final stackTrace)) => AsyncError(error, stackTrace),
    (AsyncData(value: final playlist), AsyncData(value: final tracks)) =>
      AsyncData(PlaylistWithTracks(playlist: playlist, tracks: tracks)),
    _ => const AsyncLoading(),
  };
});
