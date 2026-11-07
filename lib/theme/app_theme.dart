import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nordplayer/config/app_config.dart';
import 'package:nordplayer/theme/graphite.dart';
import 'package:nordplayer/theme/nord_theme.dart';

/// All available themes
final availableThemes = <AppTheme>[nordTheme, graphiteTheme];

/// Active ThemeDefinition based on user setting
final appThemeProvider = Provider<AppTheme>((ref) {
  final appConfig = ref.watch(appConfigProvider);
  final selectedTheme = ref.watch(appConfig.colorTheme.provider);

  return availableThemes.firstWhere(
    (theme) => theme.name.toLowerCase() == selectedTheme.toLowerCase(),
    orElse: () => nordTheme,
  );
});

class AppTheme({
  required final int id,
  required final String name,
  final ColorPalette? dark,
  final ColorPalette? light,
}) {
  this : assert(dark != null || light != null, 'Must provide at least one palette (light or dark)');

  bool get supportsDark => dark != null;
  bool get supportsLight => light != null;
  bool get isSingleMode => dark == null || light == null;

  /// Effective light theme.
  /// If no light palette exists, falls back safely to dark
  /// so the app never shows Flutter's default purple theme.
  ThemeData get lightTheme => (light ?? dark)!.toThemeData();

  /// Effective dark theme.
  /// If no dark palette exists, falls back safely to light.
  ThemeData get darkTheme => (dark ?? light)!.toThemeData();

  /// Resolves user's preferred ThemeMode against what this theme actually supports.
  ThemeMode resolveThemeMode(ThemeMode preferred) {
    if (dark != null && light == null) return ThemeMode.dark;
    if (light != null && dark == null) return ThemeMode.light;
    return preferred;
  }
}

class ColorPalette({
  required final Brightness brightness,
  // Accents
  required final Color primary, // Play button, active track, seekbar progress
  required final Color secondary, // Secondary highlights, chips
  // Surfaces (Material 3 Surface Elevation Ramp)
  required final Color surface, // App background / scaffold / base canvas
  final Color? surfaceContainerLow, // Section groups
  required final Color surfaceContainer, // Sidebar, bottom player bar, panels
  required final Color surfaceContainerHigh, // Menus, popovers, dialogs
  // Typography & Borders
  required final Color text, // Main text
  required final Color textMuted, // Secondary artist names, timestamps, subtitles
  required final Color border, // Dividers, panel outlines
  required final Color outline, // Search bar outlines, switch outlines
  // Semantics
  required final Color success,
  required final Color warning,
  required final Color error,
  required final Color info,
}) {}

@immutable
class const AppSemanticColors({
  required final Color success,
  required final Color warning,
  required final Color info,
  required final Color error,
}) extends ThemeExtension<AppSemanticColors> {
  @override
  AppSemanticColors copyWith({Color? success, Color? warning, Color? info, Color? error}) {
    return AppSemanticColors(
      success: success ?? this.success,
      warning: warning ?? this.warning,
      info: info ?? this.info,
      error: error ?? this.error,
    );
  }

  @override
  AppSemanticColors lerp(ThemeExtension<AppSemanticColors>? other, double t) {
    if (other is! AppSemanticColors) return this;
    return AppSemanticColors(
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      info: Color.lerp(info, other.info, t)!,
      error: Color.lerp(error, other.error, t)!,
    );
  }
}

extension ColorPaletteExtension on ColorPalette {
  /// Map color palette to material 3 ThemeData
  ThemeData toThemeData({String? fontFamily, List<String>? fontFallbacks}) {
    final isDark = brightness == Brightness.dark;

    // Build the Material 3 ColorScheme
    final colorScheme = ColorScheme(
      brightness: brightness,

      // Accents
      primary: primary,
      onPrimary: isDark ? surface : Colors.white,
      secondary: secondary,
      onSecondary: isDark ? surface : Colors.white,

      // Surface Elevation Ramp
      surface: surface,
      surfaceContainerLow: surfaceContainerLow ?? Color.lerp(surface, surfaceContainer, 0.5)!,
      surfaceContainer: surfaceContainer,
      surfaceContainerHigh: surfaceContainerHigh,

      // Typography
      onSurface: text,
      onSurfaceVariant: textMuted,

      // Outlines
      outline: outline,
      outlineVariant: border,

      // Errors
      error: error,
      onError: isDark ? surface : Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: fontFamily,
      fontFamilyFallback: fontFallbacks,
      scaffoldBackgroundColor: surface,

      // Register custom extensions
      extensions: [AppSemanticColors(success: success, warning: warning, info: info, error: error)],
    );
  }
}
