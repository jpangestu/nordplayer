import 'package:flutter/material.dart';
import 'package:nordplayer/theming/theme_builder.dart';

class NordColorScheme extends AppColorScheme {
  @override
  Brightness get brightness => Brightness.dark;

  @override
  Color get primary => const Color(0xFF88C0D0); // nord8 - Accent color
  @override
  Color get onPrimary => const Color(0xFF2E3440); // nord0

  @override
  Color get secondary => const Color(0xFF81A1C1); // nord9
  @override
  Color get onSecondary => const Color(0xFF2E3440); // nord0

  @override
  Color get surfaceContainerLowest => const Color(0xFF242933); // nord0 50% darkened
  @override
  Color get surface => const Color(0xFF2E3440); // nord0 - Background color
  @override
  Color get surfaceContainerLow => const Color(0xFF353B49); // mid point of nord1 - nord0
  @override
  Color get surfaceContainer => const Color(0xFF3B4252); // nord1
  @override
  Color get surfaceContainerHigh => const Color(0xFF434C5E); // nord2
  @override
  Color get surfaceContainerHighest => const Color(0xFF4C566A); // nord3

  @override
  Color get onSurface => const Color(0xFFECEFF4); // nord6 - Main text color
  @override
  Color get onSurfaceVariant => const Color(0xFFC2C8D2); // nord4 10% darkened - Subtitle/muted

  @override
  Color get outline => const Color(0xFFd8dee9); // nord3 - Main outline
  @override
  Color get outlineVariant => const Color(0xFF4C566A); // nord3 - Darker outline (for divider

  @override
  Color get error => const Color(0xFFBF616A); // nord11
  @override
  Color get onError => const Color(0xFFd8dee9); // nord6

  @override
  Color get success => const Color(0xFFA3BE8C); // nord14
  @override
  Color get onSuccess => const Color(0xFFd8dee9); // nord6

  @override
  Color get warning => const Color(0xFFEBCB8B); // nord13
  @override
  Color get onWarning => const Color(0xFFd8dee9); // nord6

  @override
  Color get info => const Color(0xFF5E81AC); // nord10
  @override
  Color get onInfo => const Color(0xFFd8dee9); // nord6

  @override
  Color get general => const Color(0xFFD8DEE9); // nord4
  @override
  Color get onGeneral => const Color(0xFF2E3440); // nord6
}
