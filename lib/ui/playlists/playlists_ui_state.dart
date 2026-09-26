import 'package:flutter/foundation.dart';
import 'package:nordplayer/domain/models/composite_models.dart';

/// Immutable UI state representing the Playlists overview screen.
class const PlaylistsUiState({
  final List<PlaylistWithDetails> playlists = const [],
  final bool isLoading = true,
  final String? errorMessage,
  final int? activePlaylistId,
  final bool isAudioPlaying = false,
  final List<String> activePlaylistAlbumArt = const [],
  final bool isAdaptiveBg = false,
  final double adaptiveBgPanelBlur = 20.0,
  final double adaptiveBgThemeOverlay = 0.5,
}) {
  /// Whether playlists have finished loading and the collection is empty.
  bool get isEmpty => !isLoading && playlists.isEmpty;

  PlaylistsUiState copyWith({
    List<PlaylistWithDetails>? playlists,
    bool? isLoading,
    String? Function()? errorMessage,
    int? Function()? activePlaylistId,
    bool? isAudioPlaying,
    List<String>? activePlaylistAlbumArt,
    bool? isAdaptiveBg,
    double? adaptiveBgPanelBlur,
    double? adaptiveBgThemeOverlay,
  }) {
    return PlaylistsUiState(
      playlists: playlists ?? this.playlists,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      activePlaylistId: activePlaylistId != null ? activePlaylistId() : this.activePlaylistId,
      isAudioPlaying: isAudioPlaying ?? this.isAudioPlaying,
      activePlaylistAlbumArt: activePlaylistAlbumArt ?? this.activePlaylistAlbumArt,
      isAdaptiveBg: isAdaptiveBg ?? this.isAdaptiveBg,
      adaptiveBgPanelBlur: adaptiveBgPanelBlur ?? this.adaptiveBgPanelBlur,
      adaptiveBgThemeOverlay: adaptiveBgThemeOverlay ?? this.adaptiveBgThemeOverlay,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlaylistsUiState &&
          runtimeType == other.runtimeType &&
          listEquals(playlists, other.playlists) &&
          isLoading == other.isLoading &&
          errorMessage == other.errorMessage &&
          activePlaylistId == other.activePlaylistId &&
          isAudioPlaying == other.isAudioPlaying &&
          listEquals(activePlaylistAlbumArt, other.activePlaylistAlbumArt) &&
          isAdaptiveBg == other.isAdaptiveBg &&
          adaptiveBgPanelBlur == other.adaptiveBgPanelBlur &&
          adaptiveBgThemeOverlay == other.adaptiveBgThemeOverlay;

  @override
  int get hashCode => Object.hash(
    Object.hashAll(playlists),
    isLoading,
    errorMessage,
    activePlaylistId,
    isAudioPlaying,
    Object.hashAll(activePlaylistAlbumArt),
    isAdaptiveBg,
    adaptiveBgPanelBlur,
    adaptiveBgThemeOverlay,
  );
}
