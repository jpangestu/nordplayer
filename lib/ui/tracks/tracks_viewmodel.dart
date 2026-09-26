import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nordplayer/ui/shared/ui/selection_state.dart';
import 'package:nordplayer/ui/shared/ui/table_column_config.dart';
import 'package:nordplayer/utils/logger.dart';
import 'package:nordplayer/data/repositories/config_repository.dart';
import 'package:nordplayer/data/repositories/playback_repository.dart';
import 'package:nordplayer/data/repositories/track_repository.dart';
import 'package:nordplayer/domain/models/composite_models.dart';
import 'package:nordplayer/ui/tracks/tracks_ui_state.dart';

/// Manages table column configurations (widths, ordering, visibility) for the all-tracks table.
class TracksPageColumnsNotifier extends Notifier<List<TableColumnConfig>> {
  @override
  List<TableColumnConfig> build() => initialColumns;

  void toggleVisibility(String columnId) {
    state = state.map((col) {
      if (col.id == columnId) {
        return col.copyWith(isVisible: !col.isVisible);
      }
      return col;
    }).toList();
  }

  static const List<TableColumnConfig> initialColumns = [
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
      isVisible: false,
    ),
    TableColumnConfig(id: 'duration', label: 'Duration', width: 90, minWidth: 90, alignment: Alignment.centerRight),
    TableColumnConfig(id: 'context_menu', label: '', width: 75, minWidth: 75, alignment: Alignment.centerRight),
  ];
}

/// ViewModel coordinating state and user actions for the Tracks feature.
class TracksViewModel extends Notifier<TracksUiState> with LoggerMixin {
  PlaybackRepository get _playbackRepository => ref.read(playbackRepositoryProvider);

  @override
  TracksUiState build() {
    final trackRepo = ref.watch(trackRepositoryProvider);
    final playbackRepo = ref.watch(playbackRepositoryProvider);
    final configRepo = ref.watch(configRepositoryProvider);

    final initialConfig = configRepo.currentConfig;
    final initialColumns = TracksPageColumnsNotifier.initialColumns;
    final initialSelection = ref.read(selectedTracksIndexProvider('all_tracks'));
    final currentTrack = playbackRepo.currentTrack;
    final isPlaying = playbackRepo.isPlaying;

    final tracksSub = trackRepo.watchAllTracks().listen(
      (tracks) {
        state = state.copyWith(
          tracks: tracks,
          isLoading: false,
          albumArtCovers: _computeCollageCovers(tracks, playbackRepo),
          errorMessage: () => null,
        );
      },
      onError: (error) {
        state = state.copyWith(isLoading: false, errorMessage: () => error.toString());
      },
    );

    final trackSub = playbackRepo.watchCurrentTrack().listen((current) {
      state = state.copyWith(
        activeTrackPath: () => current?.track.filePath,
        albumArtCovers: _computeCollageCovers(state.tracks, playbackRepo),
      );
    });

    final playingSub = playbackRepo.watchIsPlaying().listen((playing) {
      state = state.copyWith(isAudioPlaying: playing);
    });

    final queueSub = playbackRepo.watchQueue().listen((_) {
      state = state.copyWith(albumArtCovers: _computeCollageCovers(state.tracks, playbackRepo));
    });

    final configSub = configRepo.watchConfig().listen((config) {
      state = state.copyWith(
        isAdaptiveBg: config.adaptiveBg,
        adaptiveBgPanelBlur: config.adaptiveBgPanelBlur,
        adaptiveBgThemeOverlay: config.adaptiveBgThemeOverlay,
      );
    });

    ref.listen(selectedTracksIndexProvider('all_tracks'), (_, next) {
      if (!setEquals(state.selectedIndices, next)) {
        state = state.copyWith(selectedIndices: next);
      }
    });

    ref.onDispose(() {
      tracksSub.cancel();
      trackSub.cancel();
      playingSub.cancel();
      queueSub.cancel();
      configSub.cancel();
    });

    return TracksUiState(
      columns: initialColumns,
      selectedIndices: initialSelection,
      activeTrackPath: currentTrack?.track.filePath,
      isAudioPlaying: isPlaying,
      isLoading: true,
      isAdaptiveBg: initialConfig.adaptiveBg,
      adaptiveBgPanelBlur: initialConfig.adaptiveBgPanelBlur,
      adaptiveBgThemeOverlay: initialConfig.adaptiveBgThemeOverlay,
    );
  }

  /// Computes up to 5 unique album art paths for the tracks header collage.
  List<String> _computeCollageCovers(List<TrackWithArtists> tracks, PlaybackRepository playbackRepo) {
    if (playbackRepo.playbackContextType == 'all_tracks') {
      final queue = playbackRepo.currentQueue;
      final currentIndex = playbackRepo.currentIndex;
      if (queue.isNotEmpty && currentIndex >= 0 && currentIndex < queue.length) {
        final wallCovers = <String>[];
        final seen = <String>{};
        for (int i = currentIndex; i < queue.length && wallCovers.length < 5; i++) {
          final art = queue[i].album.albumArtPath;
          if (art != null && art.isNotEmpty && !seen.contains(art)) {
            seen.add(art);
            wallCovers.add(art);
          }
        }
        if (wallCovers.isNotEmpty) return wallCovers;
      }
    }

    if (tracks.isEmpty) return const [];

    final wallCovers = <String>[];
    final seen = <String>{};
    for (final track in tracks) {
      final art = track.album.albumArtPath;
      if (art != null && art.isNotEmpty && !seen.contains(art)) {
        seen.add(art);
        wallCovers.add(art);
      }
      if (wallCovers.length >= 5) break;
    }
    return wallCovers;
  }

  /// Plays the track at [index] in the context of [tracks].
  void playTrack(List<TrackWithArtists> tracks, int index) {
    if (tracks.isEmpty || index < 0 || index >= tracks.length) return;
    _playbackRepository.setPlaylist(
      playbackContextType: 'all_tracks',
      playbackContextId: null,
      tracksToPlay: tracks,
      initialIndex: index,
    );
  }

  /// Plays the track at [index] from the currently loaded tracks.
  void playTrackAt(int index) => playTrack(state.tracks, index);

  /// Plays the selected tracks as an ad-hoc playlist.
  void playAsPlaylist(
    List<TrackWithArtists> selectedTracks, {
    required int clickedIndex,
    required List<TrackWithArtists> allTracks,
  }) {
    if (selectedTracks.isEmpty) return;

    if (selectedTracks.length == 1) {
      playTrack(allTracks, clickedIndex);
      return;
    }

    final startingQueueIndex = selectedTracks.indexWhere(
      (t) => t.track.filePath == allTracks[clickedIndex].track.filePath,
    );

    _playbackRepository.setPlaylist(
      playbackContextType: 'play_as_playlist',
      playbackContextId: null,
      tracksToPlay: selectedTracks,
      initialIndex: startingQueueIndex == -1 ? 0 : startingQueueIndex,
    );
  }

  /// Plays the currently selected tracks starting from [clickedIndex] (or first selected).
  void playSelected({int? clickedIndex}) {
    final tracks = state.tracks;
    if (tracks.isEmpty) return;

    final sortedIndices = state.selectedIndices.toList()..sort();
    final selectedTracks = sortedIndices.where((i) => i >= 0 && i < tracks.length).map((i) => tracks[i]).toList();

    final effectiveClickedIndex = clickedIndex ?? (sortedIndices.isNotEmpty ? sortedIndices.first : 0);

    playAsPlaylist(selectedTracks, clickedIndex: effectiveClickedIndex, allTracks: tracks);
  }

  /// Selects or multi-selects track at [index].
  void selectTrack(int index, {required bool isCtrlSelect, required bool isShiftSelect}) {
    ref
        .read(selectedTracksIndexProvider('all_tracks').notifier)
        .selectTrack(index, isCtrlSelect: isCtrlSelect, isShiftSelect: isShiftSelect);
    state = state.copyWith(selectedIndices: ref.read(selectedTracksIndexProvider('all_tracks')));
  }

  /// Selects a single track at [index], clearing previous selections.
  void selectSingle(int index) {
    selectTrack(index, isCtrlSelect: false, isShiftSelect: false);
  }

  /// Selects all tracks in the current view.
  void selectAll() {
    final allIndices = Set<int>.from(List.generate(state.tracks.length, (i) => i));
    ref.read(selectedTracksIndexProvider('all_tracks').notifier).state = allIndices;
    state = state.copyWith(selectedIndices: allIndices);
  }

  /// Clears track selection.
  void clearSelection() {
    ref.read(selectedTracksIndexProvider('all_tracks').notifier).state = const {};
    state = state.copyWith(selectedIndices: const {});
  }

  /// Toggles visibility of the table column identified by [columnId].
  void toggleColumnVisibility(String columnId) {
    final updatedColumns = state.columns.map((col) {
      if (col.id == columnId) {
        return col.copyWith(isVisible: !col.isVisible);
      }
      return col;
    }).toList();
    state = state.copyWith(columns: updatedColumns);
  }
}

/// Riverpod provider exposing [TracksViewModel].
final tracksViewModelProvider = NotifierProvider<TracksViewModel, TracksUiState>(TracksViewModel.new);

/// Backward-compatible provider for table column configurations.
final tracksPageColumnsProvider = NotifierProvider<TracksPageColumnsNotifier, List<TableColumnConfig>>(
  TracksPageColumnsNotifier.new,
);

/// Backward-compatible provider for header collage album art paths.
final libraryAlbumArtProvider = Provider<List<String>>((ref) {
  return ref.watch(tracksViewModelProvider.select((s) => s.albumArtCovers));
});
