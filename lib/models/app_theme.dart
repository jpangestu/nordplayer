import 'package:flutter/material.dart';
import 'package:nordplayer/theming/catppuccin_mocha_theme.dart';
import 'package:nordplayer/theming/nord_theme.dart';

class AppTheme {
  AppTheme._();

  static final ThemeData defaultDark = ThemeData.dark(useMaterial3: true);
  static final ThemeData defaultLight = ThemeData.light(useMaterial3: true);

  static const Map<String, String> labels = {
    'nord': 'Nord',
    'catpuccin_mocha': 'Catpuccin Mocha',
    'dark': 'Default Dark',
    'light': 'Default Light',
  };

  static const Map<String, String> availableFonts = {
    'System': 'System Default',
    'Inter': 'Inter',
    'JetBrains Mono': 'JetBrains Mono',
    'Lora': 'Lora',
    'Outfit': 'Outfit',
    'Rubik': 'Rubik',
  };

  static ThemeData getTheme(String key, String fontFamily) {
    if (key == 'nord') {
      return buildNordTheme(fontFamily: fontFamily);
    } else if (key == 'catpuccin_mocha') {
      return buildCatppuccinMochaTheme(fontFamily: fontFamily);
    } else if (key == 'light') {
      return defaultLight.copyWith(textTheme: defaultLight.textTheme.apply(fontFamily: fontFamily));
    }

    // Default fallback
    return defaultDark.copyWith(textTheme: defaultDark.textTheme.apply(fontFamily: fontFamily));
  }
}
