import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nordplayer/data/repositories/config_repository.dart';
import 'package:nordplayer/data/repositories/playback_repository.dart';
import 'package:nordplayer/data/repositories/settings_repository.dart';
import 'package:nordplayer/domain/models/composite_models.dart';
import 'package:nordplayer/ui/queue/queue_scroll_behavior.dart';
import 'package:nordplayer/ui/queue/queue_ui_state.dart';
import 'package:nordplayer/ui/shared/ui/selection_state.dart';
import 'package:nordplayer/utils/logger.dart';

/// ViewModel managing state and operations for the playback Queue:
/// optimistic track reordering, single and batch removals, track selection,
/// scrolling behaviors, and adaptive UI styling.
class QueueViewModel extends Notifier<QueueUiState> with LoggerMixin {
  PlaybackRepository get _playbackRepo => ref.read(playbackRepositoryProvider);
  SettingsRepository get _settingsRepo => ref.read(settingsRepositoryProvider);
  SelectedTracksIndex get _selectionNotifier => ref.read(selectedTracksIndexProvider('queue_page').notifier);

  @override
  QueueUiState build() {
    final playbackRepo = ref.watch(playbackRepositoryProvider);
    final configRepo = ref.watch(configRepositoryProvider);

    final initialConfig = configRepo.currentConfig;
    final initialSelection = ref.read(selectedTracksIndexProvider('queue_page'));
    final initialScrollBehavior = ref.read(queueScrollBehaviorProvider);

    final queueSub = playbackRepo.watchQueue().listen((tracks) {
      if (state.tracks != tracks) {
        ref.read(queueScrollBehaviorProvider.notifier).setIntent(QueueScrollBehavior.jump);
      }
      state = state.copyWith(tracks: tracks);
    });

    final currentTrackSub = playbackRepo.watchCurrentTrack().listen((track) {
      state = state.copyWith(currentTrack: () => track);
    });

    final currentIndexSub = playbackRepo.watchCurrentIndex().listen((index) {
      if (state.currentIndex != index) {
        final currentIntent = ref.read(queueScrollBehaviorProvider);
        if (currentIntent == QueueScrollBehavior.none) {
          ref.read(queueScrollBehaviorProvider.notifier).setIntent(QueueScrollBehavior.animate);
        }
        state = state.copyWith(currentIndex: index);
      }
    });

    final configSub = configRepo.watchConfig().listen((config) {
      state = state.copyWith(
        isAdaptiveBg: config.adaptiveBg,
        adaptiveBgPanelBlur: config.adaptiveBgPanelBlur,
        adaptiveBgThemeOverlay: config.adaptiveBgThemeOverlay,
      );
    });

    ref.listen(selectedTracksIndexProvider('queue_page'), (_, next) {
      if (!setEquals(state.selectedIndices, next)) {
        state = state.copyWith(selectedIndices: next);
      }
    });

    ref.listen(queueScrollBehaviorProvider, (_, next) {
      if (state.scrollBehavior != next) {
        state = state.copyWith(scrollBehavior: next);
      }
    });

    ref.onDispose(() {
      queueSub.cancel();
      currentTrackSub.cancel();
      currentIndexSub.cancel();
      configSub.cancel();
    });

    return QueueUiState(
      tracks: playbackRepo.currentQueue,
      currentTrack: playbackRepo.currentTrack,
      currentIndex: playbackRepo.currentIndex,
      selectedIndices: initialSelection,
      scrollBehavior: initialScrollBehavior,
      isAdaptiveBg: initialConfig.adaptiveBg,
      adaptiveBgPanelBlur: initialConfig.adaptiveBgPanelBlur,
      adaptiveBgThemeOverlay: initialConfig.adaptiveBgThemeOverlay,
    );
  }

  /// Sets whether a reorder drag operation is actively in progress.
  void setDragging(bool isDragging) {
    if (state.isDragging != isDragging) {
      state = state.copyWith(isDragging: isDragging);
    }
  }

  /// Moves a track from [oldIndex] to [newIndex] with optimistic state updating,
  /// delegating to [PlaybackRepository] and shifting multi-selection indices.
  void moveTrack(int oldIndex, int newIndex) {
    log.d('QueueViewModel.moveTrack from $oldIndex to $newIndex');

    // Optimistically reorder state.tracks to ensure instant UI responsiveness
    final list = List<TrackWithArtists>.from(state.tracks);
    if (oldIndex >= 0 && oldIndex < list.length && newIndex >= 0 && newIndex <= list.length) {
      final item = list.removeAt(oldIndex);
      final targetIndex = newIndex.clamp(0, list.length);
      list.insert(targetIndex, item);
      state = state.copyWith(tracks: list);
    }

    _playbackRepo.reorderQueue(oldIndex, newIndex);
    _selectionNotifier.updateIndicesOnReorder(oldIndex, newIndex);
  }

  /// Removes a single track at [index], shifting downstream selected indices.
  void removeTrack(int index) {
    log.d('QueueViewModel.removeTrack at index $index');
    _playbackRepo.removeQueueItem(index);
    _selectionNotifier.updateIndicesOnRemove(index);
  }

  /// Removes multiple tracks identified by [indices] atomically via `playbackRepo.removeQueueItems`.
  Future<void> removeSelectedTracks(List<int> indices) async {
    if (indices.isEmpty) return;
    log.i('QueueViewModel.removeSelectedTracks: ${indices.length} tracks');
    await _playbackRepo.removeQueueItems(indices);
    _selectionNotifier.clear();
  }

  /// Clears the entire playback queue and clears selection state.
  Future<void> clearQueue() async {
    log.i('QueueViewModel.clearQueue');
    await _playbackRepo.clearQueue();
    _selectionNotifier.clear();
  }

  /// Jumps playback directly to the track at [index], suppressing auto-scroll since the user triggered it.
  void jumpToTrack(int index) {
    ref.read(queueScrollBehaviorProvider.notifier).setIntent(QueueScrollBehavior.none);
    _playbackRepo.jumpToIndex(index);
  }

  /// Selects or multi-selects a track index in the queue.
  void selectTrack(int index, {required bool isCtrl, required bool isShift}) {
    _selectionNotifier.selectTrack(index, isCtrlSelect: isCtrl, isShiftSelect: isShift);
  }

  /// Closes the queue sidebar drawer.
  Future<void> closeQueue() async {
    await _settingsRepo.setShowQueue(false);
  }

  /// Resets active scroll intent back to [QueueScrollBehavior.none].
  void resetScrollBehavior() {
    ref.read(queueScrollBehaviorProvider.notifier).setIntent(QueueScrollBehavior.none);
    state = state.copyWith(scrollBehavior: QueueScrollBehavior.none);
  }
}

/// Riverpod provider exposing [QueueViewModel] and [QueueUiState].
final queueViewModelProvider = NotifierProvider<QueueViewModel, QueueUiState>(QueueViewModel.new);
