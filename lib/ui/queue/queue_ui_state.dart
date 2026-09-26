import 'package:flutter/foundation.dart';
import 'package:nordplayer/domain/models/composite_models.dart';
import 'package:nordplayer/ui/queue/queue_scroll_behavior.dart';

/// Immutable UI state representing the active playback queue, current track,
/// selection state, drag-and-drop status, and adaptive styling tokens.
class const QueueUiState({
  final List<TrackWithArtists> tracks = const [],
  final TrackWithArtists? currentTrack,
  final int currentIndex = -1,
  final Set<int> selectedIndices = const {},
  final bool isDragging = false,
  final QueueScrollBehavior scrollBehavior = QueueScrollBehavior.none,
  final bool isAdaptiveBg = false,
  final double adaptiveBgPanelBlur = 20.0,
  final double adaptiveBgThemeOverlay = 0.5,
}) {
  /// Whether the queue is currently empty.
  bool get isEmpty => tracks.isEmpty;

  /// The total number of tracks in the queue.
  int get trackCount => tracks.length;

  /// Checks if [track] is the currently active/playing track.
  bool isCurrentlyPlaying(TrackWithArtists track) {
    if (currentTrack == null) return false;
    return currentTrack!.track.filePath == track.track.filePath;
  }

  QueueUiState copyWith({
    List<TrackWithArtists>? tracks,
    TrackWithArtists? Function()? currentTrack,
    int? currentIndex,
    Set<int>? selectedIndices,
    bool? isDragging,
    QueueScrollBehavior? scrollBehavior,
    bool? isAdaptiveBg,
    double? adaptiveBgPanelBlur,
    double? adaptiveBgThemeOverlay,
  }) {
    return QueueUiState(
      tracks: tracks ?? this.tracks,
      currentTrack: currentTrack != null ? currentTrack() : this.currentTrack,
      currentIndex: currentIndex ?? this.currentIndex,
      selectedIndices: selectedIndices ?? this.selectedIndices,
      isDragging: isDragging ?? this.isDragging,
      scrollBehavior: scrollBehavior ?? this.scrollBehavior,
      isAdaptiveBg: isAdaptiveBg ?? this.isAdaptiveBg,
      adaptiveBgPanelBlur: adaptiveBgPanelBlur ?? this.adaptiveBgPanelBlur,
      adaptiveBgThemeOverlay: adaptiveBgThemeOverlay ?? this.adaptiveBgThemeOverlay,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QueueUiState &&
          runtimeType == other.runtimeType &&
          listEquals(tracks, other.tracks) &&
          currentTrack == other.currentTrack &&
          currentIndex == other.currentIndex &&
          setEquals(selectedIndices, other.selectedIndices) &&
          isDragging == other.isDragging &&
          scrollBehavior == other.scrollBehavior &&
          isAdaptiveBg == other.isAdaptiveBg &&
          adaptiveBgPanelBlur == other.adaptiveBgPanelBlur &&
          adaptiveBgThemeOverlay == other.adaptiveBgThemeOverlay;

  @override
  int get hashCode => Object.hash(
    Object.hashAll(tracks),
    currentTrack,
    currentIndex,
    Object.hashAll(selectedIndices),
    isDragging,
    scrollBehavior,
    isAdaptiveBg,
    adaptiveBgPanelBlur,
    adaptiveBgThemeOverlay,
  );

  @override
  String toString() =>
      'QueueUiState(trackCount: ${tracks.length}, currentIndex: $currentIndex, isDragging: $isDragging, selected: ${selectedIndices.length})';
}
