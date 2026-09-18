import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nordplayer/core/database/app_database.dart';
import 'package:nordplayer/data/repositories/drift_artist_repository.dart';

/// Repository interface abstracting artist catalog queries.
abstract interface class ArtistRepository {
  /// Watches all artists associated with non-missing tracks, ordered alphabetically by name.
  Stream<List<Artist>> watchArtists();
}

/// Riverpod provider exposing the default [ArtistRepository] implementation.
final artistRepositoryProvider = Provider<ArtistRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return DriftArtistRepository(db);
});

final artistsProvider = StreamProvider<List<Artist>>((ref) {
  return ref.watch(artistRepositoryProvider).watchArtists();
});
