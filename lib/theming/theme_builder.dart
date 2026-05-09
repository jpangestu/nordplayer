import 'package:flutter/material.dart';
import 'package:nordplayer/theming/theme-extension/nord_sidebar_theme.dart';
import 'package:nordplayer/theming/theme-extension/nord_snackbar_theme.dart';

abstract class AppColorScheme {
  // Base theme: dark or light
  Brightness get brightness;

  // Pimary
  Color get primary;
  Color get onPrimary;
  // Color get primaryContainer;
  // Color get onPrimaryContainer;

  // Secondary
  Color get secondary;
  Color get onSecondary;
  // Color get secondaryContainer;
  // Color get onSecondaryContainer;

  // Tertiary
  // Color? get tertiary;
  // Color? get onTertiary;
  // Color? get tertiaryContainer;
  // Color? get onTertiaryContainer;

  // Surface
  Color get surfaceContainerLowest;
  Color get surface;
  Color get surfaceContainerLow;
  Color get surfaceContainer;
  Color get surfaceContainerHigh;
  Color get surfaceContainerHighest;

  // Typography
  Color get onSurface;
  Color get onSurfaceVariant;

  // Outline
  Color get outline;
  Color get outlineVariant;

  // States
  Color get error;
  Color get onError;

  Color get success;
  Color get onSuccess;

  Color get warning;
  Color get onWarning;

  Color get info;
  Color get onInfo;

  Color get general;
  Color get onGeneral;
}

ThemeData buildTheme({
  // Nullable fontFamily for system font (null == system font)
  required String? fontFamily,
  required List<String>? fontFamilyFallback,
  required AppColorScheme nordColorScheme,
}) {
  return ThemeData(
    useMaterial3: true,
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,

    colorScheme: ColorScheme(
      brightness: nordColorScheme.brightness,

      primary: nordColorScheme.primary,
      onPrimary: nordColorScheme.onPrimary,

      secondary: nordColorScheme.secondary,
      onSecondary: nordColorScheme.onSecondary,

      surface: nordColorScheme.surface,
      onSurface: nordColorScheme.onSurface,
      onSurfaceVariant: nordColorScheme.onSurfaceVariant,
      surfaceContainerLowest: nordColorScheme.surfaceContainerLowest,
      surfaceContainerLow: nordColorScheme.surfaceContainerLow,
      surfaceContainer: nordColorScheme.surfaceContainer,
      surfaceContainerHigh: nordColorScheme.surfaceContainerHigh,
      surfaceContainerHighest: nordColorScheme.surfaceContainerHighest,

      outline: nordColorScheme.outline,
      outlineVariant: nordColorScheme.outlineVariant,

      error: nordColorScheme.error,
      onError: nordColorScheme.onError,
    ),

    extensions: <ThemeExtension<dynamic>>[
      NordSidebarTheme(
        backgroundColor: nordColorScheme.surfaceContainer,
        itemBackgroundColor: WidgetStateProperty.resolveWith((states) {
          // Selected State
          if (states.contains(WidgetState.selected)) {
            // Blend the M3 State Layers over the active container color
            if (states.contains(WidgetState.pressed) || states.contains(WidgetState.focused)) {
              return nordColorScheme.primary.withValues(alpha: 0.1);
            }
            if (states.contains(WidgetState.hovered)) {
              return nordColorScheme.primary.withValues(alpha: 0.08);
            }

            return nordColorScheme.primary.withValues(alpha: 0.1);
          }

          // Unselected State
          final stateLayerColor = nordColorScheme.onSurface;

          if (states.contains(WidgetState.pressed) || states.contains(WidgetState.focused)) {
            return stateLayerColor.withValues(alpha: 0.1);
          }
          if (states.contains(WidgetState.hovered)) {
            return stateLayerColor.withValues(alpha: 0.08);
          }

          return Colors.transparent;
        }),
        itemForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return nordColorScheme.onSurface.withValues(alpha: 0.38);
          }
          if (states.contains(WidgetState.selected)) {
            return nordColorScheme.primary;
          }
          if (states.contains(WidgetState.pressed) ||
              states.contains(WidgetState.focused) ||
              states.contains(WidgetState.hovered)) {
            return nordColorScheme.onSurface;
          }
          return nordColorScheme.onSurface;
        }),
      ),

      NordSnackBarTheme(
        generalColor: nordColorScheme.general,
        infoColor: nordColorScheme.info,
        successColor: nordColorScheme.success,
        warningColor: nordColorScheme.warning,
        errorColor: nordColorScheme.error,
      ),
    ],

    // Guideline: https://m3.material.io/styles/typography/type-scale-tokens
    textTheme: TextTheme(
      displayLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: 57,
        fontWeight: .w400,
        height: 64 / 57, // 'Line height 64pt' relative to '57pt' font size
        letterSpacing: 0, // letter spacing = tracking
        color: nordColorScheme.onSurface,
        fontVariations: const <FontVariation>[
          FontVariation('wght', 400), // Weight
          FontVariation('wdth', 100), // Width
          FontVariation('opsz', 57), // Optical Size (matches font size)
          FontVariation('GRAD', 0), // Grade
          FontVariation('slnt', 0), // Slant
          FontVariation('CRSV', 0), // Cursive
          FontVariation('ROND', 0), // Roundness
          FontVariation('FILL', 0), // Fill
          FontVariation('HEXP', 0), // Horizontal Expansion
        ],
      ),
      displayMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: 45,
        fontWeight: .w400,
        height: 52 / 45,
        letterSpacing: 0,
        color: nordColorScheme.onSurface,
        fontVariations: const <FontVariation>[
          FontVariation('wght', 400),
          FontVariation('wdth', 100),
          FontVariation('opsz', 45),
          FontVariation('GRAD', 0),
          FontVariation('slnt', 0),
          FontVariation('CRSV', 0),
          FontVariation('ROND', 0),
          FontVariation('FILL', 0),
          FontVariation('HEXP', 0),
        ],
      ),
      displaySmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: 36,
        fontWeight: .w400,
        height: 44 / 36,
        letterSpacing: 0,
        color: nordColorScheme.onSurface,
        fontVariations: const <FontVariation>[
          FontVariation('wght', 400),
          FontVariation('wdth', 100),
          FontVariation('opsz', 36),
          FontVariation('GRAD', 0),
          FontVariation('slnt', 0),
          FontVariation('CRSV', 0),
          FontVariation('ROND', 0),
          FontVariation('FILL', 0),
          FontVariation('HEXP', 0),
        ],
      ),

      headlineLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: 32,
        fontWeight: .w500, // default:400
        height: 40 / 32,
        letterSpacing: 0,
        color: nordColorScheme.onSurface,
        fontVariations: const <FontVariation>[
          FontVariation('wght', 500), // default:400
          FontVariation('wdth', 100),
          FontVariation('opsz', 32),
          FontVariation('GRAD', 0),
          FontVariation('slnt', 0),
          FontVariation('CRSV', 0),
          FontVariation('ROND', 0),
          FontVariation('FILL', 0),
          FontVariation('HEXP', 0),
        ],
      ),
      headlineMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: 28,
        fontWeight: .w500, // default:400
        height: 36 / 28,
        letterSpacing: 0,
        color: nordColorScheme.onSurface,
        fontVariations: const <FontVariation>[
          FontVariation('wght', 500),
          FontVariation('wdth', 100),
          FontVariation('opsz', 28),
          FontVariation('GRAD', 0),
          FontVariation('slnt', 0),
          FontVariation('CRSV', 0),
          FontVariation('ROND', 0),
          FontVariation('FILL', 0),
          FontVariation('HEXP', 0),
        ],
      ),
      headlineSmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: 24,
        fontWeight: .w500, // default:400
        height: 32 / 24,
        letterSpacing: 0,
        color: nordColorScheme.onSurface,
        fontVariations: const <FontVariation>[
          FontVariation('wght', 500),
          FontVariation('wdth', 100),
          FontVariation('opsz', 24),
          FontVariation('GRAD', 0),
          FontVariation('slnt', 0),
          FontVariation('CRSV', 0),
          FontVariation('ROND', 0),
          FontVariation('FILL', 0),
          FontVariation('HEXP', 0),
        ],
      ),

      titleLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: 20, // default: 22
        fontWeight: .w500, // default:400
        height: 28 / 20,
        letterSpacing: 0,
        color: nordColorScheme.onSurface,
        fontVariations: const <FontVariation>[
          FontVariation('wght', 500),
          FontVariation('wdth', 100),
          FontVariation('opsz', 22),
          FontVariation('GRAD', 0),
          FontVariation('slnt', 0),
          FontVariation('CRSV', 0),
          FontVariation('ROND', 0),
          FontVariation('FILL', 0),
          FontVariation('HEXP', 0),
        ],
      ),
      titleMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: 16,
        fontWeight: .w500,
        height: 24 / 16,
        letterSpacing: 0,
        color: nordColorScheme.onSurface,
        fontVariations: const <FontVariation>[
          FontVariation('wght', 500),
          FontVariation('wdth', 100),
          FontVariation('opsz', 16),
          FontVariation('GRAD', 0),
          FontVariation('slnt', 0),
          FontVariation('CRSV', 0),
          FontVariation('ROND', 0),
          FontVariation('FILL', 0),
          FontVariation('HEXP', 0),
        ],
      ),
      titleSmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: 14,
        fontWeight: .w500,
        height: 20 / 14,
        letterSpacing: 0,
        color: nordColorScheme.onSurface,
        fontVariations: const <FontVariation>[
          FontVariation('wght', 500),
          FontVariation('wdth', 100),
          FontVariation('opsz', 14),
          FontVariation('GRAD', 0),
          FontVariation('slnt', 0),
          FontVariation('CRSV', 0),
          FontVariation('ROND', 0),
          FontVariation('FILL', 0),
          FontVariation('HEXP', 0),
        ],
      ),

      bodyLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: 16,
        fontWeight: .w400,
        height: 24 / 16,
        letterSpacing: 0,
        color: nordColorScheme.onSurface,
        fontVariations: const <FontVariation>[
          FontVariation('wght', 400),
          FontVariation('wdth', 100),
          FontVariation('opsz', 16),
          FontVariation('GRAD', 0),
          FontVariation('slnt', 0),
          FontVariation('CRSV', 0),
          FontVariation('ROND', 0),
          FontVariation('FILL', 0),
          FontVariation('HEXP', 0),
        ],
      ),
      bodyMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: 14,
        fontWeight: .w400,
        height: 20 / 14,
        letterSpacing: 0,
        color: nordColorScheme.onSurface,
        fontVariations: const <FontVariation>[
          FontVariation('wght', 400),
          FontVariation('wdth', 100),
          FontVariation('opsz', 14),
          FontVariation('GRAD', 0),
          FontVariation('slnt', 0),
          FontVariation('CRSV', 0),
          FontVariation('ROND', 0),
          FontVariation('FILL', 0),
          FontVariation('HEXP', 0),
        ],
      ),
      bodySmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: 12,
        fontWeight: .w400,
        height: 16 / 12,
        letterSpacing: 0.1,
        color: nordColorScheme.onSurface,
        fontVariations: const <FontVariation>[
          FontVariation('wght', 400),
          FontVariation('wdth', 100),
          FontVariation('opsz', 12),
          FontVariation('GRAD', 0),
          FontVariation('slnt', 0),
          FontVariation('CRSV', 0),
          FontVariation('ROND', 0),
          FontVariation('FILL', 0),
          FontVariation('HEXP', 0),
        ],
      ),

      // Font weight prominent: 700
      labelLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: 14,
        fontWeight: .w500,
        height: 20 / 14,
        letterSpacing: 0,
        color: nordColorScheme.onSurface,
        fontVariations: const <FontVariation>[
          FontVariation('wght', 500),
          FontVariation('wdth', 100),
          FontVariation('opsz', 14),
          FontVariation('GRAD', 0),
          FontVariation('slnt', 0),
          FontVariation('CRSV', 0),
          FontVariation('ROND', 0),
          FontVariation('FILL', 0),
          FontVariation('HEXP', 0),
        ],
      ),

      // Font weight prominent: 700
      labelMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: 12,
        fontWeight: .w500,
        height: 20 / 12,
        letterSpacing: 0.1,
        color: nordColorScheme.onSurface,
        fontVariations: const <FontVariation>[
          FontVariation('wght', 500),
          FontVariation('wdth', 100),
          FontVariation('opsz', 12),
          FontVariation('GRAD', 0),
          FontVariation('slnt', 0),
          FontVariation('CRSV', 0),
          FontVariation('ROND', 0),
          FontVariation('FILL', 0),
          FontVariation('HEXP', 0),
        ],
      ),
      labelSmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: 11,
        fontWeight: .w500,
        height: 16 / 11,
        letterSpacing: 0.1,
        color: nordColorScheme.onSurface,
        fontVariations: const <FontVariation>[
          FontVariation('wght', 500),
          FontVariation('wdth', 100),
          FontVariation('opsz', 16),
          FontVariation('GRAD', 0),
          FontVariation('slnt', 0),
          FontVariation('CRSV', 0),
          FontVariation('ROND', 0),
          FontVariation('FILL', 0),
          FontVariation('HEXP', 0),
        ],
      ),
    ),
  );
}
