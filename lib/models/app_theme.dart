import 'package:flutter/material.dart';
import 'package:nordplayer/theming/theme_builder.dart';
import 'package:nordplayer/theming/themes/graphite.dart';
import 'package:nordplayer/theming/themes/nord.dart';
import 'package:nordplayer/theming/themes/nord_light.dart';

class AppTheme {
  AppTheme._();

  static final ThemeData defaultDark = ThemeData.dark(useMaterial3: true);
  static final ThemeData defaultLight = ThemeData.light(useMaterial3: true);

  static const Map<String, String> labels = {
    'nord': 'Nord (default)',
    'nord_light': 'Nord Light',
    'graphite': 'Graphite',
  };

  static const Map<String, String> availableFonts = {
    'outfit': 'Outfit (default)',
    'inter': 'Inter',
    'jetbrains_mono': 'JetBrains Mono',
    'lora': 'Lora',
    'rubik': 'Rubik',
    'system': 'System Default',
  };

  static ThemeData getTheme(String key, String fontFamily) {
    if (key == 'nord') {
      return buildTheme(
        fontFamily: fontFamily,
        fontFamilyFallback: availableFonts.keys.toList(),
        nordColorScheme: NordColorScheme(),
      );
    } else if (key == 'nord_light') {
      return buildTheme(
        fontFamily: fontFamily,
        fontFamilyFallback: availableFonts.keys.toList(),
        nordColorScheme: NordLightColorScheme(),
      );
    } else if (key == 'graphite') {
      return buildTheme(
        fontFamily: fontFamily,
        fontFamilyFallback: availableFonts.keys.toList(),
        nordColorScheme: GraphiteColorScheme(),
      );
    }

    return buildTheme(
      fontFamily: fontFamily,
      fontFamilyFallback: availableFonts.keys.toList(),
      nordColorScheme: NordColorScheme(),
    );
  }
}
