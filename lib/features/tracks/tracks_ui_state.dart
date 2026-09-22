import 'package:flutter/foundation.dart';
import 'package:nordplayer/core/models/table_column_config.dart';
import 'package:nordplayer/domain/models/models.dart';

/// Immutable UI State snapshot for the Tracks screen.
class const TracksUiState({
  final List<TrackWithArtists> tracks = const [],
  final Set<int> selectedIndices = const {},
  final List<TableColumnConfig> columns = const [],
  final List<String> albumArtCovers = const [],
  final bool isLoading = true,
  final String? activeTrackPath,
  final bool isAudioPlaying = false,
  final String? errorMessage,
  final bool isAdaptiveBg = false,
  final double adaptiveBgPanelBlur = 20.0,
  final double adaptiveBgThemeOverlay = 0.5,
}) {
  /// Total duration of all loaded tracks in milliseconds.
  int get totalDurationMs => tracks.fold(0, (sum, track) => sum + track.track.durationMs);

  /// Number of tracks loaded.
  int get trackCount => tracks.length;

  /// Whether the library is empty after loading has finished.
  bool get isEmpty => !isLoading && tracks.isEmpty;

  TracksUiState copyWith({
    List<TrackWithArtists>? tracks,
    Set<int>? selectedIndices,
    List<TableColumnConfig>? columns,
    List<String>? albumArtCovers,
    bool? isLoading,
    String? Function()? activeTrackPath,
    bool? isAudioPlaying,
    String? Function()? errorMessage,
    bool? isAdaptiveBg,
    double? adaptiveBgPanelBlur,
    double? adaptiveBgThemeOverlay,
  }) {
    return TracksUiState(
      tracks: tracks ?? this.tracks,
      selectedIndices: selectedIndices ?? this.selectedIndices,
      columns: columns ?? this.columns,
      albumArtCovers: albumArtCovers ?? this.albumArtCovers,
      isLoading: isLoading ?? this.isLoading,
      activeTrackPath: activeTrackPath != null ? activeTrackPath() : this.activeTrackPath,
      isAudioPlaying: isAudioPlaying ?? this.isAudioPlaying,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      isAdaptiveBg: isAdaptiveBg ?? this.isAdaptiveBg,
      adaptiveBgPanelBlur: adaptiveBgPanelBlur ?? this.adaptiveBgPanelBlur,
      adaptiveBgThemeOverlay: adaptiveBgThemeOverlay ?? this.adaptiveBgThemeOverlay,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TracksUiState &&
          runtimeType == other.runtimeType &&
          listEquals(tracks, other.tracks) &&
          setEquals(selectedIndices, other.selectedIndices) &&
          listEquals(columns, other.columns) &&
          listEquals(albumArtCovers, other.albumArtCovers) &&
          isLoading == other.isLoading &&
          activeTrackPath == other.activeTrackPath &&
          isAudioPlaying == other.isAudioPlaying &&
          errorMessage == other.errorMessage &&
          isAdaptiveBg == other.isAdaptiveBg &&
          adaptiveBgPanelBlur == other.adaptiveBgPanelBlur &&
          adaptiveBgThemeOverlay == other.adaptiveBgThemeOverlay;

  @override
  int get hashCode => Object.hash(
        Object.hashAll(tracks),
        Object.hashAll(selectedIndices),
        Object.hashAll(columns),
        Object.hashAll(albumArtCovers),
        isLoading,
        activeTrackPath,
        isAudioPlaying,
        errorMessage,
        isAdaptiveBg,
        adaptiveBgPanelBlur,
        adaptiveBgThemeOverlay,
      );
}
