import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nordplayer/data/database/app_database.dart' hide Album, Artist, Track;
import 'package:nordplayer/data/database/db_mappers.dart';
import 'package:nordplayer/domain/models/album.dart';
import 'package:nordplayer/domain/models/artist.dart';
import 'package:nordplayer/domain/models/composite_models.dart';

/// Repository interface abstracting album queries and track associations.
abstract interface class AlbumRepository {
  /// Watches all albums that contain at least one non-missing track, ordered by title.
  Stream<List<Album>> watchAlbums();

  /// Watches an album and all its associated tracks, ordered by track number.
  Stream<AlbumWithTracks?> watchAlbumWithTracks(int albumId);

  /// Retrieves distinct artists featured across tracks within a specific album.
  Future<List<Artist>> getTrackArtists({required int albumId});

  /// Fetches a randomized sample of albums.
  Future<List<Album>> getRandomAlbums({int limitAmount = 10});
}

/// Drift/SQLite implementation of [AlbumRepository].
class const DriftAlbumRepository(final AppDatabase _db) implements AlbumRepository {
  @override
  Stream<List<Album>> watchAlbums() {
    final query =
        _db.select(_db.albums).join([
            innerJoin(_db.tracks, _db.tracks.albumId.equalsExp(_db.albums.id) & _db.tracks.isMissing.equals(false)),
          ])
          ..groupBy([_db.albums.id])
          ..orderBy([OrderingTerm.asc(_db.albums.title.lower())]);

    return query.watch().map((rows) {
      return rows.map((row) => row.readTable(_db.albums).toDomain()).toList();
    });
  }

  @override
  Stream<AlbumWithTracks?> watchAlbumWithTracks(int albumId) {
    final query = _db.select(_db.albums).join([
      leftOuterJoin(_db.tracks, _db.tracks.albumId.equalsExp(_db.albums.id) & _db.tracks.isMissing.equals(false)),
      leftOuterJoin(_db.trackArtist, _db.trackArtist.trackId.equalsExp(_db.tracks.id)),
      leftOuterJoin(_db.artists, _db.artists.id.equalsExp(_db.trackArtist.artistId)),
    ])..where(_db.albums.id.equals(albumId));

    query.orderBy([OrderingTerm.asc(_db.tracks.trackNumber)]);

    return query.watch().map((rows) {
      if (rows.isEmpty) return null;

      final album = rows.first.readTable(_db.albums).toDomain();
      final Map<int, TrackWithArtists> groupedTracks = {};
      int tracksLengthMs = 0;

      for (final row in rows) {
        final track = row.readTableOrNull(_db.tracks);

        if (track != null) {
          if (!groupedTracks.containsKey(track.id)) {
            groupedTracks[track.id] = TrackWithArtists(track: track.toDomain(), album: album, artists: []);
            tracksLengthMs += track.durationMs;
          }

          final artist = row.readTableOrNull(_db.artists);
          if (artist != null && artist.id != 0) {
            final currentArtists = groupedTracks[track.id]!.artists;
            if (!currentArtists.any((a) => a.id == artist.id)) {
              currentArtists.add(artist.toDomain());
            }
          }
        }
      }

      return AlbumWithTracks(album: album, tracks: groupedTracks.values.toList(), tracksLengthMs: tracksLengthMs);
    });
  }

  @override
  Future<List<Artist>> getTrackArtists({required int albumId}) {
    final query =
        _db.select(_db.artists, distinct: true).join([
            innerJoin(_db.trackArtist, _db.trackArtist.artistId.equalsExp(_db.artists.id)),
            innerJoin(_db.tracks, _db.tracks.id.equalsExp(_db.trackArtist.trackId)),
          ])
          ..where(_db.tracks.albumId.equals(albumId) & _db.tracks.isMissing.equals(false))
          ..groupBy([_db.artists.id])
          ..orderBy([OrderingTerm.asc(_db.artists.name.lower())]);

    return query.get().then((rows) => rows.map((row) => row.readTable(_db.artists).toDomain()).toList());
  }

  @override
  Future<List<Album>> getRandomAlbums({int limitAmount = 10}) {
    final query =
        _db.select(_db.albums).join([
            innerJoin(_db.tracks, _db.tracks.albumId.equalsExp(_db.albums.id) & _db.tracks.isMissing.equals(false)),
          ])
          ..groupBy([_db.albums.id])
          ..orderBy([OrderingTerm(expression: const CustomExpression('RANDOM()'))])
          ..limit(limitAmount);

    return query.get().then((rows) => rows.map((row) => row.readTable(_db.albums).toDomain()).toList());
  }
}

/// Riverpod provider exposing the default [AlbumRepository] implementation.
final albumRepositoryProvider = Provider<AlbumRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return DriftAlbumRepository(db);
});

final albumsProvider = StreamProvider<List<Album>>((ref) {
  return ref.watch(albumRepositoryProvider).watchAlbums();
});

final albumWithTracksProvider = StreamProvider.autoDispose.family<AlbumWithTracks?, int>((ref, albumId) {
  return ref.watch(albumRepositoryProvider).watchAlbumWithTracks(albumId);
});

final trackArtistsProvider = FutureProvider.autoDispose.family<List<Artist>, int>((ref, albumId) {
  return ref.watch(albumRepositoryProvider).getTrackArtists(albumId: albumId);
});

final randomAlbumsProvider = FutureProvider<List<Album>>((ref) {
  return ref.watch(albumRepositoryProvider).getRandomAlbums(limitAmount: 10);
});
