import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nordplayer/database/app_database.dart';
import 'package:nordplayer/pages/library_page.dart';
import 'package:nordplayer/services/player_service.dart';

// =========================== Player Bar ================================

class PlayOrPauseIntent extends Intent {
  const PlayOrPauseIntent();
}

class PlayOrPauseAction extends Action<PlayOrPauseIntent> {
  PlayOrPauseAction(this.ref);
  final WidgetRef ref;

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
  void invoke(covariant MuteIntent intent) {
    ref.read(playerServiceProvider).toggleMute();
  }
}

// ========================== Tracks Table ===============================

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
  void invoke(covariant PlaySelectedIntent intent) {
    // Fetch the latest tracks right when the key is pressed
    final allTracks = getTracks();
    if (allTracks.isEmpty) return;

    // Get the current selection for this specific table
    final selectedIndices = ref.read(selectedTracksIndexProvider(tableId));

    if (selectedIndices.isEmpty) return;

    if (selectedIndices.length == 1) {
      // Single Selection: Play the whole list, starting at the selected index
      final targetIndex = selectedIndices.first;
      ref
          .read(playerServiceProvider)
          .setPlaylist(
            tracksToPlay: allTracks,
            initialIndex: targetIndex,
            playbackContextType: playbackContextType,
            playbackContextId: playbackContextId,
          );
    } else {
      // Multiple Selection: Play only the selected tracks as a new playlist
      final sortedIndices = selectedIndices.toList()..sort();
      final selectedTracks = sortedIndices.map((i) => allTracks[i]).toList();

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
