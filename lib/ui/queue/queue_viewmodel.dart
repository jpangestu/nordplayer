import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nordplayer/data/repositories/config_repository.dart';
import 'package:nordplayer/data/repositories/settings_repository.dart';
import 'package:nordplayer/data/services/audio/playback_controller.dart';
import 'package:nordplayer/domain/models/composite_models.dart';
import 'package:nordplayer/ui/queue/queue_scroll_behavior.dart';
import 'package:nordplayer/ui/queue/queue_ui_state.dart';
import 'package:nordplayer/ui/shared/ui/selection_state.dart';
import 'package:nordplayer/utils/logger.dart';

/// ViewModel managing state and operations for the playback Queue:
/// optimistic track reordering, single and batch removals, track selection,
/// scrolling behaviors, and adaptive UI styling.
class QueueViewModel extends Notifier<QueueUiState> with LoggerMixin {
  PlaybackController get _playbackController => ref.read(playbackControllerProvider);
  SettingsRepository get _settingsRepo => ref.read(settingsRepositoryProvider);
  SelectedTracksIndex get _selectionNotifier => ref.read(selectedTracksIndexProvider('queue_page').notifier);

  @override
  QueueUiState build() {
    final playbackController = ref.watch(playbackControllerProvider);
    final configRepo = ref.watch(configRepositoryProvider);

    final initialConfig = configRepo.currentConfig;
    final initialSelection = ref.read(selectedTracksIndexProvider('queue_page'));
    final initialScrollBehavior = ref.read(queueScrollBehaviorProvider);

    final queueStateSub = playbackController.watchQueueState().listen((qs) {
      final newTracks = qs.tracks;
      final newTrack = qs.currentItem?.track;
      final newIndex = qs.activeIndex;

      if (!listEquals(state.tracks, newTracks)) {
        ref.read(queueScrollBehaviorProvider.notifier).setIntent(QueueScrollBehavior.jump);
      } else if (state.currentIndex != newIndex) {
        final currentIntent = ref.read(queueScrollBehaviorProvider);
        if (currentIntent == QueueScrollBehavior.none) {
          ref.read(queueScrollBehaviorProvider.notifier).setIntent(QueueScrollBehavior.animate);
        }
      }

      state = state.copyWith(tracks: newTracks, currentTrack: () => newTrack, currentIndex: newIndex);
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
      queueStateSub.cancel();
      configSub.cancel();
    });

    return QueueUiState(
      tracks: playbackController.currentQueue,
      currentTrack: playbackController.currentTrack,
      currentIndex: playbackController.currentIndex,
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
  /// delegating to [PlaybackController] and shifting multi-selection indices.
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

    _playbackController.reorderQueue(oldIndex, newIndex);
    _selectionNotifier.updateIndicesOnReorder(oldIndex, newIndex);
  }

  /// Removes a single track at [index], shifting downstream selected indices.
  void removeTrack(int index) {
    log.d('QueueViewModel.removeTrack at index $index');
    _playbackController.removeQueueItem(index);
    _selectionNotifier.updateIndicesOnRemove(index);
  }

  /// Removes multiple tracks identified by [indices] atomically via `playbackController.removeQueueItems`.
  Future<void> removeSelectedTracks(List<int> indices) async {
    if (indices.isEmpty) return;
    log.i('QueueViewModel.removeSelectedTracks: ${indices.length} tracks');
    await _playbackController.removeQueueItems(indices);
    _selectionNotifier.clear();
  }

  /// Clears the entire playback queue and clears selection state.
  Future<void> clearQueue() async {
    log.i('QueueViewModel.clearQueue');
    await _playbackController.clearQueue();
    _selectionNotifier.clear();
  }

  /// Jumps playback directly to the track at [index], suppressing auto-scroll since the user triggered it.
  void jumpToTrack(int index) {
    ref.read(queueScrollBehaviorProvider.notifier).setIntent(QueueScrollBehavior.none);
    _playbackController.jumpToIndex(index);
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
