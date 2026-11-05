import 'dart:ui';

import 'app_theme.dart';

final graphiteTheme = AppTheme(id: 1, name: 'Graphite', dark: graphiteDarkPalette);

final graphiteDarkPalette = ColorPalette(
  brightness: Brightness.dark,
  primary: const Color(0xFF7491AE),
  secondary: const Color(0xFFA0AAB2),
  surface: const Color(0xFF14161A),
  surfaceContainer: const Color(0xFF1E2227),
  surfaceContainerHigh: const Color(0xFF262A31),
  text: const Color(0xFFE0E3E8),
  textMuted: const Color(0xFFB3B6BA),
  border: const Color(0xFF3A414A),
  outline: const Color(0xFF636D7A),
  success: const Color(0xFF81C784),
  warning: const Color(0xFFE6C047),
  error: const Color(0xFFE57373),
  info: const Color(0xFF5AA3DD),
);
