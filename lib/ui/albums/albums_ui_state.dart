import 'package:flutter/foundation.dart';
import 'package:nordplayer/domain/models/album.dart';

/// Immutable UI state representing the Albums overview screen.
class const AlbumsUiState({
  final List<Album> albums = const [],
  final bool isLoading = true,
  final String? errorMessage,
  final bool isAdaptiveBg = false,
  final double adaptiveBgPanelBlur = 20.0,
  final double adaptiveBgThemeOverlay = 0.5,
}) {
  /// Whether albums have finished loading and the collection is empty.
  bool get isEmpty => !isLoading && albums.isEmpty;

  AlbumsUiState copyWith({
    List<Album>? albums,
    bool? isLoading,
    String? Function()? errorMessage,
    bool? isAdaptiveBg,
    double? adaptiveBgPanelBlur,
    double? adaptiveBgThemeOverlay,
  }) {
    return AlbumsUiState(
      albums: albums ?? this.albums,
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
      other is AlbumsUiState &&
          runtimeType == other.runtimeType &&
          listEquals(albums, other.albums) &&
          isLoading == other.isLoading &&
          errorMessage == other.errorMessage &&
          isAdaptiveBg == other.isAdaptiveBg &&
          adaptiveBgPanelBlur == other.adaptiveBgPanelBlur &&
          adaptiveBgThemeOverlay == other.adaptiveBgThemeOverlay;

  @override
  int get hashCode => Object.hash(
    Object.hashAll(albums),
    isLoading,
    errorMessage,
    isAdaptiveBg,
    adaptiveBgPanelBlur,
    adaptiveBgThemeOverlay,
  );
}
