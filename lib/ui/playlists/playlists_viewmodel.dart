import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nordplayer/utils/logger.dart';
import 'package:nordplayer/data/repositories/config_repository.dart';
import 'package:nordplayer/data/repositories/playback_repository.dart';
import 'package:nordplayer/data/repositories/playlist_repository.dart';
import 'package:nordplayer/domain/models/models.dart';
import 'package:nordplayer/ui/playlists/playlists_ui_state.dart';

/// ViewModel orchestrating playlists overview state, mutations, and playback dispatch.
class PlaylistsViewModel extends Notifier<PlaylistsUiState> with LoggerMixin {
  PlaylistRepository get _repository => ref.read(playlistRepositoryProvider);
  PlaybackRepository get _playbackRepository => ref.read(playbackRepositoryProvider);

  @override
  PlaylistsUiState build() {
    final playlistRepo = ref.watch(playlistRepositoryProvider);
    final playbackRepo = ref.watch(playbackRepositoryProvider);
    final configRepo = ref.watch(configRepositoryProvider);

    final initialConfig = configRepo.currentConfig;
    final initialActiveId = playbackRepo.playbackContextType == 'playlist' ? playbackRepo.playbackContextId : null;
    final initialAlbumArt = playbackRepo.currentQueueCoverArt;

    final playlistsSub = playlistRepo.watchAllPlaylists().listen(
      (playlists) {
        state = state.copyWith(playlists: playlists, isLoading: false, errorMessage: () => null);
      },
      onError: (err) {
        state = state.copyWith(isLoading: false, errorMessage: () => err.toString());
      },
    );

    final playingSub = playbackRepo.watchIsPlaying().listen((playing) {
      if (state.isAudioPlaying != playing) {
        state = state.copyWith(isAudioPlaying: playing);
      }
    });

    final currentTrackSub = playbackRepo.watchCurrentTrack().listen((_) {
      final isPlaylistActive = playbackRepo.playbackContextType == 'playlist';
      final activeId = isPlaylistActive ? playbackRepo.playbackContextId : null;
      if (state.activePlaylistId != activeId) {
        state = state.copyWith(activePlaylistId: () => activeId);
      }
    });

    final configSub = configRepo.watchConfig().listen((config) {
      state = state.copyWith(
        isAdaptiveBg: config.adaptiveBg,
        adaptiveBgPanelBlur: config.adaptiveBgPanelBlur,
        adaptiveBgThemeOverlay: config.adaptiveBgThemeOverlay,
      );
    });

    final queueArtSub = playbackRepo.watchQueueCoverArt().listen((next) {
      if (!listEquals(state.activePlaylistAlbumArt, next)) {
        state = state.copyWith(activePlaylistAlbumArt: next);
      }
    });

    ref.onDispose(() {
      playlistsSub.cancel();
      playingSub.cancel();
      currentTrackSub.cancel();
      configSub.cancel();
      queueArtSub.cancel();
    });

    return PlaylistsUiState(
      isLoading: true,
      activePlaylistId: initialActiveId,
      isAudioPlaying: playbackRepo.isPlaying,
      activePlaylistAlbumArt: initialAlbumArt,
      isAdaptiveBg: initialConfig.adaptiveBg,
      adaptiveBgPanelBlur: initialConfig.adaptiveBgPanelBlur,
      adaptiveBgThemeOverlay: initialConfig.adaptiveBgThemeOverlay,
    );
  }

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
    _playbackRepository.setPlaylist(
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

    await _playbackRepository.setPlaylist(
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

    await _playbackRepository.addToQueue(tracks);
    return tracks.length;
  }
}

/// Riverpod provider exposing [PlaylistsViewModel].
final playlistsViewModelProvider = NotifierProvider<PlaylistsViewModel, PlaylistsUiState>(PlaylistsViewModel.new);
