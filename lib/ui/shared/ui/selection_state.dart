import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Riverpod family provider for managing multi-track selection indices per table context.
final selectedTracksIndexProvider = NotifierProvider.family<SelectedTracksIndex, Set<int>, String>(
  SelectedTracksIndex.new,
);

/// Manages multi-selection index state (click, Ctrl+click, Shift+click range selection)
/// and handles reorder/removal index adjustments.
class SelectedTracksIndex(final String tableId) extends Notifier<Set<int>> {
  int? _anchorIndex;

  @override
  Set<int> build() => const {};

  /// Clears the current selection.
  void clear() {
    _anchorIndex = null;
    state = const {};
  }

  /// Selects all indices from 0 up to [totalCount] - 1.
  void selectAll(int totalCount) {
    if (totalCount <= 0) {
      clear();
      return;
    }
    _anchorIndex = 0;
    state = {for (var i = 0; i < totalCount; i++) i};
  }

  /// Handles track selection based on keyboard modifier keys (Ctrl/Cmd and Shift).
  void selectTrack(int index, {required bool isCtrlSelect, required bool isShiftSelect}) {
    if (isShiftSelect) {
      final start = _anchorIndex ?? index;
      final minIdx = start < index ? start : index;
      final maxIdx = start > index ? start : index;
      final range = <int>{for (var i = minIdx; i <= maxIdx; i++) i};

      if (isCtrlSelect) {
        state = {...state, ...range};
      } else {
        state = range;
      }
    } else if (isCtrlSelect) {
      _anchorIndex = index;
      if (state.contains(index)) {
        state = {...state}..remove(index);
      } else {
        state = {...state, index};
      }
    } else {
      _anchorIndex = index;
      state = {index};
    }
  }

  /// Maps the current selected indices to their new positions after a track is moved.
  void updateIndicesOnReorder(int oldIndex, int newIndex) {
    final actualNewIndex = newIndex;

    int mapIndex(int i) {
      if (i == oldIndex) return actualNewIndex;
      if (oldIndex < actualNewIndex) {
        // Moving down: shift items between old and new indices up by 1
        if (i > oldIndex && i <= actualNewIndex) return i - 1;
      } else if (oldIndex > actualNewIndex) {
        // Moving up: shift items between new and old indices down by 1
        if (i >= actualNewIndex && i < oldIndex) return i + 1;
      }
      return i;
    }

    state = state.map(mapIndex).toSet();
    if (_anchorIndex != null) {
      _anchorIndex = mapIndex(_anchorIndex!);
    }
  }

  /// Shifts any selected indices that appear *after* the [removedIndex] down by 1.
  void updateIndicesOnRemove(int removedIndex) {
    state = state.where((i) => i != removedIndex).map((i) => i > removedIndex ? i - 1 : i).toSet();

    if (_anchorIndex != null) {
      if (_anchorIndex == removedIndex) {
        _anchorIndex = null;
      } else if (_anchorIndex! > removedIndex) {
        _anchorIndex = _anchorIndex! - 1;
      }
    }
  }

  /// Shifts selected indices when multiple tracks are batch removed at [removedIndices].
  void updateIndicesOnBatchRemove(List<int> removedIndices) {
    if (removedIndices.isEmpty) return;
    final sortedRemovals = removedIndices.toSet().toList()..sort();
    final newSelection = <int>{};

    for (final index in state) {
      if (sortedRemovals.contains(index)) continue;
      // Count how many removed items were before this index
      final shift = sortedRemovals.where((r) => r < index).length;
      newSelection.add(index - shift);
    }

    state = newSelection;
    _anchorIndex = null;
  }
}
