import 'dart:ui';

import 'app_theme.dart';

/// Official Nord color palette (16 colors in 4 modular components).
/// Reference: https://www.nordtheme.com/docs/colors-and-palettes
abstract final class NordColors {
  // Polar Night
  static const nord0 = Color(0xFF2E3440);
  static const nord1 = Color(0xFF3B4252);
  static const nord2 = Color(0xFF434C5E);
  static const nord3 = Color(0xFF4C566A);

  // Snow Storm
  static const nord4 = Color(0xFFD8DEE9);
  static const nord5 = Color(0xFFE5E9F0);
  static const nord6 = Color(0xFFECEFF4);

  // Frost
  static const nord7 = Color(0xFF8FBCBB);
  static const nord8 = Color(0xFF88C0D0);
  static const nord9 = Color(0xFF81A1C1);
  static const nord10 = Color(0xFF5E81AC);

  // Aurora
  static const nord11 = Color(0xFFBF616A);
  static const nord12 = Color(0xFFD08770);
  static const nord13 = Color(0xFFEBCB8B);
  static const nord14 = Color(0xFFA3BE8C);
  static const nord15 = Color(0xFFB48EAD);
}

final nordTheme = AppTheme(id: 0, name: 'Nord', dark: nordDarkPalette, light: nordLightPalette);

final nordDarkPalette = ColorPalette(
  brightness: Brightness.dark,
  // Accents (Frost)
  primary: NordColors.nord8,
  secondary: NordColors.nord9,
  // Surfaces (Polar Night Ramp)
  surface: NordColors.nord0,
  surfaceContainer: NordColors.nord1,
  surfaceContainerHigh: NordColors.nord2,
  // Typography (Snow Storm)
  text: NordColors.nord6,
  textMuted: NordColors.nord4,
  // Borders & Outlines (Polar Night)
  border: NordColors.nord3,
  outline: NordColors.nord3,
  // Semantics (Aurora & Frost)
  success: NordColors.nord14,
  warning: NordColors.nord13,
  error: NordColors.nord11,
  info: NordColors.nord10,
);

final nordLightPalette = ColorPalette(
  brightness: Brightness.light,
  // Accents (Frost)
  primary: NordColors.nord10, // Deep arctic blue for high light-mode contrast
  secondary: NordColors.nord8,
  // Surfaces (Snow Storm Ramp)
  surface: NordColors.nord6, // Base light canvas
  surfaceContainer: NordColors.nord5, // Elevated panels / sidebars
  surfaceContainerHigh: NordColors.nord4, // Dialogs, popovers, elevated cards
  // Typography (Polar Night)
  text: NordColors.nord0, // Crisp dark text
  textMuted: NordColors.nord3, // Muted secondary text
  // Borders & Outlines (Snow Storm / Polar Night)
  border: NordColors.nord4, // Subtle dividers
  outline: NordColors.nord3, // Functional input / switch borders
  // Semantics (Aurora & Frost)
  success: NordColors.nord14,
  warning: NordColors.nord12, // Aurora orange for high visibility on light surfaces
  error: NordColors.nord11,
  info: NordColors.nord9,
);
