import 'package:flutter/material.dart';
import 'package:nordplayer/theme/nord_theme.dart' as nord_theme;

class AppTheme {
  AppTheme._();

  static final ThemeData nordTheme = nord_theme.nordTheme;
  static final ThemeData defaultDark = ThemeData.dark(useMaterial3: true);
  static final ThemeData defaultLight = ThemeData.light(useMaterial3: true);

  static final Map<String, ThemeData> themes = {
    'nord': nordTheme,
    'dark': defaultDark,
    'light': defaultLight,
  };

  static const Map<String, String> labels = {
       'nord': 'Nord',
       'dark': 'Default Dark',
       'light': 'Default Light',
     };


  static ThemeData getTheme(String key) => themes[key] ?? nordTheme;
}
