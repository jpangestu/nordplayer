import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nordplayer/database/app_database.dart';
import 'package:nordplayer/pages/pages_helper.dart';
import 'package:nordplayer/services/player_service.dart';

/// Checks if any text field in the app currently has focus.
/// Used to prevent global shortcuts (like Spacebar) from stealing keystrokes while typing.
bool _isAnyTextFieldFocused() {
  final focusContext = FocusManager.instance.primaryFocus?.context;
  if (focusContext == null) return false;

  // Helper function to check if a widget is any known text input type
  bool isTextInputWrapper(Widget w) {
    return w is EditableText ||
        w is TextField ||
        w is TextFormField ||
        w is SearchBar || // Material 3 SearchBar
        w is CupertinoTextField || // iOS style text field
        w is CupertinoSearchTextField;
  }

  if (isTextInputWrapper(focusContext.widget)) {
    return true;
  }

  // If a custom FocusNode is used, it gets attached to an internal Focus widget.
  // Traverse up the tree a few levels to find the parent TextField wrapper.
  bool isTextFieldFocused = false;
  int depth = 0;

  focusContext.visitAncestorElements((element) {
    final ancestorWidget = element.widget;
    if (ancestorWidget is TextField || ancestorWidget is TextFormField || ancestorWidget is EditableText) {
      isTextFieldFocused = true;
      return false;
    }

    depth++;
    // 10 levels is more than enough to escape internal wrapper widgets
    return depth <= 10;
  });

  return isTextFieldFocused;
}

// ================================================= Player Bar =======================================================

class PlayOrPauseIntent extends Intent {
  const PlayOrPauseIntent();
}

class PlayOrPauseAction extends Action<PlayOrPauseIntent> {
  PlayOrPauseAction(this.ref);
  final WidgetRef ref;

  @override
  bool isEnabled(covariant PlayOrPauseIntent intent) {
    if (_isAnyTextFieldFocused()) return false;
    return super.isEnabled(intent);
  }

  @override
  void invoke(covariant PlayOrPauseIntent intent) {
    ref.read(playerServiceProvider).playOrPause();
  }
}

class SkipToNextIntent extends Intent {
  const SkipToNextIntent();
}

class SkipToNextAction extends Action<SkipToNextIntent> {
  SkipToNextAction(this.ref);
  final WidgetRef ref;

  @override
  bool isEnabled(covariant SkipToNextIntent intent) {
    if (_isAnyTextFieldFocused()) return false;
    return super.isEnabled(intent);
  }

  @override
  void invoke(covariant SkipToNextIntent intent) {
    ref.read(playerServiceProvider).next();
  }
}

class SkipToPreviousIntent extends Intent {
  const SkipToPreviousIntent();
}

class SkipToPreviousAction extends Action<SkipToPreviousIntent> {
  SkipToPreviousAction(this.ref);
  final WidgetRef ref;

  @override
  bool isEnabled(covariant SkipToPreviousIntent intent) {
    if (_isAnyTextFieldFocused()) return false;
    return super.isEnabled(intent);
  }

  @override
  void invoke(covariant SkipToPreviousIntent intent) {
    ref.read(playerServiceProvider).previous();
  }
}

class ToggleShuffleIntent extends Intent {
  const ToggleShuffleIntent();
}

class ToggleShuffleAction extends Action<ToggleShuffleIntent> {
  ToggleShuffleAction(this.ref);
  final WidgetRef ref;

  @override
  bool isEnabled(covariant ToggleShuffleIntent intent) {
    if (_isAnyTextFieldFocused()) return false;
    return super.isEnabled(intent);
  }

  @override
  void invoke(covariant ToggleShuffleIntent intent) {
    ref.read(playerServiceProvider).toggleShuffle();
  }
}

class CycleLoopIntent extends Intent {
  const CycleLoopIntent();
}

class CycleLoopAction extends Action<CycleLoopIntent> {
  CycleLoopAction(this.ref);
  final WidgetRef ref;

  @override
  bool isEnabled(covariant CycleLoopIntent intent) {
    if (_isAnyTextFieldFocused()) return false;
    return super.isEnabled(intent);
  }

  @override
  void invoke(covariant CycleLoopIntent intent) {
    ref.read(playerServiceProvider).cycleLoopMode();
  }
}

class VolumeUpIntent extends Intent {
  const VolumeUpIntent();
}

class VolumeUpAction extends Action<VolumeUpIntent> {
  VolumeUpAction(this.ref);
  final WidgetRef ref;

  @override
  bool isEnabled(covariant VolumeUpIntent intent) {
    if (_isAnyTextFieldFocused()) return false;
    return super.isEnabled(intent);
  }

  @override
  void invoke(covariant VolumeUpIntent intent) {
    ref.read(playerServiceProvider).setVolumeUp(5);
  }
}

class VolumeDownIntent extends Intent {
  const VolumeDownIntent();
}

class VolumeDownAction extends Action<VolumeDownIntent> {
  VolumeDownAction(this.ref);
  final WidgetRef ref;

  @override
  bool isEnabled(covariant VolumeDownIntent intent) {
    if (_isAnyTextFieldFocused()) return false;
    return super.isEnabled(intent);
  }

  @override
  void invoke(covariant VolumeDownIntent intent) {
    ref.read(playerServiceProvider).setVolumeDown(5);
  }
}

class MuteIntent extends Intent {
  const MuteIntent();
}

class MuteAction extends Action<MuteIntent> {
  MuteAction(this.ref);
  final WidgetRef ref;

  @override
  bool isEnabled(covariant MuteIntent intent) {
    if (_isAnyTextFieldFocused()) return false;
    return super.isEnabled(intent);
  }

  @override
  void invoke(covariant MuteIntent intent) {
    ref.read(playerServiceProvider).toggleMute();
  }
}

// ================================================ Search Bar ========================================================

final searchFocusNodeProvider = Provider<FocusNode>((ref) {
  final node = FocusNode();
  ref.onDispose(() => node.dispose());
  return node;
});

class FocusSearchIntent extends Intent {
  const FocusSearchIntent();
}

class FocusSearchAction extends Action<FocusSearchIntent> {
  FocusSearchAction(this.ref);
  final WidgetRef ref;

  @override
  void invoke(covariant FocusSearchIntent intent) {
    ref.read(searchFocusNodeProvider).requestFocus();
  }
}

// ============================================= Tracks Table =========================================================

class PlaySelectedIntent extends Intent {
  const PlaySelectedIntent();
}

class PlaySelectedAction extends Action<PlaySelectedIntent> {
  PlaySelectedAction({
    required this.ref,
    required this.tableId,
    required this.playbackContextType,
    this.playbackContextId,
    required this.getTracks,
  });

  final WidgetRef ref;
  final String tableId;
  final String playbackContextType;
  final int? playbackContextId;
  final List<TrackWithArtists> Function() getTracks;

  @override
  bool isEnabled(covariant PlaySelectedIntent intent) {
    if (_isAnyTextFieldFocused()) return false;
    return super.isEnabled(intent);
  }

  @override
  void invoke(covariant PlaySelectedIntent intent) {
    // Fetch the latest tracks right when the key is pressed
    final tracks = getTracks();
    if (tracks.isEmpty) return;

    // Get the current selection for this specific table
    final selectedIndices = ref.read(selectedTracksIndexProvider(tableId));

    if (selectedIndices.isEmpty) return;

    if (selectedIndices.length == 1) {
      // Single Selection: Play the whole list, starting at the selected index
      final targetIndex = selectedIndices.first;
      ref
          .read(playerServiceProvider)
          .setPlaylist(
            tracksToPlay: tracks,
            initialIndex: targetIndex,
            playbackContextType: playbackContextType,
            playbackContextId: playbackContextId,
          );
    } else {
      // Multiple Selection: Play only the selected tracks as a new playlist
      final sortedIndices = selectedIndices.toList()..sort();
      final selectedTracks = sortedIndices.map((i) => tracks[i]).toList();

      ref
          .read(playerServiceProvider)
          .setPlaylist(
            tracksToPlay: selectedTracks,
            initialIndex: 0,
            playbackContextType: playbackContextType,
            playbackContextId: playbackContextId,
          );
    }
  }
}
