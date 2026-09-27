import 'dart:math' show Random;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nordplayer/data/repositories/album_repository.dart';
import 'package:nordplayer/data/repositories/config_repository.dart';
import 'package:nordplayer/data/repositories/playback_repository.dart';
import 'package:nordplayer/data/repositories/settings_repository.dart';
import 'package:nordplayer/domain/models/composite_models.dart';
import 'package:nordplayer/domain/models/playback_context.dart';
import 'package:nordplayer/ui/albums/album_detail_ui_state.dart';
import 'package:nordplayer/ui/shared/ui/selection_state.dart';
import 'package:nordplayer/ui/shared/ui/table_column_config.dart';
import 'package:nordplayer/utils/logger.dart';

/// ViewModel orchestrating Album Detail state, sorting, filtering, columns, selection, and playback.
class AlbumDetailViewModel(final int albumId) extends Notifier<AlbumDetailUiState> with LoggerMixin {
  PlaybackRepository get _playbackRepository => ref.read(playbackRepositoryProvider);
  SettingsRepository get _settingsRepository => ref.read(settingsRepositoryProvider);

  @override
  AlbumDetailUiState build() {
    final albumRepo = ref.watch(albumRepositoryProvider);
    final playbackRepo = ref.watch(playbackRepositoryProvider);
    final configRepo = ref.watch(configRepositoryProvider);
    final settingsRepo = ref.watch(settingsRepositoryProvider);

    final initialConfig = configRepo.currentConfig;
    final initialColumns = _initialColumns;
    final initialSelection = ref.read(selectedTracksIndexProvider('album'));
    final currentTrack = playbackRepo.currentTrack;
    final isPlaying = playbackRepo.isPlaying;
    final initialSettings = settingsRepo.currentSettings;

    final albumSub = albumRepo
        .watchAlbumWithTracks(albumId)
        .listen(
          (raw) {
            final sorted = _applySortAndFilter(raw, state.sortCriteria, state.sortOrder, state.showFavoritesOnly);
            state = state.copyWith(
              rawAlbumWithTracks: () => raw,
              albumWithTracks: () => sorted,
              isLoading: false,
              errorMessage: () => null,
            );
          },
          onError: (err) {
            log.e('Error loading album $albumId: $err');
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

    final settingsSub = settingsRepo.watchSettings().listen((settings) {
      if (state.shouldShuffle != settings.shuffleMode) {
        state = state.copyWith(shouldShuffle: settings.shuffleMode);
      }
    });

    ref.listen(selectedTracksIndexProvider('album'), (_, next) {
      if (!setEquals(state.selectedIndices, next)) {
        state = state.copyWith(selectedIndices: next);
      }
    });

    ref.onDispose(() {
      albumSub.cancel();
      trackSub.cancel();
      playingSub.cancel();
      configSub.cancel();
      settingsSub.cancel();
    });

    return AlbumDetailUiState(
      columns: initialColumns,
      selectedIndices: initialSelection,
      activeTrackPath: currentTrack?.track.filePath,
      isAudioPlaying: isPlaying,
      shouldShuffle: initialSettings.shuffleMode,
      isLoading: true,
      isAdaptiveBg: initialConfig.adaptiveBg,
      adaptiveBgPanelBlur: initialConfig.adaptiveBgPanelBlur,
      adaptiveBgThemeOverlay: initialConfig.adaptiveBgThemeOverlay,
    );
  }

  /// Sets sorting criteria (track number, title, duration) and re-sorts tracks.
  void setSort(AlbumTrackSort sort) {
    if (state.sortCriteria == sort) return;
    final sorted = _applySortAndFilter(state.rawAlbumWithTracks, sort, state.sortOrder, state.showFavoritesOnly);
    state = state.copyWith(sortCriteria: sort, albumWithTracks: () => sorted);
  }

  /// Sets sorting order (ascending, descending) and re-sorts tracks.
  void setOrder(SortOrder order) {
    if (state.sortOrder == order) return;
    final sorted = _applySortAndFilter(state.rawAlbumWithTracks, state.sortCriteria, order, state.showFavoritesOnly);
    state = state.copyWith(sortOrder: order, albumWithTracks: () => sorted);
  }

  /// Toggles favorites-only filter for album tracks.
  void toggleFavoritesOnly() {
    final toggled = !state.showFavoritesOnly;
    final sorted = _applySortAndFilter(state.rawAlbumWithTracks, state.sortCriteria, state.sortOrder, toggled);
    state = state.copyWith(showFavoritesOnly: toggled, albumWithTracks: () => sorted);
  }

  /// Toggles shuffle mode for album playback and syncs with [SettingsRepository].
  void toggleShuffle() {
    final newShuffle = !state.shouldShuffle;
    state = state.copyWith(shouldShuffle: newShuffle);
    _settingsRepository.setShuffleMode(newShuffle);
  }

  /// Toggles column visibility for column [columnId].
  void toggleColumnVisibility(String columnId) {
    final updated = state.columns.map((col) {
      if (col.id == columnId) {
        return col.copyWith(isVisible: !col.isVisible);
      }
      return col;
    }).toList();
    state = state.copyWith(columns: updated);
  }

  /// Selects track at [index] supporting multi-select modifier keys.
  void selectTrack(int index, {required bool isCtrlSelect, required bool isShiftSelect}) {
    ref
        .read(selectedTracksIndexProvider('album').notifier)
        .selectTrack(index, isCtrlSelect: isCtrlSelect, isShiftSelect: isShiftSelect);
  }

  /// Selects single track at [index], clearing previous selections.
  void selectSingle(int index) {
    selectTrack(index, isCtrlSelect: false, isShiftSelect: false);
  }

  /// Clears active track selection.
  void clearSelection() {
    ref.read(selectedTracksIndexProvider('album').notifier).clear();
  }

  /// Plays the given album tracks, optionally picking a random start index if shuffle is enabled,
  /// and synchronizes user preferences.
  void playAlbum({List<TrackWithArtists>? tracks, int? initialIndex, bool? shouldShuffle, bool forceReload = true}) {
    final tracksToPlay = tracks ?? state.albumWithTracks?.tracks ?? const [];
    if (tracksToPlay.isEmpty) return;

    final shuffle = shouldShuffle ?? state.shouldShuffle;
    final startIndex = initialIndex ?? (shuffle && tracksToPlay.isNotEmpty ? Random().nextInt(tracksToPlay.length) : 0);

    _settingsRepository.setShuffleMode(shuffle);

    final albumTitle = state.albumWithTracks?.album.title ?? '';

    _playbackRepository.setPlaylist(
      tracksToPlay: tracksToPlay,
      initialIndex: startIndex,
      context: PlaybackContext.album(id: albumId, title: albumTitle),
      playbackContextType: 'album',
      playbackContextId: albumId,
      playbackContextTitle: albumTitle,
      forceReload: forceReload,
    );
  }

  static AlbumWithTracks? _applySortAndFilter(
    AlbumWithTracks? raw,
    AlbumTrackSort sortCriteria,
    SortOrder sortOrder,
    bool showFavoritesOnly,
  ) {
    if (raw == null) return null;
    final orderMultiplier = sortOrder == SortOrder.ascending ? 1 : -1;
    var sortedTracks = List<TrackWithArtists>.from(raw.tracks);

    if (showFavoritesOnly) {
      // Future favorite filter hook
    }

    switch (sortCriteria) {
      case AlbumTrackSort.trackNumber:
        sortedTracks.sort((a, b) => a.track.trackNumber.compareTo(b.track.trackNumber) * orderMultiplier);
        break;
      case AlbumTrackSort.title:
        sortedTracks.sort(
          (a, b) => a.track.title.toLowerCase().compareTo(b.track.title.toLowerCase()) * orderMultiplier,
        );
        break;
      case AlbumTrackSort.duration:
        sortedTracks.sort((a, b) => a.track.durationMs.compareTo(b.track.durationMs) * orderMultiplier);
        break;
    }

    return AlbumWithTracks(album: raw.album, tracks: sortedTracks, tracksLengthMs: raw.tracksLengthMs);
  }

  static const List<TableColumnConfig> _initialColumns = [
    TableColumnConfig(id: 'index', label: "#", width: 50, minWidth: 50, alignment: Alignment.centerRight),
    TableColumnConfig(id: 'title', label: "Title", flex: 5, minWidth: 150),
    TableColumnConfig(id: 'duration', label: 'Duration', width: 90, minWidth: 90, alignment: Alignment.center),
    TableColumnConfig(id: 'context_menu', label: '', width: 115, minWidth: 115, alignment: Alignment.centerRight),
  ];
}

/// Riverpod provider exposing [AlbumDetailViewModel] parameterized by album ID.
final albumDetailViewModelProvider = NotifierProvider.family<AlbumDetailViewModel, AlbumDetailUiState, int>(
  AlbumDetailViewModel.new,
);

/// Backward-compatible provider for album track columns.
final albumDetailPageTableColumnsProvider = Provider.family<List<TableColumnConfig>, int>((ref, albumId) {
  return ref.watch(albumDetailViewModelProvider(albumId).select((s) => s.columns));
});

/// Backward-compatible provider for sorted album with tracks.
final sortedAlbumWithTracksProvider = Provider.autoDispose.family<AsyncValue<AlbumWithTracks?>, int>((ref, albumId) {
  final uiState = ref.watch(albumDetailViewModelProvider(albumId));
  if (uiState.isLoading) return const AsyncValue.loading();
  if (uiState.errorMessage != null) {
    return AsyncValue.error(uiState.errorMessage!, StackTrace.current);
  }
  return AsyncValue.data(uiState.albumWithTracks);
});
