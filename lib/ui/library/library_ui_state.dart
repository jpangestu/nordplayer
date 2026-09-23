import 'package:flutter/foundation.dart';
import 'package:nordplayer/config/app_config.dart';
import 'package:nordplayer/domain/models/models.dart';

/// Immutable UI State snapshot for the Library overview screen.
class const LibraryUiState({
  final LibraryStats stats = const LibraryStats.empty(),
  final List<LibrarySectionConfig> sections = const [],
  final List<Album> randomAlbums = const [],
  final List<TrackWithArtists> sampleTracks = const [],
  final List<TrackWithArtists> recentlyAddedTracks = const [],
  final bool isLoading = true,
  final String? errorMessage,
  final bool isRecentlyAddedExpanded = false,
  final bool isAdaptiveBg = false,
  final double adaptiveBgPanelBlur = 20.0,
  final double adaptiveBgThemeOverlay = 0.5,
}) {
  /// Whether the library has finished loading and contains zero tracks.
  bool get isEmpty => !isLoading && stats.trackCount == 0;

  /// Total count of indexed tracks in the library.
  int get trackCount => stats.trackCount;

  LibraryUiState copyWith({
    LibraryStats? stats,
    List<LibrarySectionConfig>? sections,
    List<Album>? randomAlbums,
    List<TrackWithArtists>? sampleTracks,
    List<TrackWithArtists>? recentlyAddedTracks,
    bool? isLoading,
    String? Function()? errorMessage,
    bool? isRecentlyAddedExpanded,
    bool? isAdaptiveBg,
    double? adaptiveBgPanelBlur,
    double? adaptiveBgThemeOverlay,
  }) {
    return LibraryUiState(
      stats: stats ?? this.stats,
      sections: sections ?? this.sections,
      randomAlbums: randomAlbums ?? this.randomAlbums,
      sampleTracks: sampleTracks ?? this.sampleTracks,
      recentlyAddedTracks: recentlyAddedTracks ?? this.recentlyAddedTracks,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      isRecentlyAddedExpanded: isRecentlyAddedExpanded ?? this.isRecentlyAddedExpanded,
      isAdaptiveBg: isAdaptiveBg ?? this.isAdaptiveBg,
      adaptiveBgPanelBlur: adaptiveBgPanelBlur ?? this.adaptiveBgPanelBlur,
      adaptiveBgThemeOverlay: adaptiveBgThemeOverlay ?? this.adaptiveBgThemeOverlay,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LibraryUiState &&
          runtimeType == other.runtimeType &&
          stats == other.stats &&
          listEquals(sections, other.sections) &&
          listEquals(randomAlbums, other.randomAlbums) &&
          listEquals(sampleTracks, other.sampleTracks) &&
          listEquals(recentlyAddedTracks, other.recentlyAddedTracks) &&
          isLoading == other.isLoading &&
          errorMessage == other.errorMessage &&
          isRecentlyAddedExpanded == other.isRecentlyAddedExpanded &&
          isAdaptiveBg == other.isAdaptiveBg &&
          adaptiveBgPanelBlur == other.adaptiveBgPanelBlur &&
          adaptiveBgThemeOverlay == other.adaptiveBgThemeOverlay;

  @override
  int get hashCode => Object.hash(
        stats,
        Object.hashAll(sections),
        Object.hashAll(randomAlbums),
        Object.hashAll(sampleTracks),
        Object.hashAll(recentlyAddedTracks),
        isLoading,
        errorMessage,
        isRecentlyAddedExpanded,
        isAdaptiveBg,
        adaptiveBgPanelBlur,
        adaptiveBgThemeOverlay,
      );
}
