import 'dart:io' show File;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nordplayer/ui/shared/themes/app_theme.dart';
import 'package:nordplayer/ui/shared/themes/themes/adaptive.dart';
import 'package:nordplayer/data/services/system/config_service.dart';
import 'package:nordplayer/data/services/audio/player_service.dart';
import 'package:nordplayer/data/services/system/preference_service.dart';

final adaptiveThemeProvider = FutureProvider<AdaptiveColorScheme>((ref) async {
  final trackAlbumArtPath = ref.watch(currentTrackProvider.select((t) => t?.album.albumArtPath));
  final cachedAlbumArtPath = ref.watch(preferenceServiceProvider.select((p) => p.cachedAlbumArtPath));

  final themeBrightness = ref.watch(
    configServiceProvider.select((c) => c.themeBrightness),
  );

  final albumArtPath = trackAlbumArtPath ?? cachedAlbumArtPath;

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
  final currentTheme = ref.watch(configServiceProvider.select((c) => c.theme));
  final currentFont = ref.watch(configServiceProvider.select((c) => c.fontFamily));

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
