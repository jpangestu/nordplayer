import 'dart:io' show File;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nordplayer/services/config_service.dart';
import 'package:nordplayer/services/player_service.dart';
import 'package:nordplayer/theming/theme_builder.dart';
import 'package:nordplayer/theming/themes/adaptive.dart';
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

  // Nullable fontFamily for system font (null == system font)
  static ThemeData getTheme(String key, String? fontFamily, {AppColorScheme? adaptiveScheme}) {
    // Convert the string 'system' into a true null for Flutter
    final String? actualFontFamily = fontFamily == 'system' ? null : fontFamily;

    // Only use fallbacks if we are NOT using the system font.
    // Also, make sure 'system' isn't accidentally passed into the fallback list.
    final List<String>? fallbacks = actualFontFamily == null
        ? null
        : availableFonts.keys.where((k) => k != 'system').toList();

    AppColorScheme schemeToUse;

    if (key == 'adaptive' && adaptiveScheme != null) {
      schemeToUse = adaptiveScheme;
    } else if (key == 'nord_light') {
      schemeToUse = NordLightColorScheme();
    } else if (key == 'graphite') {
      schemeToUse = GraphiteColorScheme();
    } else {
      // Default to standard Nord (also acts as a safe fallback if 'adaptive' is selected but the scheme is null)
      schemeToUse = NordColorScheme();
    }

    return buildTheme(fontFamily: fontFamily, fontFamilyFallback: fallbacks, appColorScheme: schemeToUse);
  }
}

// =============================================== Provider ===========================================================

final adaptiveThemeProvider = FutureProvider<AdaptiveColorScheme>((ref) async {
  final track = ref.watch(currentTrackProvider);
  
  final themeBrightness = ref.watch(
    configServiceProvider.select((asyncValue) => asyncValue.value?.themeBrightness ?? Brightness.dark),
  );
  
  final albumArtPath = track?.album.albumArtPath;

  // Determine the correct ImageProvider based on the path
  final ImageProvider imageProvider;
  if (albumArtPath != null && albumArtPath.isNotEmpty) {
    // If it's a real path on the device, use FileImage
    imageProvider = FileImage(File(albumArtPath));
  } else {
    // If it's a fallback asset bundled with the app, use AssetImage
    imageProvider = const AssetImage('assets/images/default_background.png');
  }

  // Register onDispose listener to evict the image from cache if the provider is cancelled or rebuilt.
  ref.onDispose(() {
    if (imageProvider is FileImage) {
      imageProvider.evict();
    }
  });

  final generatedScheme = await ColorScheme.fromImageProvider(provider: imageProvider, brightness: themeBrightness);

  // Evict the image provider from Flutter's imageCache immediately after extraction
  // to avoid retaining the full-resolution decoded image in memory.
  if (imageProvider is FileImage) {
    await imageProvider.evict();
  }

  return AdaptiveColorScheme.fromColorScheme(generatedScheme);
});

final activeThemeProvider = Provider<ThemeData>((ref) {
  final currentTheme = ref.watch(configServiceProvider.select((v) => v.value?.theme ?? 'nord'));
  final currentFont = ref.watch(configServiceProvider.select((v) => v.value?.fontFamily));

  if (currentTheme != 'adaptive') {
    return AppTheme.getTheme(currentTheme, currentFont);
  }

  final adaptiveThemeAsync = ref.watch(adaptiveThemeProvider);

  // .value contains the most recently generated scheme.
  // When the track changes, this will hold the OLD scheme until the NEW one is ready!
  final currentAdaptiveScheme = adaptiveThemeAsync.value;

  if (currentAdaptiveScheme != null) {
    // If we have any scheme at all (old or new), use it. No flicker!
    return AppTheme.getTheme(currentTheme, currentFont, adaptiveScheme: currentAdaptiveScheme);
  } else {
    // Fallback at app first launch
    return AppTheme.getTheme('nord', currentFont);
  }
});

