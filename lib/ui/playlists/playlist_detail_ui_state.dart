import 'package:flutter/foundation.dart';
import 'package:nordplayer/ui/shared/ui/table_column_config.dart';
import 'package:nordplayer/domain/models/models.dart';

/// Immutable UI state representing the Playlist Detail screen.
class const PlaylistDetailUiState({
  final Playlist? playlist,
  final List<TrackWithArtists> tracks = const [],
  final Set<int> selectedIndices = const {},
  final List<TableColumnConfig> columns = const [],
  final List<String> albumArtCovers = const [],
  final bool isLoading = true,
  final String? errorMessage,
  final String? activeTrackPath,
  final bool isAudioPlaying = false,
  final bool isAdaptiveBg = false,
  final double adaptiveBgPanelBlur = 20.0,
  final double adaptiveBgThemeOverlay = 0.5,
}) {
  /// Whether the playlist has finished loading and contains no tracks.
  bool get isEmpty => !isLoading && tracks.isEmpty;

  /// Total duration of all tracks in the playlist in milliseconds.
  int get totalDurationMs => tracks.fold(0, (sum, track) => sum + track.track.durationMs);

  /// Total count of tracks in this playlist.
  int get trackCount => tracks.length;

  PlaylistDetailUiState copyWith({
    Playlist? Function()? playlist,
    List<TrackWithArtists>? tracks,
    Set<int>? selectedIndices,
    List<TableColumnConfig>? columns,
    List<String>? albumArtCovers,
    bool? isLoading,
    String? Function()? errorMessage,
    String? Function()? activeTrackPath,
    bool? isAudioPlaying,
    bool? isAdaptiveBg,
    double? adaptiveBgPanelBlur,
    double? adaptiveBgThemeOverlay,
  }) {
    return PlaylistDetailUiState(
      playlist: playlist != null ? playlist() : this.playlist,
      tracks: tracks ?? this.tracks,
      selectedIndices: selectedIndices ?? this.selectedIndices,
      columns: columns ?? this.columns,
      albumArtCovers: albumArtCovers ?? this.albumArtCovers,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      activeTrackPath: activeTrackPath != null ? activeTrackPath() : this.activeTrackPath,
      isAudioPlaying: isAudioPlaying ?? this.isAudioPlaying,
      isAdaptiveBg: isAdaptiveBg ?? this.isAdaptiveBg,
      adaptiveBgPanelBlur: adaptiveBgPanelBlur ?? this.adaptiveBgPanelBlur,
      adaptiveBgThemeOverlay: adaptiveBgThemeOverlay ?? this.adaptiveBgThemeOverlay,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlaylistDetailUiState &&
          runtimeType == other.runtimeType &&
          playlist == other.playlist &&
          listEquals(tracks, other.tracks) &&
          setEquals(selectedIndices, other.selectedIndices) &&
          listEquals(columns, other.columns) &&
          listEquals(albumArtCovers, other.albumArtCovers) &&
          isLoading == other.isLoading &&
          errorMessage == other.errorMessage &&
          activeTrackPath == other.activeTrackPath &&
          isAudioPlaying == other.isAudioPlaying &&
          isAdaptiveBg == other.isAdaptiveBg &&
          adaptiveBgPanelBlur == other.adaptiveBgPanelBlur &&
          adaptiveBgThemeOverlay == other.adaptiveBgThemeOverlay;

  @override
  int get hashCode => Object.hash(
        playlist,
        Object.hashAll(tracks),
        Object.hashAll(selectedIndices),
        Object.hashAll(columns),
        Object.hashAll(albumArtCovers),
        isLoading,
        errorMessage,
        activeTrackPath,
        isAudioPlaying,
        isAdaptiveBg,
        adaptiveBgPanelBlur,
        adaptiveBgThemeOverlay,
      );
}
