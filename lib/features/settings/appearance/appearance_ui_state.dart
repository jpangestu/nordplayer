import 'package:flutter/material.dart';

/// Immutable UI state representing the visual theming and appearance configuration.
class const AppearanceUiState({
  final String theme = 'nord',
  final Brightness themeBrightness = Brightness.dark,
  final String iconSet = 'lucide',
  final bool adaptiveBg = false,
  final BoxFit adaptiveBgAlbumFit = BoxFit.cover,
  final double adaptiveBgAlbumBlur = 20.0,
  final double adaptiveBgPanelBlur = 20.0,
  final double adaptiveBgThemeOverlay = 0.5,
  final String fontFamily = 'inter',
  final double textScale = 1.0,
}) {
  AppearanceUiState copyWith({
    String? theme,
    Brightness? themeBrightness,
    String? iconSet,
    bool? adaptiveBg,
    BoxFit? adaptiveBgAlbumFit,
    double? adaptiveBgAlbumBlur,
    double? adaptiveBgPanelBlur,
    double? adaptiveBgThemeOverlay,
    String? fontFamily,
    double? textScale,
  }) {
    return AppearanceUiState(
      theme: theme ?? this.theme,
      themeBrightness: themeBrightness ?? this.themeBrightness,
      iconSet: iconSet ?? this.iconSet,
      adaptiveBg: adaptiveBg ?? this.adaptiveBg,
      adaptiveBgAlbumFit: adaptiveBgAlbumFit ?? this.adaptiveBgAlbumFit,
      adaptiveBgAlbumBlur: adaptiveBgAlbumBlur ?? this.adaptiveBgAlbumBlur,
      adaptiveBgPanelBlur: adaptiveBgPanelBlur ?? this.adaptiveBgPanelBlur,
      adaptiveBgThemeOverlay: adaptiveBgThemeOverlay ?? this.adaptiveBgThemeOverlay,
      fontFamily: fontFamily ?? this.fontFamily,
      textScale: textScale ?? this.textScale,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppearanceUiState &&
          runtimeType == other.runtimeType &&
          theme == other.theme &&
          themeBrightness == other.themeBrightness &&
          iconSet == other.iconSet &&
          adaptiveBg == other.adaptiveBg &&
          adaptiveBgAlbumFit == other.adaptiveBgAlbumFit &&
          adaptiveBgAlbumBlur == other.adaptiveBgAlbumBlur &&
          adaptiveBgPanelBlur == other.adaptiveBgPanelBlur &&
          adaptiveBgThemeOverlay == other.adaptiveBgThemeOverlay &&
          fontFamily == other.fontFamily &&
          textScale == other.textScale;

  @override
  int get hashCode => Object.hash(
        theme,
        themeBrightness,
        iconSet,
        adaptiveBg,
        adaptiveBgAlbumFit,
        adaptiveBgAlbumBlur,
        adaptiveBgPanelBlur,
        adaptiveBgThemeOverlay,
        fontFamily,
        textScale,
      );

  @override
  String toString() =>
      'AppearanceUiState(theme: $theme, brightness: $themeBrightness, iconSet: $iconSet, adaptiveBg: $adaptiveBg)';
}
