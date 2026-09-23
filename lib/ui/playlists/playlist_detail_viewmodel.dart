import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nordplayer/ui/shared/ui/selection_state.dart';
import 'package:nordplayer/ui/shared/ui/table_column_config.dart';
import 'package:nordplayer/utils/logger.dart';
import 'package:nordplayer/data/repositories/config_repository.dart';
import 'package:nordplayer/data/repositories/playback_repository.dart';
import 'package:nordplayer/data/repositories/playlist_repository.dart';
import 'package:nordplayer/domain/models/models.dart';
import 'package:nordplayer/ui/playlists/playlist_detail_ui_state.dart';

/// ViewModel orchestrating Playlist Detail state, selection, column configs, and playback.
class PlaylistDetailViewModel(final int playlistId) extends Notifier<PlaylistDetailUiState> with LoggerMixin {
  PlaybackRepository get _playbackRepository => ref.read(playbackRepositoryProvider);

  @override
  PlaylistDetailUiState build() {
    final playlistRepo = ref.watch(playlistRepositoryProvider);
    final playbackRepo = ref.watch(playbackRepositoryProvider);
    final configRepo = ref.watch(configRepositoryProvider);

    final initialConfig = configRepo.currentConfig;
    final initialColumns = _initialColumns;
    final initialSelection = ref.read(selectedTracksIndexProvider('playlist'));
    final currentTrack = playbackRepo.currentTrack;
    final isPlaying = playbackRepo.isPlaying;

    final playlistSub = playlistRepo
        .watchPlaylist(playlistId)
        .listen(
          (playlist) {
            state = state.copyWith(playlist: () => playlist, errorMessage: () => null);
          },
          onError: (err) {
            state = state.copyWith(errorMessage: () => err.toString());
          },
        );

    final tracksSub = playlistRepo
        .watchPlaylistTracks(playlistId)
        .listen(
          (tracks) {
            final covers = _calculateWallCovers(tracks);
            state = state.copyWith(tracks: tracks, albumArtCovers: covers, isLoading: false, errorMessage: () => null);
          },
          onError: (err) {
            state = state.copyWith(isLoading: false, errorMessage: () => err.toString());
          },
        );

    final trackSub = playbackRepo.watchCurrentTrack().listen((track) {
      final activePath = track?.track.filePath;
      if (state.activeTrackPath != activePath) {
        state = state.copyWith(activeTrackPath: () => activePath);
      }
    });

    final playingSub = playbackRepo.watchIsPlaying().listen((playing) {
      if (state.isAudioPlaying != playing) {
        state = state.copyWith(isAudioPlaying: playing);
      }
    });

    final configSub = configRepo.watchConfig().listen((config) {
      state = state.copyWith(
        isAdaptiveBg: config.adaptiveBg,
        adaptiveBgPanelBlur: config.adaptiveBgPanelBlur,
        adaptiveBgThemeOverlay: config.adaptiveBgThemeOverlay,
      );
    });

    ref.listen(selectedTracksIndexProvider('playlist'), (_, next) {
      if (!setEquals(state.selectedIndices, next)) {
        state = state.copyWith(selectedIndices: next);
      }
    });

    ref.onDispose(() {
      playlistSub.cancel();
      tracksSub.cancel();
      trackSub.cancel();
      playingSub.cancel();
      configSub.cancel();
    });

    return PlaylistDetailUiState(
      selectedIndices: initialSelection,
      columns: initialColumns,
      activeTrackPath: currentTrack?.track.filePath,
      isAudioPlaying: isPlaying,
      isLoading: true,
      isAdaptiveBg: initialConfig.adaptiveBg,
      adaptiveBgPanelBlur: initialConfig.adaptiveBgPanelBlur,
      adaptiveBgThemeOverlay: initialConfig.adaptiveBgThemeOverlay,
    );
  }

  /// Selects track at [index] supporting multi-select modifier keys.
  void selectTrack(int index, {required bool isCtrlSelect, required bool isShiftSelect}) {
    ref
        .read(selectedTracksIndexProvider('playlist').notifier)
        .selectTrack(index, isCtrlSelect: isCtrlSelect, isShiftSelect: isShiftSelect);
  }

  /// Selects single track at [index], clearing previous selections.
  void selectSingle(int index) {
    selectTrack(index, isCtrlSelect: false, isShiftSelect: false);
  }

  /// Selects all tracks in this playlist.
  void selectAll() {
    ref.read(selectedTracksIndexProvider('playlist').notifier).selectAll(state.tracks.length);
  }

  /// Clears active selection.
  void clearSelection() {
    ref.read(selectedTracksIndexProvider('playlist').notifier).clear();
  }

  /// Toggles visibility of column with [columnId].
  void toggleColumnVisibility(String columnId) {
    final updated = state.columns.map((col) {
      if (col.id == columnId) {
        return col.copyWith(isVisible: !col.isVisible);
      }
      return col;
    }).toList();
    state = state.copyWith(columns: updated);
  }

  /// Resizes column with [columnId] to [width].
  void resizeColumn(String columnId, double width) {
    final updated = state.columns.map((col) {
      if (col.id == columnId) {
        return col.copyWith(width: width);
      }
      return col;
    }).toList();
    state = state.copyWith(columns: updated);
  }

  /// Starts playback of the playlist beginning at track [index].
  void playTrack(int index) {
    if (index < 0 || index >= state.tracks.length) return;
    _playbackRepository.setPlaylist(
      tracksToPlay: state.tracks,
      initialIndex: index,
      playbackContextType: 'playlist',
      playbackContextId: playlistId,
    );
  }

  /// Starts playback from the first track in this playlist.
  void playAll() {
    if (state.tracks.isEmpty) return;
    playTrack(0);
  }

  static List<String> _calculateWallCovers(List<TrackWithArtists> tracks) {
    final wallCovers = <String>[];
    final seenWallCovers = <String>{};

    for (final track in tracks) {
      final artPath = track.album.albumArtPath;
      if (artPath != null && artPath.isNotEmpty && !seenWallCovers.contains(artPath)) {
        seenWallCovers.add(artPath);
        wallCovers.add(artPath);
      }
      if (wallCovers.length >= 5) break;
    }

    return wallCovers;
  }

  static const List<TableColumnConfig> _initialColumns = [
    TableColumnConfig(id: 'index', label: "#", width: 60, minWidth: 60, alignment: Alignment.centerRight),
    TableColumnConfig(id: 'title_artist', label: "Title/Artist", flex: 5, minWidth: 150),
    TableColumnConfig(id: 'album', label: "Album", flex: 3, minWidth: 100),
    TableColumnConfig(id: 'path', label: 'Path', flex: 3, minWidth: 120, isVisible: false),
    TableColumnConfig(
      id: 'date_added',
      label: "Date Added",
      width: 110,
      minWidth: 110,
      alignment: Alignment.centerRight,
      isVisible: true,
    ),
    TableColumnConfig(id: 'duration', label: 'Duration', width: 90, minWidth: 90, alignment: Alignment.centerRight),
  ];
}

/// Riverpod provider exposing [PlaylistDetailViewModel] parameterized by playlist ID.
final playlistDetailViewModelProvider = NotifierProvider.family<PlaylistDetailViewModel, PlaylistDetailUiState, int>(
  PlaylistDetailViewModel.new,
);

/// Backward-compatible provider for playlist collage album arts.
final playlistDetailsAlbumArtProvider = Provider.family<List<String>, int>((ref, playlistId) {
  return ref.watch(playlistDetailViewModelProvider(playlistId).select((s) => s.albumArtCovers));
});

/// Backward-compatible provider for playlist table columns.
final playlistDetailPageColumnsProvider = Provider.family<List<TableColumnConfig>, int>((ref, playlistId) {
  return ref.watch(playlistDetailViewModelProvider(playlistId).select((s) => s.columns));
});
