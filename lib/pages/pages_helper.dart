import 'dart:io';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// To store and retrieve selected index (int) from playbackContextType
/// Theis only store the indexes (int)
final selectedTracksIndexProvider = NotifierProvider.family<SelectedTracksIndex, Set<int>, String>(
  SelectedTracksIndex.new,
);

class SelectedTracksIndex extends Notifier<Set<int>> {
  SelectedTracksIndex(this.tableId);

  final String tableId;
  int? _anchorIndex;

  @override
  Set<int> build() => {};

  void clear() => state = {};

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
    // Flutter's ReorderableList: newIndex is already adjusted (the final destination index).
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

  /// Shifts any selected indices that appear *after* the removedIndex up by 1.
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
}

// TODO: Fix cannot open certain path with weird characters (' ` ;, etc) and replace debugPrint to logger
Future<void> showInFolder(String filePath) async {
  final file = File(filePath);
  if (!await file.exists()) {
    debugPrint("File does not exist: $filePath");
    return;
  }

  if (Platform.isLinux) {
    try {
      await Process.run('dbus-send', [
        '--session',
        '--dest=org.freedesktop.FileManager1',
        '--type=method_call',
        '/org/freedesktop/FileManager1',
        'org.freedesktop.FileManager1.ShowItems',
        'array:string:file://$filePath', // file:// + raw path
        'string:',
      ]);
    } catch (e) {
      // Fallback: If DBus fails, just open the parent directory
      final folderPath = file.parent.path;
      await Process.run('xdg-open', [folderPath]);
    }
  } else if (Platform.isWindows) {
    await Process.run('explorer.exe', ['/select,', filePath]);
  } else if (Platform.isMacOS) {
    await Process.run('open', ['-R', filePath]);
  }
}
