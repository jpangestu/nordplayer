import 'package:flutter/material.dart';

// Source: https://www.nordtheme.com/docs/colors-and-palettes
class NordColors {
  // --- POLAR NIGHT (Backgrounds) ---
  // "Used for background and area coloring."
  static const Color nord0 = Color(0xFF2E3440);

  // "Used for elevated, more prominent or focused UI elements like panels."
  static const Color nord1 = Color(0xFF3B4252);

  // "Used for active text editor line... and text highlighting."
  static const Color nord2 = Color(0xFF434C5E);

  // "Used for UI elements like indent- and wrap guide marker."
  static const Color nord3 = Color(0xFF4C566A);

  // --- SNOW STORM (Text) ---
  // "Used for UI elements like the text editor caret." (Muted Text)
  static const Color nord4 = Color(0xFFD8DEE9);

  // "Brighter shade... used for more subtle UI text elements."
  static const Color nord5 = Color(0xFFE5E9F0);

  // "Used for elevated UI text elements that require more visual attention." (Main Text)
  static const Color nord6 = Color(0xFFECEFF4);

  // --- FROST (Accents) ---
  // "Stand out and get more visual attention."
  static const Color nord7 = Color(0xFF8FBCBB); // Teal

  // "Primary accent color... used for primary UI elements."
  static const Color nord8 = Color(0xFF88C0D0); // Cyan (Primary)

  // "Secondary UI elements."
  static const Color nord9 = Color(0xFF81A1C1); // Blue (Secondary)

  // "Tertiary UI elements."
  static const Color nord10 = Color(0xFF5E81AC); // Dark Blue (Tertiary)

  // --- AURORA (States) ---
  static const Color nord11 = Color(0xFFBF616A); // Error
  static const Color nord12 = Color(0xFFD08770); // Danger/Annotation
  static const Color nord13 = Color(0xFFEBCB8B); // Warning
  static const Color nord14 = Color(0xFFA3BE8C); // Success
  static const Color nord15 = Color(0xFFB48EAD); // Uncommon
}

final ThemeData nordTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,

  // SCAFFOLD (The Base)
  // Guideline: Nord0 is for "background and area coloring".
  scaffoldBackgroundColor: NordColors.nord0,

  colorScheme: const ColorScheme(
    brightness: Brightness.dark,

    // --- PRIMARY ---
    // Guideline: Nord8 is "Primary accent color".
    primary: NordColors.nord8,
    onPrimary: NordColors.nord0, // Dark text on Cyan for readability
    // --- SECONDARY ---
    // Guideline: Nord9 is "Secondary UI elements".
    secondary: NordColors.nord9,
    onSecondary: NordColors.nord0,

    // --- TERTIARY ---
    // Guideline: Nord10 is "Tertiary UI elements".
    tertiary: NordColors.nord10,
    onTertiary: NordColors.nord6,

    // --- SURFACES ---
    // Surface: The "Sheet" of paper. Nord0 is base.
    surface: NordColors.nord0,
    onSurface: NordColors.nord6, // Main text (Nord6)
    // Surface Container: "Elevated" elements (Sidebars, Cards).
    // Guideline: Nord1 is for "panels, modals, and floating popups".
    surfaceContainer: NordColors.nord1,
    onSurfaceVariant: NordColors.nord4, // Muted text (Nord4)
    // Highlight/Active States
    // Guideline: Nord2 is for "active text... and text highlighting".
    secondaryContainer: NordColors.nord2,
    onSecondaryContainer: NordColors.nord8, // Text on active selection
    // --- ERRORS ---
    error: NordColors.nord11,
    onError: NordColors.nord6,
  ),

  appBarTheme: const AppBarTheme(
    backgroundColor: NordColors.nord0,
    foregroundColor: NordColors.nord6,
    elevation: 0,
  ),

  navigationRailTheme: const NavigationRailThemeData(
    backgroundColor: NordColors.nord1,
    indicatorColor: NordColors.nord2,

    selectedIconTheme: IconThemeData(color: NordColors.nord8),
    unselectedIconTheme: IconThemeData(color: NordColors.nord4),

    selectedLabelTextStyle: TextStyle(
      color: NordColors.nord8,
      fontWeight: FontWeight.bold,
    ),
    unselectedLabelTextStyle: TextStyle(color: NordColors.nord4),
  ),

  dividerTheme: const DividerThemeData(
    color: NordColors.nord2,
    thickness: 2,
    space: 2,
  ),

  sliderTheme: SliderThemeData(
    trackHeight: 5,
    trackShape: const RoundedRectSliderTrackShape(),
    activeTrackColor: NordColors.nord8,
    inactiveTrackColor: NordColors.nord3,
    secondaryActiveTrackColor: NordColors.nord8.withValues(alpha: 0.38),

    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
    thumbColor: NordColors.nord8,

    overlayShape: const RoundSliderOverlayShape(overlayRadius: 14.0),
    overlayColor: NordColors.nord8.withValues(alpha: 0.24),

    valueIndicatorColor: NordColors.nord3,
    valueIndicatorTextStyle: const TextStyle(
      color: NordColors.nord6,
    ),
  ),

  iconButtonTheme: IconButtonThemeData(
    style: ButtonStyle(
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected) ||
            states.contains(WidgetState.pressed)) {
          return NordColors.nord8;
        }
        if (states.contains(WidgetState.disabled)) {
          return NordColors.nord3;
        }
        return NordColors.nord4;
      }),

      overlayColor: WidgetStateProperty.all(
        NordColors.nord8.withValues(alpha: 0.12),
      ),
    ),
  ),

  tooltipTheme: TooltipThemeData(
    decoration: BoxDecoration(
      color: NordColors.nord3,
      borderRadius: BorderRadius.circular(4),
    ),

    textStyle: const TextStyle(
      color: NordColors.nord6,
      fontSize: 12,
      fontWeight: FontWeight.w500,
    ),
  ),

  cardTheme: CardThemeData(
    color: NordColors.nord1,
    shadowColor: Colors.black26,
    elevation: 4,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  ),
);
