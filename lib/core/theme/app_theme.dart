import 'package:material_ui/material_ui.dart';
import 'package:nordplayer/core/theme/theme_builder.dart';
import 'package:nordplayer/core/theme/themes/graphite.dart';
import 'package:nordplayer/core/theme/themes/nord.dart';
import 'package:nordplayer/core/theme/themes/nord_light.dart';

class AppTheme {
  AppTheme._();

  static final ThemeData defaultDark = ThemeData.dark(useMaterial3: true);
  static final ThemeData defaultLight = ThemeData.light(useMaterial3: true);

  static const Map<String, String> labels = {
    'nord': 'Nord (default)',
    'nord_light': 'Nord Light',
    'adaptive': 'Adaptive',
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

  static final List<String> _fontFallbacks =
      availableFonts.keys.where((k) => k != 'system').toList(growable: false);

  static final AppColorScheme _nordScheme = NordColorScheme();
  static final AppColorScheme _nordLightScheme = NordLightColorScheme();
  static final AppColorScheme _graphiteScheme = GraphiteColorScheme();

  // Nullable fontFamily for system font (null == system font)
  static ThemeData getTheme(String key, String? fontFamily, {AppColorScheme? adaptiveScheme}) {
    // Convert the string 'system' into a true null for Flutter
    final String? actualFontFamily = fontFamily == 'system' ? null : fontFamily;

    // Only use fallbacks if we are NOT using the system font.
    final List<String>? fallbacks = actualFontFamily == null ? null : _fontFallbacks;

    final AppColorScheme schemeToUse;
    if (key == 'adaptive' && adaptiveScheme != null) {
      schemeToUse = adaptiveScheme;
    } else if (key == 'nord_light') {
      schemeToUse = _nordLightScheme;
    } else if (key == 'graphite') {
      schemeToUse = _graphiteScheme;
    } else {
      // Default to standard Nord (also acts as a safe fallback if 'adaptive' is selected but the scheme is null)
      schemeToUse = _nordScheme;
    }

    return buildTheme(
      fontFamily: actualFontFamily,
      fontFamilyFallback: fallbacks,
      appColorScheme: schemeToUse,
    );
  }
}
