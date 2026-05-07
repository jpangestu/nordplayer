import 'package:flutter/material.dart';
import 'package:nordplayer/theming/theme-extension/nord_sidebar_theme.dart';
import 'package:nordplayer/theming/theme-extension/nord_snackbar_theme.dart';

class GraphiteColors {
  // --- BACKGROUNDS (The Charcoals) ---
  // Deepest background for the main scaffold
  static const Color graphite0 = Color(0xFF161618);

  // Elevated panels, cards, and modals
  static const Color graphite1 = Color(0xFF222225);

  // Active items, hover states, and selections
  static const Color graphite2 = Color(0xFF2D2D31);

  // Borders, dividers, and guides
  static const Color graphite3 = Color(0xFF3D3D42);

  // --- TEXT (The Silvers) ---
  // Muted, disabled, or secondary text
  static const Color graphite4 = Color(0xFF8F8F94);

  // Standard reading text
  static const Color graphite5 = Color(0xFFC8C8CC);

  // High-contrast headings and active text
  static const Color graphite6 = Color(0xFFEBEBEF);

  // --- ACCENTS (Steel Blue) ---
  static const Color graphite7 = Color(0xFF8E9BB0);

  // Primary accent (Buttons, sliders, active icons)
  static const Color graphite8 = Color(0xFF738CA6);

  // Secondary accents
  static const Color graphite9 = Color(0xFF5C7085);

  // Tertiary accents
  static const Color graphite10 = Color(0xFF455566);

  // --- STATES (Muted pastels to fit the dark theme) ---
  static const Color graphite11 = Color(0xFFD27979); // Error
  static const Color graphite12 = Color(0xFFD29B79); // Danger
  static const Color graphite13 = Color(0xFFD2B479); // Warning
  static const Color graphite14 = Color(0xFF79D28B); // Success
  static const Color graphite15 = Color(0xFFA179D2); // Uncommon
}

ThemeData buildGraphiteTheme({String? fontFamily}) {
  final String? resolvedFont = (fontFamily == null || fontFamily == 'System' || fontFamily.isEmpty) ? null : fontFamily;

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,

    // SCAFFOLD
    scaffoldBackgroundColor: GraphiteColors.graphite0,

    colorScheme: ColorScheme(
      brightness: Brightness.dark,

      // --- PRIMARY ---
      primary: GraphiteColors.graphite8,
      onPrimary: GraphiteColors.graphite0,

      // --- SECONDARY ---
      secondary: GraphiteColors.graphite9,
      onSecondary: GraphiteColors.graphite0,

      // --- TERTIARY ---
      tertiary: GraphiteColors.graphite10,
      onTertiary: GraphiteColors.graphite6,

      // --- SURFACES ---
      surface: GraphiteColors.graphite0,
      surfaceContainerLow: Color.lerp(GraphiteColors.graphite1, GraphiteColors.graphite0, 0.5),
      surfaceContainer: GraphiteColors.graphite1,
      surfaceContainerHigh: Color.lerp(GraphiteColors.graphite1, GraphiteColors.graphite2, 0.5),
      onSurface: GraphiteColors.graphite6,

      onSurfaceVariant: GraphiteColors.graphite4,

      // Highlight/Active States
      secondaryContainer: GraphiteColors.graphite2,
      onSecondaryContainer: GraphiteColors.graphite8,

      // --- ERRORS ---
      error: GraphiteColors.graphite11,
      onError: GraphiteColors.graphite6,
    ),

    extensions: <ThemeExtension<dynamic>>[
      NordSidebarTheme(
        backgroundColor: GraphiteColors.graphite1,
        itemBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return GraphiteColors.graphite3.withValues(alpha: 0.8);
          }
          if (states.contains(WidgetState.selected)) {
            return GraphiteColors.graphite2;
          }
          if (states.contains(WidgetState.focused)) {
            return GraphiteColors.graphite3.withValues(alpha: 0.5);
          }
          if (states.contains(WidgetState.hovered)) {
            return GraphiteColors.graphite3.withValues(alpha: 0.3);
          }
          return Colors.transparent;
        }),
        itemForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GraphiteColors.graphite8;
          }
          if (states.contains(WidgetState.pressed) ||
              states.contains(WidgetState.focused) ||
              states.contains(WidgetState.hovered)) {
            return GraphiteColors.graphite6;
          }
          return GraphiteColors.graphite4;
        }),
      ),

      const NordSnackBarTheme(
        generalColor: GraphiteColors.graphite6,
        infoColor: GraphiteColors.graphite9,
        successColor: GraphiteColors.graphite14,
        warningColor: GraphiteColors.graphite13,
        errorColor: GraphiteColors.graphite11,
      ),
    ],

    appBarTheme: const AppBarTheme(
      backgroundColor: GraphiteColors.graphite0,
      foregroundColor: GraphiteColors.graphite6,
      elevation: 0,
    ),

    dividerTheme: const DividerThemeData(color: GraphiteColors.graphite2, thickness: 2, space: 2),

    sliderTheme: SliderThemeData(
      trackHeight: 5,
      trackShape: const RoundedRectSliderTrackShape(),
      activeTrackColor: GraphiteColors.graphite8,
      inactiveTrackColor: GraphiteColors.graphite3,
      secondaryActiveTrackColor: GraphiteColors.graphite8.withValues(alpha: 0.38),

      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
      thumbColor: GraphiteColors.graphite8,

      overlayShape: const RoundSliderOverlayShape(overlayRadius: 14.0),
      overlayColor: GraphiteColors.graphite8.withValues(alpha: 0.24),

      valueIndicatorColor: GraphiteColors.graphite3,
      valueIndicatorTextStyle: TextStyle(fontFamily: resolvedFont, color: GraphiteColors.graphite6),
    ),

    iconButtonTheme: IconButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected) || states.contains(WidgetState.pressed)) {
            return GraphiteColors.graphite8;
          }
          if (states.contains(WidgetState.disabled)) {
            return GraphiteColors.graphite3;
          }
          return GraphiteColors.graphite4;
        }),
        overlayColor: WidgetStateProperty.all(GraphiteColors.graphite8.withValues(alpha: 0.12)),
      ),
    ),

    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(color: GraphiteColors.graphite3, borderRadius: BorderRadius.circular(4)),
      textStyle: TextStyle(
        fontFamily: resolvedFont,
        color: GraphiteColors.graphite6,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    ),

    dropdownMenuTheme: DropdownMenuThemeData(
      menuStyle: const MenuStyle(
        backgroundColor: WidgetStatePropertyAll(GraphiteColors.graphite3),
        side: WidgetStatePropertyAll(BorderSide(color: GraphiteColors.graphite2, width: 2)),
      ),
      textStyle: TextStyle(fontFamily: resolvedFont, color: GraphiteColors.graphite6),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: GraphiteColors.graphite3,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: GraphiteColors.graphite8, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: GraphiteColors.graphite8, width: 2),
        ),
        iconColor: GraphiteColors.graphite6,
        suffixIconColor: GraphiteColors.graphite6,
      ),
    ),

    listTileTheme: ListTileThemeData(
      tileColor: Colors.transparent,
      selectedTileColor: GraphiteColors.graphite2,
      iconColor: GraphiteColors.graphite4,
      selectedColor: GraphiteColors.graphite8,
      titleTextStyle: TextStyle(
        fontFamily: resolvedFont,
        inherit: false,
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: GraphiteColors.graphite6,
        height: 1.4,
        letterSpacing: 0.15,
      ),
      subtitleTextStyle: TextStyle(
        fontFamily: resolvedFont,
        inherit: false,
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: Color.lerp(GraphiteColors.graphite3, GraphiteColors.graphite4, 0.8),
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
        color: GraphiteColors.graphite6,
      ),
      displayMedium: TextStyle(
        fontFamily: resolvedFont,
        fontSize: 36,
        fontWeight: FontWeight.bold,
        color: GraphiteColors.graphite6,
      ),
      headlineLarge: TextStyle(
        fontFamily: resolvedFont,
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: GraphiteColors.graphite6,
      ),
      headlineMedium: TextStyle(
        fontFamily: resolvedFont,
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: GraphiteColors.graphite6,
      ),
      titleLarge: TextStyle(
        fontFamily: resolvedFont,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: GraphiteColors.graphite6,
      ),
      titleMedium: TextStyle(
        fontFamily: resolvedFont,
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: GraphiteColors.graphite5,
      ),
      titleSmall: TextStyle(
        fontFamily: resolvedFont,
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: GraphiteColors.graphite5,
      ),
      bodyLarge: TextStyle(
        fontFamily: resolvedFont,
        fontSize: 15,
        fontWeight: FontWeight.normal,
        color: GraphiteColors.graphite4,
      ),
      bodyMedium: TextStyle(
        fontFamily: resolvedFont,
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: GraphiteColors.graphite4,
      ),
      bodySmall: TextStyle(
        fontFamily: resolvedFont,
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: GraphiteColors.graphite4,
      ),
      labelLarge: TextStyle(
        fontFamily: resolvedFont,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: GraphiteColors.graphite6,
      ),
      labelSmall: TextStyle(
        fontFamily: resolvedFont,
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: GraphiteColors.graphite4,
      ),
    ),
  );
}
