import 'package:flutter/material.dart';
import 'package:nordplayer/theming/theme_builder.dart';

class AdaptiveColorScheme implements AppColorScheme {
  @override
  final Brightness brightness;

  @override
  final Color primary;
  @override
  final Color onPrimary;

  @override
  final Color secondary;
  @override
  final Color onSecondary;

  @override
  final Color surfaceContainerLowest;
  @override
  final Color surface;
  @override
  final Color surfaceContainerLow;
  @override
  final Color surfaceContainer;
  @override
  final Color surfaceContainerHigh;
  @override
  final Color surfaceContainerHighest;

  @override
  final Color onSurface;
  @override
  final Color onSurfaceVariant;

  @override
  final Color outline;
  @override
  final Color outlineVariant;
  @override
  final Color error;
  @override
  final Color onError;

  @override
  final Color success;
  @override
  final Color onSuccess;

  @override
  final Color warning;
  @override
  final Color onWarning;

  @override
  final Color info;
  @override
  final Color onInfo;

  @override
  final Color general;
  @override
  final Color onGeneral;

  AdaptiveColorScheme._({
    required this.brightness,
    required this.primary,
    required this.onPrimary,
    required this.secondary,
    required this.onSecondary,
    required this.surfaceContainerLowest,
    required this.surface,
    required this.surfaceContainerLow,
    required this.surfaceContainer,
    required this.surfaceContainerHigh,
    required this.surfaceContainerHighest,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.outline,
    required this.outlineVariant,
    required this.error,
    required this.onError,
    required this.success,
    required this.onSuccess,
    required this.warning,
    required this.onWarning,
    required this.info,
    required this.onInfo,
    required this.general,
    required this.onGeneral,
  });

  factory AdaptiveColorScheme.fromColorScheme(ColorScheme colorScheme) {
    return AdaptiveColorScheme._(
      brightness: colorScheme.brightness,
      primary: colorScheme.primary,
      onPrimary: colorScheme.onPrimary,

      secondary: colorScheme.secondary,
      onSecondary: colorScheme.onSecondary,

      surface: colorScheme.surface,
      onSurface: colorScheme.onSurface,
      onSurfaceVariant: colorScheme.onSurfaceVariant,
      surfaceContainerLowest: colorScheme.surfaceContainerLowest,
      surfaceContainerLow: colorScheme.surfaceContainerLow,
      surfaceContainer: colorScheme.surfaceContainer,
      surfaceContainerHigh: colorScheme.surfaceContainerHigh,
      surfaceContainerHighest: colorScheme.surfaceContainerHighest,

      outline: colorScheme.outline,
      outlineVariant: colorScheme.outlineVariant,

      // Using nord color scheme
      error: const Color(0xFFBF616A),
      onError: const Color(0xFFd8dee9),
      success: const Color(0xFFA3BE8C),
      onSuccess: const Color(0xFFd8dee9),
      warning: const Color(0xFFEBCB8B),
      onWarning: const Color(0xFFd8dee9),
      info: const Color(0xFF6E8EB4),
      onInfo: const Color(0xFFd8dee9),
      general: const Color(0xFFD8DEE9),
      onGeneral: const Color(0xFF2E3440),
    );
  }
}
