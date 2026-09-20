import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nordplayer/core/models/selection_state.dart';
import 'package:nordplayer/core/services/logger.dart';
import 'package:nordplayer/services/player_service.dart';

/// ViewModel managing queue actions: atomic batch removals, reordering, and clearing.
class QueueViewModel(final Ref _ref) with LoggerMixin {
  PlayerService get _playerService => _ref.read(playerServiceProvider);
  SelectedTracksIndex get _selectionNotifier =>
      _ref.read(selectedTracksIndexProvider('queue_page').notifier);

  /// Moves a track from [oldIndex] to [newIndex], synchronizing multi-selection state.
  void moveTrack(int oldIndex, int newIndex) {
    log.d('QueueViewModel.moveTrack from $oldIndex to $newIndex');
    _playerService.moveTrack(oldIndex, newIndex);
    _selectionNotifier.updateIndicesOnReorder(oldIndex, newIndex);
  }

  /// Removes a single track at [index], shifting downstream selected indices.
  void removeTrack(int index) {
    log.d('QueueViewModel.removeTrack at index $index');
    _playerService.removeTrack(index);
    _selectionNotifier.updateIndicesOnRemove(index);
  }

  /// Removes multiple tracks identified by [indices] atomically via `playerService.removeTracks`.
  Future<void> removeSelectedTracks(List<int> indices) async {
    if (indices.isEmpty) return;
    log.i('QueueViewModel.removeSelectedTracks: ${indices.length} tracks');
    await _playerService.removeTracks(indices);
    _selectionNotifier.clear();
  }

  /// Clears the entire playback queue and clears selection state.
  Future<void> clearQueue() async {
    log.i('QueueViewModel.clearQueue');
    await _playerService.clearQueue();
    _selectionNotifier.clear();
  }

  /// Jumps playback directly to the track at [index].
  void jumpToTrack(int index) {
    _playerService.jumpToIndex(index);
  }
}

/// Riverpod provider exposing [QueueViewModel].
final queueViewModelProvider = Provider<QueueViewModel>((ref) => QueueViewModel(ref));
