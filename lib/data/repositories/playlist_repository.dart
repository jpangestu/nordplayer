import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nordplayer/core/database/app_database.dart';
import 'package:nordplayer/data/repositories/drift_playlist_repository.dart';

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
