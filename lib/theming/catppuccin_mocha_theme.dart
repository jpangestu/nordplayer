import 'package:flutter/material.dart';
import 'package:nordplayer/theming/theme-extension/sidebar_theme.dart';

// Source: https://catppuccin.com/palette
class CatppuccinMochaColors {
  // --- BACKGROUNDS ---
  // "Base is the primary background color"
  static const Color base = Color(0xFF1e1e2e);

  // "Mantle is used for sidebars and slightly darker backgrounds"
  static const Color mantle = Color(0xFF181825);

  // "Crust is used for the deepest backgrounds, borders, or shadows"
  static const Color crust = Color(0xFF11111b);

  // --- SURFACES ---
  // "Used for elevated surfaces like panels, cards, and buttons"
  // use mantle as surface for now, fix this later
  static const Color surface0 = Color(0xFF181825);
  // static const Color surface0 = Color(0xFF313244);

  // "Used for hovered states or secondary elevations"
  static const Color surface1 = Color(0xFF45475a);

  // "Used for active states or tertiary elevations"
  static const Color surface2 = Color(0xFF585b70);

  // --- OVERLAYS & SUBTEXT (Muted/UI elements) ---
  static const Color overlay0 = Color(0xFF6c7086);
  static const Color overlay1 = Color(0xFF7f849c);
  static const Color overlay2 = Color(0xFF9399b2);

  // "Subtext is for secondary text, disabled text, or subtle hints"
  static const Color subtext0 = Color(0xFFa6adc8);
  static const Color subtext1 = Color(0xFFbac2de);

  // --- FOREGROUND ---
  // "Text is the primary text color"
  static const Color text = Color(0xFFcdd6f4);

  // --- ACCENTS ---
  // Catppuccin features a wide array of accents. Mauve is the signature primary color.
  static const Color mauve = Color(0xFFcba6f7); // Primary
  static const Color blue = Color(0xFF89b4fa); // Secondary
  static const Color lavender = Color(0xFFb4befe); // Tertiary
  static const Color sapphire = Color(0xFF74c7ec);
  static const Color teal = Color(0xFF94e2d5);

  // --- STATES ---
  static const Color red = Color(0xFFf38ba8); // Error/Danger
  static const Color peach = Color(0xFFfab387); // Warning
  static const Color green = Color(0xFFa6e3a1); // Success
}

ThemeData buildCatppuccinMochaTheme({String? fontFamily}) {
  final String? resolvedFont = (fontFamily == null || fontFamily == 'System' || fontFamily.isEmpty) ? null : fontFamily;

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,

    // SCAFFOLD (The Base)
    // Guideline: Base is the primary app background.
    scaffoldBackgroundColor: CatppuccinMochaColors.base,

    colorScheme: const ColorScheme(
      brightness: Brightness.dark,

      // --- PRIMARY ---
      // Guideline: Mauve is the signature Catppuccin accent.
      primary: CatppuccinMochaColors.mauve,
      onPrimary: CatppuccinMochaColors.crust, // Dark text on Mauve for readability
      // --- SECONDARY ---
      secondary: CatppuccinMochaColors.blue,
      onSecondary: CatppuccinMochaColors.crust,

      // --- TERTIARY ---
      tertiary: CatppuccinMochaColors.lavender,
      onTertiary: CatppuccinMochaColors.crust,

      // --- SURFACES ---
      // Surface: The "Sheet" of paper.
      surface: CatppuccinMochaColors.base,
      onSurface: CatppuccinMochaColors.text, // Main text
      // Surface Container: "Elevated" elements (Cards, Dialogs).
      surfaceContainer: CatppuccinMochaColors.surface0,
      onSurfaceVariant: CatppuccinMochaColors.subtext0, // Muted text
      // Highlight/Active States
      // Guideline: Surface1/Surface2 are for active states and highlights.
      secondaryContainer: CatppuccinMochaColors.surface1,
      onSecondaryContainer: CatppuccinMochaColors.mauve,

      // --- ERRORS ---
      error: CatppuccinMochaColors.red,
      onError: CatppuccinMochaColors.crust,
    ),

    extensions: <ThemeExtension<dynamic>>[
      SidebarTheme(
        backgroundColor: CatppuccinMochaColors.mantle, // Mantle is used for sidebars
        itemBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            // When actively clicking down
            return CatppuccinMochaColors.surface2.withValues(alpha: 0.8);
          }
          if (states.contains(WidgetState.selected)) {
            // Highlighting the active menu item
            return CatppuccinMochaColors.surface1;
          }
          if (states.contains(WidgetState.focused)) {
            // Keyboard navigation focus
            return CatppuccinMochaColors.surface2.withValues(alpha: 0.5);
          }
          if (states.contains(WidgetState.hovered)) {
            // Subtle highlight when hovering
            return CatppuccinMochaColors.surface2.withValues(alpha: 0.3);
          }
          return Colors.transparent;
        }),
        itemForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            // Signature Catppuccin Mauve when selected
            return CatppuccinMochaColors.mauve;
          }
          if (states.contains(WidgetState.pressed) ||
              states.contains(WidgetState.focused) ||
              states.contains(WidgetState.hovered)) {
            // Bright white/text color when interacting
            return CatppuccinMochaColors.text;
          }
          // Muted subtext when unselected
          return CatppuccinMochaColors.subtext0;
        }),
      ),
    ],

    appBarTheme: const AppBarTheme(
      backgroundColor: CatppuccinMochaColors.base,
      foregroundColor: CatppuccinMochaColors.text,
      elevation: 0,
    ),

    dividerTheme: const DividerThemeData(color: CatppuccinMochaColors.surface1, thickness: 2, space: 2),

    sliderTheme: SliderThemeData(
      trackHeight: 5,
      trackShape: const RoundedRectSliderTrackShape(),
      activeTrackColor: CatppuccinMochaColors.mauve,
      inactiveTrackColor: CatppuccinMochaColors.surface1,
      secondaryActiveTrackColor: CatppuccinMochaColors.mauve.withValues(alpha: 0.38),

      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
      thumbColor: CatppuccinMochaColors.mauve,

      overlayShape: const RoundSliderOverlayShape(overlayRadius: 14.0),
      overlayColor: CatppuccinMochaColors.mauve.withValues(alpha: 0.24),

      valueIndicatorColor: CatppuccinMochaColors.surface1,
      valueIndicatorTextStyle: TextStyle(fontFamily: resolvedFont, color: CatppuccinMochaColors.text),
    ),

    iconButtonTheme: IconButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected) || states.contains(WidgetState.pressed)) {
            return CatppuccinMochaColors.mauve;
          }
          if (states.contains(WidgetState.disabled)) {
            return CatppuccinMochaColors.overlay0;
          }
          return CatppuccinMochaColors.subtext0;
        }),

        overlayColor: WidgetStateProperty.all(CatppuccinMochaColors.mauve.withValues(alpha: 0.12)),
      ),
    ),

    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(color: CatppuccinMochaColors.surface1, borderRadius: BorderRadius.circular(4)),

      textStyle: TextStyle(
        fontFamily: resolvedFont,
        color: CatppuccinMochaColors.text,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    ),

    dropdownMenuTheme: DropdownMenuThemeData(
      menuStyle: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(CatppuccinMochaColors.surface0),
        side: WidgetStatePropertyAll(const BorderSide(color: CatppuccinMochaColors.surface1, width: 2)),
      ),

      textStyle: TextStyle(fontFamily: resolvedFont, color: CatppuccinMochaColors.text),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: CatppuccinMochaColors.surface0,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: CatppuccinMochaColors.surface1, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: CatppuccinMochaColors.mauve, width: 2),
        ),

        iconColor: CatppuccinMochaColors.text,
        suffixIconColor: CatppuccinMochaColors.text,
      ),
    ),

    listTileTheme: ListTileThemeData(
      tileColor: Colors.transparent,
      selectedTileColor: CatppuccinMochaColors.surface1,
      iconColor: CatppuccinMochaColors.subtext0,
      selectedColor: CatppuccinMochaColors.mauve,
      titleTextStyle: TextStyle(
        fontFamily: resolvedFont,
        inherit: false,
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: CatppuccinMochaColors.text,
        height: 1.4,
        letterSpacing: 0.15,
      ),
      subtitleTextStyle: TextStyle(
        fontFamily: resolvedFont,
        inherit: false,
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: CatppuccinMochaColors.subtext0,
        height: 1.4,
        letterSpacing: 0.25,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      visualDensity: VisualDensity.standard,
    ),

    textTheme: TextTheme(
      displayLarge: TextStyle(
        fontFamily: resolvedFont,
        fontSize: 48,
        fontWeight: FontWeight.bold,
        color: CatppuccinMochaColors.text,
      ),
      displayMedium: TextStyle(
        fontFamily: resolvedFont,
        fontSize: 36,
        fontWeight: FontWeight.bold,
        color: CatppuccinMochaColors.text,
      ),

      headlineLarge: TextStyle(
        fontFamily: resolvedFont,
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: CatppuccinMochaColors.text,
      ),
      headlineMedium: TextStyle(
        fontFamily: resolvedFont,
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: CatppuccinMochaColors.text,
      ),

      titleLarge: TextStyle(
        fontFamily: resolvedFont,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: CatppuccinMochaColors.text,
      ),
      titleMedium: TextStyle(
        fontFamily: resolvedFont,
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: CatppuccinMochaColors.subtext1,
      ),
      titleSmall: TextStyle(
        fontFamily: resolvedFont,
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: CatppuccinMochaColors.subtext1,
      ),

      bodyLarge: TextStyle(
        fontFamily: resolvedFont,
        fontSize: 15,
        fontWeight: FontWeight.normal,
        color: CatppuccinMochaColors.subtext0,
      ),
      bodyMedium: TextStyle(
        fontFamily: resolvedFont,
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: CatppuccinMochaColors.subtext0,
      ),
      bodySmall: TextStyle(
        fontFamily: resolvedFont,
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: CatppuccinMochaColors.overlay1, // Muted further
      ),

      labelLarge: TextStyle(
        fontFamily: resolvedFont,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: CatppuccinMochaColors.text,
      ),
      labelSmall: TextStyle(
        fontFamily: resolvedFont,
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: CatppuccinMochaColors.subtext0,
      ),
    ),

    cardTheme: CardThemeData(
      color: CatppuccinMochaColors.surface0,
      shadowColor: Colors.black26,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  );
}
