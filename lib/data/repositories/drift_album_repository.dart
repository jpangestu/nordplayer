import 'package:drift/drift.dart';
import 'package:nordplayer/core/database/app_database.dart';
import 'package:nordplayer/data/repositories/album_repository.dart';

/// Drift/SQLite implementation of [AlbumRepository].
class const DriftAlbumRepository(final AppDatabase _db) implements AlbumRepository {

  @override
  Stream<List<Album>> watchAlbums() {
    final query = _db.select(_db.albums).join([
      innerJoin(
        _db.tracks,
        _db.tracks.albumId.equalsExp(_db.albums.id) & _db.tracks.isMissing.equals(false),
      ),
    ])
      ..groupBy([_db.albums.id])
      ..orderBy([OrderingTerm.asc(_db.albums.title.lower())]);

    return query.watch().map((rows) {
      return rows.map((row) => row.readTable(_db.albums)).toList();
    });
  }

  @override
  Stream<AlbumWithTracks?> watchAlbumWithTracks(int albumId) {
    final query = _db.select(_db.albums).join([
      leftOuterJoin(
        _db.tracks,
        _db.tracks.albumId.equalsExp(_db.albums.id) & _db.tracks.isMissing.equals(false),
      ),
      leftOuterJoin(_db.trackArtist, _db.trackArtist.trackId.equalsExp(_db.tracks.id)),
      leftOuterJoin(_db.artists, _db.artists.id.equalsExp(_db.trackArtist.artistId)),
    ])..where(_db.albums.id.equals(albumId));

    query.orderBy([OrderingTerm.asc(_db.tracks.trackNumber)]);

    return query.watch().map((rows) {
      if (rows.isEmpty) return null;

      final album = rows.first.readTable(_db.albums);
      final Map<int, TrackWithArtists> groupedTracks = {};
      int tracksLengthMs = 0;

      for (final row in rows) {
        final track = row.readTableOrNull(_db.tracks);

        if (track != null) {
          if (!groupedTracks.containsKey(track.id)) {
            groupedTracks[track.id] = TrackWithArtists(track: track, album: album, artists: []);
            tracksLengthMs += track.durationMs;
          }

          final artist = row.readTableOrNull(_db.artists);
          if (artist != null && artist.id != 0) {
            final currentArtists = groupedTracks[track.id]!.artists;
            if (!currentArtists.any((a) => a.id == artist.id)) {
              currentArtists.add(artist);
            }
          }
        }
      }

      return AlbumWithTracks(
        album: album,
        tracks: groupedTracks.values.toList(),
        tracksLengthMs: tracksLengthMs,
      );
    });
  }

  @override
  Future<List<Artist>> getTrackArtists({required int albumId}) {
    final query = _db.select(_db.artists, distinct: true).join([
      innerJoin(_db.trackArtist, _db.trackArtist.artistId.equalsExp(_db.artists.id)),
      innerJoin(_db.tracks, _db.tracks.id.equalsExp(_db.trackArtist.trackId)),
    ])
      ..where(_db.tracks.albumId.equals(albumId) & _db.tracks.isMissing.equals(false))
      ..groupBy([_db.artists.id])
      ..orderBy([OrderingTerm.asc(_db.artists.name.lower())]);

    return query.get().then((rows) => rows.map((row) => row.readTable(_db.artists)).toList());
  }

  @override
  Future<List<Album>> getRandomAlbums({int limitAmount = 10}) {
    final query = _db.select(_db.albums).join([
      innerJoin(
        _db.tracks,
        _db.tracks.albumId.equalsExp(_db.albums.id) & _db.tracks.isMissing.equals(false),
      ),
    ])
      ..groupBy([_db.albums.id])
      ..orderBy([OrderingTerm(expression: const CustomExpression('RANDOM()'))])
      ..limit(limitAmount);

    return query.get().then((rows) => rows.map((row) => row.readTable(_db.albums)).toList());
  }
}
