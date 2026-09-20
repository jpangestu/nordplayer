import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nordplayer/core/database/app_database.dart';

/// Repository interface abstracting artist catalog queries.
abstract interface class ArtistRepository {
  /// Watches all artists associated with non-missing tracks, ordered alphabetically by name.
  Stream<List<Artist>> watchArtists();
}

/// Drift/SQLite implementation of [ArtistRepository].
class const DriftArtistRepository(final AppDatabase _db) implements ArtistRepository {

  @override
  Stream<List<Artist>> watchArtists() {
    final query = _db.select(_db.artists).join([
      innerJoin(_db.trackArtist, _db.trackArtist.artistId.equalsExp(_db.artists.id)),
      innerJoin(
        _db.tracks,
        _db.tracks.id.equalsExp(_db.trackArtist.trackId) & _db.tracks.isMissing.equals(false),
      ),
    ])
      ..groupBy([_db.artists.id])
      ..orderBy([OrderingTerm.asc(_db.artists.name.lower())]);

    return query.watch().map((rows) {
      return rows.map((row) => row.readTable(_db.artists)).toList();
    });
  }
}

/// Riverpod provider exposing the default [ArtistRepository] implementation.
final artistRepositoryProvider = Provider<ArtistRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return DriftArtistRepository(db);
});

final artistsProvider = StreamProvider<List<Artist>>((ref) {
  return ref.watch(artistRepositoryProvider).watchArtists();
});
