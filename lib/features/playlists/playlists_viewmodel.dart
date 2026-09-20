import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nordplayer/core/models/entities.dart';
import 'package:nordplayer/core/system/logger.dart';
import 'package:nordplayer/data/repositories/playlist_repository.dart';
import 'package:nordplayer/services/audio/player_service.dart';

/// ViewModel orchestrating playlist mutations and playback dispatch via [PlaylistRepository].
class PlaylistsViewModel(final Ref _ref) with LoggerMixin {
  PlaylistRepository get _repository => _ref.read(playlistRepositoryProvider);
  PlayerService get _playerService => _ref.read(playerServiceProvider);

  /// Creates a new playlist with [name], optionally adding [trackIds] atomically.
  Future<int> createPlaylist(String name, {List<int>? trackIds}) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError('Playlist name cannot be empty');
    }
    log.i('Creating playlist "$trimmedName" with ${trackIds?.length ?? 0} initial tracks');
    return await _repository.createPlaylist(trimmedName, trackIds: trackIds);
  }

  /// Renames an existing playlist with [playlistId] to [newName].
  Future<void> renamePlaylist(int playlistId, String newName) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Playlist name cannot be empty');
    }
    log.i('Renaming playlist $playlistId to "$trimmed"');
    await _repository.renamePlaylist(playlistId, trimmed);
  }

  /// Deletes the playlist identified by [playlistId].
  Future<void> deletePlaylist(int playlistId) async {
    log.i('Deleting playlist $playlistId');
    await _repository.deletePlaylist(playlistId);
  }

  /// Appends multiple tracks to a playlist, ignoring duplicates.
  Future<void> addTracksToPlaylist(int playlistId, List<int> trackIds) async {
    if (trackIds.isEmpty) return;
    log.i('Adding ${trackIds.length} tracks to playlist $playlistId');
    await _repository.addTracksToPlaylist(playlistId, trackIds);
  }

  /// Removes a track from a playlist.
  Future<void> removeTrackFromPlaylist(int playlistId, int trackId) async {
    log.i('Removing track $trackId from playlist $playlistId');
    await _repository.removeTrackFromPlaylist(playlistId, trackId);
  }

  /// Starts playback of the given playlist.
  void playPlaylist({
    required List<TrackWithArtists> tracks,
    required int playlistId,
    int initialIndex = 0,
    bool forceReload = false,
  }) {
    if (tracks.isEmpty) return;
    _playerService.setPlaylist(
      tracksToPlay: tracks,
      initialIndex: initialIndex,
      playbackContextType: 'playlist',
      playbackContextId: playlistId,
      forceReload: forceReload,
    );
  }

  /// Loads tracks for [playlistId] and starts playback. Returns false if the playlist is empty.
  Future<bool> playPlaylistById(int playlistId) async {
    final tracks = await _repository.getPlaylistTracks(playlistId);
    if (tracks.isEmpty) return false;

    _playerService.setPlaylist(
      playbackContextType: 'playlist',
      playbackContextId: playlistId,
      tracksToPlay: tracks,
      initialIndex: 0,
    );
    return true;
  }

  /// Loads tracks for [playlistId] and adds them to the active playback queue.
  /// Returns the number of tracks added (0 if playlist is empty).
  Future<int> addPlaylistToQueue(int playlistId) async {
    final tracks = await _repository.getPlaylistTracks(playlistId);
    if (tracks.isEmpty) return 0;

    final playbackContext = _ref.read(playbackContextProvider);
    _playerService.addToQueue(tracks, playbackContext?.type ?? '', playbackContext?.id);
    return tracks.length;
  }
}

/// Riverpod provider exposing [PlaylistsViewModel].
final playlistsViewModelProvider = Provider<PlaylistsViewModel>((ref) => PlaylistsViewModel(ref));
