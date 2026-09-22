import 'package:flutter/foundation.dart';
import 'package:nordplayer/core/models/table_column_config.dart';
import 'package:nordplayer/domain/models/models.dart';

/// Available sorting criteria for album tracks.
enum AlbumTrackSort {
  trackNumber('Track Number'),
  title('Title'),
  duration('Duration');

  final String label;
  const AlbumTrackSort(this.label);
}

/// Sort ordering direction.
enum SortOrder {
  ascending('Ascending'),
  descending('Descending');

  final String label;
  const SortOrder(this.label);
}

/// Immutable UI state representing the Album Detail screen.
class const AlbumDetailUiState({
  final AlbumWithTracks? rawAlbumWithTracks,
  final AlbumWithTracks? albumWithTracks,
  final AlbumTrackSort sortCriteria = AlbumTrackSort.trackNumber,
  final SortOrder sortOrder = SortOrder.ascending,
  final bool showFavoritesOnly = false,
  final List<TableColumnConfig> columns = const [],
  final Set<int> selectedIndices = const {},
  final bool isLoading = true,
  final String? errorMessage,
  final String? activeTrackPath,
  final bool isAudioPlaying = false,
  final bool shouldShuffle = false,
  final bool isAdaptiveBg = false,
  final double adaptiveBgPanelBlur = 20.0,
  final double adaptiveBgThemeOverlay = 0.5,
}) {
  /// Whether the album has finished loading and contains no tracks.
  bool get isEmpty => !isLoading && (albumWithTracks == null || albumWithTracks!.tracks.isEmpty);

  /// Total count of tracks in this album view.
  int get trackCount => albumWithTracks?.tracks.length ?? 0;

  /// Total duration of all tracks in milliseconds.
  int get totalDurationMs => albumWithTracks?.tracksLengthMs ?? 0;

  AlbumDetailUiState copyWith({
    AlbumWithTracks? Function()? rawAlbumWithTracks,
    AlbumWithTracks? Function()? albumWithTracks,
    AlbumTrackSort? sortCriteria,
    SortOrder? sortOrder,
    bool? showFavoritesOnly,
    List<TableColumnConfig>? columns,
    Set<int>? selectedIndices,
    bool? isLoading,
    String? Function()? errorMessage,
    String? Function()? activeTrackPath,
    bool? isAudioPlaying,
    bool? shouldShuffle,
    bool? isAdaptiveBg,
    double? adaptiveBgPanelBlur,
    double? adaptiveBgThemeOverlay,
  }) {
    return AlbumDetailUiState(
      rawAlbumWithTracks: rawAlbumWithTracks != null ? rawAlbumWithTracks() : this.rawAlbumWithTracks,
      albumWithTracks: albumWithTracks != null ? albumWithTracks() : this.albumWithTracks,
      sortCriteria: sortCriteria ?? this.sortCriteria,
      sortOrder: sortOrder ?? this.sortOrder,
      showFavoritesOnly: showFavoritesOnly ?? this.showFavoritesOnly,
      columns: columns ?? this.columns,
      selectedIndices: selectedIndices ?? this.selectedIndices,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      activeTrackPath: activeTrackPath != null ? activeTrackPath() : this.activeTrackPath,
      isAudioPlaying: isAudioPlaying ?? this.isAudioPlaying,
      shouldShuffle: shouldShuffle ?? this.shouldShuffle,
      isAdaptiveBg: isAdaptiveBg ?? this.isAdaptiveBg,
      adaptiveBgPanelBlur: adaptiveBgPanelBlur ?? this.adaptiveBgPanelBlur,
      adaptiveBgThemeOverlay: adaptiveBgThemeOverlay ?? this.adaptiveBgThemeOverlay,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlbumDetailUiState &&
          runtimeType == other.runtimeType &&
          rawAlbumWithTracks == other.rawAlbumWithTracks &&
          albumWithTracks == other.albumWithTracks &&
          sortCriteria == other.sortCriteria &&
          sortOrder == other.sortOrder &&
          showFavoritesOnly == other.showFavoritesOnly &&
          listEquals(columns, other.columns) &&
          setEquals(selectedIndices, other.selectedIndices) &&
          isLoading == other.isLoading &&
          errorMessage == other.errorMessage &&
          activeTrackPath == other.activeTrackPath &&
          isAudioPlaying == other.isAudioPlaying &&
          shouldShuffle == other.shouldShuffle &&
          isAdaptiveBg == other.isAdaptiveBg &&
          adaptiveBgPanelBlur == other.adaptiveBgPanelBlur &&
          adaptiveBgThemeOverlay == other.adaptiveBgThemeOverlay;

  @override
  int get hashCode => Object.hash(
    rawAlbumWithTracks,
    albumWithTracks,
    sortCriteria,
    sortOrder,
    showFavoritesOnly,
    Object.hashAll(columns),
    Object.hashAll(selectedIndices),
    isLoading,
    errorMessage,
    activeTrackPath,
    isAudioPlaying,
    shouldShuffle,
    isAdaptiveBg,
    adaptiveBgPanelBlur,
    adaptiveBgThemeOverlay,
  );
}
