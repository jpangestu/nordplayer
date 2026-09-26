import 'package:media_kit/media_kit.dart';
import 'package:nordplayer/domain/models/composite_models.dart';
import 'package:nordplayer/domain/models/time_label_type.dart';

/// Cohesive immutable UI state representing the player bar and playback controls.
class const PlayerBarUiState({
  final TrackWithArtists? currentTrack,
  final bool isPlaying = false,
  final Duration position = Duration.zero,
  final Duration duration = Duration.zero,
  final double volume = 100.0,
  final bool isMuted = false,
  final bool isShuffle = false,
  final PlaylistMode loopMode = PlaylistMode.none,
  final bool showQueue = false,
  final TimeLabelType timeLabelType = TimeLabelType.totalTime,
  final bool isAdaptiveBgOn = false,
  final double adaptiveBgPanelBlur = 20.0,
  final double adaptiveBgThemeOverlay = 0.5,
}) {
  PlayerBarUiState copyWith({
    TrackWithArtists? Function()? currentTrack,
    bool? isPlaying,
    Duration? position,
    Duration? duration,
    double? volume,
    bool? isMuted,
    bool? isShuffle,
    PlaylistMode? loopMode,
    bool? showQueue,
    TimeLabelType? timeLabelType,
    bool? isAdaptiveBgOn,
    double? adaptiveBgPanelBlur,
    double? adaptiveBgThemeOverlay,
  }) {
    return PlayerBarUiState(
      currentTrack: currentTrack != null ? currentTrack() : this.currentTrack,
      isPlaying: isPlaying ?? this.isPlaying,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      volume: volume ?? this.volume,
      isMuted: isMuted ?? this.isMuted,
      isShuffle: isShuffle ?? this.isShuffle,
      loopMode: loopMode ?? this.loopMode,
      showQueue: showQueue ?? this.showQueue,
      timeLabelType: timeLabelType ?? this.timeLabelType,
      isAdaptiveBgOn: isAdaptiveBgOn ?? this.isAdaptiveBgOn,
      adaptiveBgPanelBlur: adaptiveBgPanelBlur ?? this.adaptiveBgPanelBlur,
      adaptiveBgThemeOverlay: adaptiveBgThemeOverlay ?? this.adaptiveBgThemeOverlay,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlayerBarUiState &&
          runtimeType == other.runtimeType &&
          currentTrack == other.currentTrack &&
          isPlaying == other.isPlaying &&
          position == other.position &&
          duration == other.duration &&
          volume == other.volume &&
          isMuted == other.isMuted &&
          isShuffle == other.isShuffle &&
          loopMode == other.loopMode &&
          showQueue == other.showQueue &&
          timeLabelType == other.timeLabelType &&
          isAdaptiveBgOn == other.isAdaptiveBgOn &&
          adaptiveBgPanelBlur == other.adaptiveBgPanelBlur &&
          adaptiveBgThemeOverlay == other.adaptiveBgThemeOverlay;

  @override
  int get hashCode => Object.hash(
        currentTrack,
        isPlaying,
        position,
        duration,
        volume,
        isMuted,
        isShuffle,
        loopMode,
        showQueue,
        timeLabelType,
        isAdaptiveBgOn,
        adaptiveBgPanelBlur,
        adaptiveBgThemeOverlay,
      );
}
