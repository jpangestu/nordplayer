import 'dart:io' show File;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nordplayer/data/repositories/config_repository.dart';
import 'package:nordplayer/data/repositories/ui_preferences_repository.dart';
import 'package:nordplayer/data/services/audio/player_state.dart';
import 'package:nordplayer/ui/shared/themes/app_theme.dart';
import 'package:nordplayer/ui/shared/themes/themes/adaptive.dart';

final adaptiveThemeProvider = FutureProvider<AdaptiveColorScheme>((ref) async {
  final trackAlbumArtPath = ref.watch(currentTrackProvider.select((t) => t?.album.albumArtPath));
  final cachedAlbumArtPath = ref.watch(uiPreferencesStateProvider.select((p) => p.cachedAlbumArtPath));

  final themeBrightness = ref.watch(configStateProvider.select((c) => c.themeBrightness));

  final albumArtPath = (trackAlbumArtPath != null && trackAlbumArtPath.isNotEmpty)
      ? trackAlbumArtPath
      : cachedAlbumArtPath;

  // Determine the correct ImageProvider based on the path.
  // Downsample to 112x112 thumbnail: Material 3 ColorScheme extraction only requires
  // a small palette sample and avoids decoding full multi-megabyte images into RAM.
  final ImageProvider imageProvider;
  final FileImage? fileImage;
  if (albumArtPath != null && albumArtPath.isNotEmpty) {
    fileImage = FileImage(File(albumArtPath));
    imageProvider = ResizeImage(fileImage, width: 112, height: 112);
  } else {
    fileImage = null;
    imageProvider = const ResizeImage(AssetImage('assets/images/default_background.png'), width: 112, height: 112);
  }

  // Register onDispose listener to evict the image from cache if the provider is cancelled or rebuilt.
  ref.onDispose(() {
    imageProvider.evict();
    fileImage?.evict();
  });

  final generatedScheme = await ColorScheme.fromImageProvider(provider: imageProvider, brightness: themeBrightness);

  // Evict the image provider from Flutter's imageCache immediately after extraction
  // to avoid retaining the decoded image in memory.
  await imageProvider.evict();
  await fileImage?.evict();

  return AdaptiveColorScheme.fromColorScheme(generatedScheme);
});

final activeThemeProvider = Provider<ThemeData>((ref) {
  final currentTheme = ref.watch(configStateProvider.select((c) => c.theme));
  final currentFont = ref.watch(configStateProvider.select((c) => c.fontFamily));

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
