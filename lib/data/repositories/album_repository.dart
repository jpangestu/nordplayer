import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nordplayer/core/database/app_database.dart';
import 'package:nordplayer/data/repositories/drift_album_repository.dart';

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
