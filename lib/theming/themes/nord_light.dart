import 'package:flutter/material.dart';
import 'package:nordplayer/theming/theme_builder.dart';

class NordLightColorScheme extends AppColorScheme {
  @override
  Brightness get brightness => Brightness.light;

  // --- PRIMARY (Frost - Deepened for WCAG Light Mode Contrast) ---
  @override
  Color get primary => const Color(0xFF5E81AC); // nord10
  @override
  Color get onPrimary => const Color(0xFFFFFFFF);

  // --- SECONDARY (Frost - Standard) ---
  @override
  Color get secondary => const Color(0xFF88C0D0); // nord8
  @override
  Color get onSecondary => const Color(0xFF2E3440); // nord0 (Dark text needed on light blue)

  // @override
  // Color get surfaceContainerLowest => const Color(0xFFFFFFFF); // Pure White - Deepest rest state
  // @override
  // Color get surfaceContainerLow => const Color(0xFFF5F7FA); // Custom: Subtle bridge between white and nord6

  // --- SURFACES (The Snow Storm Ramp) ---
  @override
  Color get surfaceContainerLowest => const Color(0xFFFFFFFF); // Anchor 1: Deepest/Inset background
  @override
  Color get surface => const Color(0xFFf9fafc); // Anchor 2: Pure white base

  // The elevated containers progressively step into the Nord Snow Storm palette
  @override
  Color get surfaceContainerLow => const Color(0xFFF5F7FA); // Subtle bridge
  @override
  Color get surfaceContainer => const Color(0xFFECEFF4); // nord6 - Standard Cards
  @override
  Color get surfaceContainerHigh => const Color(0xFFE5E9F0); // nord5 - Elevated UI
  @override
  Color get surfaceContainerHighest => const Color(0xFFD8DEE9); // nord4 - Highest menus/modals

  // --- TYPOGRAPHY (Polar Night) ---
  @override
  Color get onSurface => const Color(0xFF2E3440); // nord0 - Crisp, high-contrast dark text
  @override
  Color get onSurfaceVariant => const Color(0xFF4C566A); // nord3 - Muted/Subtitle text

  // --- OUTLINES ---
  @override
  Color get outline => const Color(0xFF4C566A); // nord3 - Active borders
  @override
  Color get outlineVariant => const Color(0xFFD8DEE9); // nord4 - Muted dividers

  // --- SEMANTICS (Aurora Palette) ---
  @override
  Color get error => const Color(0xFFBF616A); // nord11
  @override
  Color get onError => const Color(0xFFFFFFFF);

  @override
  Color get success => const Color(0xFFA3BE8C); // nord14
  @override
  Color get onSuccess => const Color(0xFF2E3440); // nord0 (Light green needs dark text)

  @override
  Color get warning => const Color(0xFFD08770); // nord12 (Using Aurora Orange for better light-mode visibility)
  @override
  Color get onWarning => const Color(0xFFFFFFFF);

  @override
  Color get info => const Color(0xFF81A1C1); // nord9
  @override
  Color get onInfo => const Color(0xFFFFFFFF);

  @override
  Color get general => const Color(0xFF3B4252); // nord1
  @override
  Color get onGeneral => const Color(0xFFECEFF4); // nord6
}
