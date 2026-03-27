import 'package:flutter/material.dart';
import 'package:nordplayer/theme/nord_theme.dart';
import 'package:nordplayer/theme/catppuccin_mocha_theme.dart';

class AppTheme {
  AppTheme._();

  static final ThemeData defaultDark = ThemeData.dark(useMaterial3: true);
  static final ThemeData defaultLight = ThemeData.light(useMaterial3: true);

  static final Map<String, ThemeData> themes = {
    'nord': nordTheme,
    'catpuccin_mocha': catppuccinMochaTheme,
    'dark': defaultDark,
    'light': defaultLight,
  };

  static const Map<String, String> labels = {
    'nord': 'Nord',
    'catpuccin_mocha': 'Catpuccin Mocha',
    'dark': 'Default Dark',
    'light': 'Default Light',
  };

  static ThemeData getTheme(String key) => themes[key] ?? nordTheme;
}
