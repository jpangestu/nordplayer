import 'package:flutter/foundation.dart';
import 'package:nordplayer/domain/models/models.dart';

/// Immutable UI state representing the Artists overview screen.
class const ArtistsUiState({
  final List<Artist> artists = const [],
  final bool isLoading = true,
  final String? errorMessage,
  final bool isAdaptiveBg = false,
  final double adaptiveBgPanelBlur = 20.0,
  final double adaptiveBgThemeOverlay = 0.5,
}) {
  /// Whether artists have finished loading and the collection is empty.
  bool get isEmpty => !isLoading && artists.isEmpty;

  ArtistsUiState copyWith({
    List<Artist>? artists,
    bool? isLoading,
    String? Function()? errorMessage,
    bool? isAdaptiveBg,
    double? adaptiveBgPanelBlur,
    double? adaptiveBgThemeOverlay,
  }) {
    return ArtistsUiState(
      artists: artists ?? this.artists,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      isAdaptiveBg: isAdaptiveBg ?? this.isAdaptiveBg,
      adaptiveBgPanelBlur: adaptiveBgPanelBlur ?? this.adaptiveBgPanelBlur,
      adaptiveBgThemeOverlay: adaptiveBgThemeOverlay ?? this.adaptiveBgThemeOverlay,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ArtistsUiState &&
          runtimeType == other.runtimeType &&
          listEquals(artists, other.artists) &&
          isLoading == other.isLoading &&
          errorMessage == other.errorMessage &&
          isAdaptiveBg == other.isAdaptiveBg &&
          adaptiveBgPanelBlur == other.adaptiveBgPanelBlur &&
          adaptiveBgThemeOverlay == other.adaptiveBgThemeOverlay;

  @override
  int get hashCode => Object.hash(
        Object.hashAll(artists),
        isLoading,
        errorMessage,
        isAdaptiveBg,
        adaptiveBgPanelBlur,
        adaptiveBgThemeOverlay,
      );
}
