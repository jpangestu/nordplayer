import 'package:flutter/material.dart';
import 'package:nordplayer/theme/nord_theme.dart' as nord_theme;

class AppTheme {
  AppTheme._instance();
  static final AppTheme _singleton = AppTheme._instance();
  factory AppTheme() => _singleton;

  static final ThemeData nordTheme = nord_theme.nordTheme;
  static final ThemeData defaultDark = ThemeData.dark(useMaterial3: true);
  static final ThemeData defaultLight = ThemeData.light(useMaterial3: true);

  static final Map<String, ThemeData> _themeDataMap = {
    'nord': nordTheme,
    'dark': defaultDark,
    'light': defaultLight,
  };

  Map<String, ThemeData> getThemeDataMap() {
    return _themeDataMap;
  }

  Map<String, String> getKeyAndLabel() {
    return {'nord': 'Nord', 'dark': 'Default Dark', 'light': 'Default Light'};
  }

  ThemeData withKey(String key) {
    return _themeDataMap[key]!;
  }
}
