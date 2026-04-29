import 'package:flutter/material.dart';
import 'package:nordplayer/theming/theme-extension/sidebar_theme.dart';

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

ThemeData buildNordTheme({String? fontFamily}) {
  // Resolve the font (null means it will use the default system font)
  final String? resolvedFont = (fontFamily == null || fontFamily == 'System' || fontFamily.isEmpty) ? null : fontFamily;

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,

    // SCAFFOLD (The Base)
    // Guideline: Nord0 is for "background and area coloring".
    scaffoldBackgroundColor: NordColors.nord0,

    colorScheme: ColorScheme(
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
      // Surface Container: "Elevated" elements (Sidebars, Cards).
      // Guideline: Nord1 is for "panels, modals, and floating popups".
      surfaceContainerLow: Color.lerp(NordColors.nord1, NordColors.nord0, 0.5), // Slight elevation
      surfaceContainer: NordColors.nord1, // Standard elevation (Cards, Dialogs)
      surfaceContainerHigh: Color.lerp(NordColors.nord1, NordColors.nord2, 0.5), // Higher elevation (Hover states)
      onSurface: NordColors.nord6, // Main text (Nord6)

      onSurfaceVariant: NordColors.nord4, // Muted text (Nord4)
      // Highlight/Active States
      // Guideline: Nord2 is for "active text... and text highlighting".
      secondaryContainer: NordColors.nord2,
      onSecondaryContainer: NordColors.nord8, // Text on active selection
      // --- ERRORS ---
      error: NordColors.nord11,
      onError: NordColors.nord6,
    ),

    extensions: <ThemeExtension<dynamic>>[
      SidebarTheme(
        backgroundColor: NordColors.nord1,
        itemBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            // When actively clicking down (highlightColor).
            // A slightly deeper or more distinct color than hover.
            return NordColors.nord3.withValues(alpha: 0.8);
          }
          if (states.contains(WidgetState.selected)) {
            // Highlighting the active menu item
            return NordColors.nord2;
          }
          if (states.contains(WidgetState.focused)) {
            // Keyboard navigation focus.
            // Often similar to hover, but slightly more opaque to be obvious.
            return NordColors.nord3.withValues(alpha: 0.5);
          }
          if (states.contains(WidgetState.hovered)) {
            // A subtle highlight when the mouse is over it
            return NordColors.nord3.withValues(alpha: 0.3);
          }
          // Transparent when it's just sitting there normally
          return Colors.transparent;
        }),
        itemForegroundColor: WidgetStateProperty.resolveWith((states) {
          // Foreground colors usually don't need to change for pressed/focused,
          // they just need to stay bright while the background changes behind them.
          if (states.contains(WidgetState.selected)) {
            // Bright cyan when selected
            return NordColors.nord8;
          }
          if (states.contains(WidgetState.pressed) ||
              states.contains(WidgetState.focused) ||
              states.contains(WidgetState.hovered)) {
            // Bright white when interacting
            return NordColors.nord6;
          }
          // Muted text when unselected
          return NordColors.nord4;
        }),
      ),
    ],

    appBarTheme: const AppBarTheme(backgroundColor: NordColors.nord0, foregroundColor: NordColors.nord6, elevation: 0),

    dividerTheme: const DividerThemeData(color: NordColors.nord2, thickness: 2, space: 2),

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
      valueIndicatorTextStyle: TextStyle(fontFamily: resolvedFont, color: NordColors.nord6),
    ),

    iconButtonTheme: IconButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected) || states.contains(WidgetState.pressed)) {
            return NordColors.nord8;
          }
          if (states.contains(WidgetState.disabled)) {
            return NordColors.nord3;
          }
          return NordColors.nord4;
        }),

        overlayColor: WidgetStateProperty.all(NordColors.nord8.withValues(alpha: 0.12)),
      ),
    ),

    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(color: NordColors.nord3, borderRadius: BorderRadius.circular(4)),

      textStyle: TextStyle(
        fontFamily: resolvedFont,
        color: NordColors.nord6,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    ),

    dropdownMenuTheme: DropdownMenuThemeData(
      menuStyle: const MenuStyle(
        backgroundColor: WidgetStatePropertyAll(NordColors.nord3),
        side: WidgetStatePropertyAll(BorderSide(color: NordColors.nord2, width: 2)),
      ),

      textStyle: TextStyle(fontFamily: resolvedFont, color: NordColors.nord6),

      // The input box (not expanded)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: NordColors.nord3,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: NordColors.nord8, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: NordColors.nord8, width: 2),
        ),

        iconColor: NordColors.nord6,
        // The arrow
        suffixIconColor: NordColors.nord6,
      ),
    ),

    listTileTheme: ListTileThemeData(
      tileColor: Colors.transparent,
      selectedTileColor: NordColors.nord2,
      iconColor: NordColors.nord4,
      selectedColor: NordColors.nord8,
      titleTextStyle: TextStyle(
        fontFamily: resolvedFont,
        inherit: false,
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: NordColors.nord6,
        height: 1.4,
        letterSpacing: 0.15,
      ),
      subtitleTextStyle: TextStyle(
        fontFamily: resolvedFont,
        inherit: false,
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: Color.lerp(NordColors.nord3, NordColors.nord4, 0.8),
        height: 1.4,
        letterSpacing: 0.25,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      visualDensity: VisualDensity.standard,
    ),

    textTheme: TextTheme(
      // --- DISPLAY (Used sparingly for hero numbers or large branding) ---
      displayLarge: TextStyle(
        fontFamily: resolvedFont,
        fontSize: 48,
        fontWeight: FontWeight.bold,
        color: NordColors.nord6,
      ),
      displayMedium: TextStyle(
        fontFamily: resolvedFont,
        fontSize: 36,
        fontWeight: FontWeight.bold,
        color: NordColors.nord6,
      ),

      // --- HEADLINE (Main Page Titles, e.g., "Settings") ---
      headlineLarge: TextStyle(
        fontFamily: resolvedFont,
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: NordColors.nord6,
      ),
      headlineMedium: TextStyle(
        fontFamily: resolvedFont,
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: NordColors.nord6,
      ),

      // --- TITLE (Section Headers & List Labels) ---
      titleLarge: TextStyle(
        fontFamily: resolvedFont,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: NordColors.nord6,
      ),
      titleMedium: TextStyle(
        fontFamily: resolvedFont,
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: NordColors.nord5,
      ),
      titleSmall: TextStyle(
        fontFamily: resolvedFont,
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: NordColors.nord5,
      ),

      // --- BODY (Reading text and descriptions) ---
      bodyLarge: TextStyle(
        fontFamily: resolvedFont,
        fontSize: 15,
        fontWeight: FontWeight.normal,
        color: NordColors.nord4,
      ),
      bodyMedium: TextStyle(
        fontFamily: resolvedFont,
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: NordColors.nord4,
      ),
      bodySmall: TextStyle(
        fontFamily: resolvedFont,
        fontSize: 12, // Muted subtext
        fontWeight: FontWeight.normal,
        color: NordColors.nord4,
      ),

      // --- LABEL (Buttons, chips, and small captions) ---
      labelLarge: TextStyle(
        fontFamily: resolvedFont,
        fontSize: 13, // Compact button text
        fontWeight: FontWeight.w600,
        color: NordColors.nord6,
      ),
      labelSmall: TextStyle(
        fontFamily: resolvedFont,
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: NordColors.nord4,
      ),
    ),
  );
}
