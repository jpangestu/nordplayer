import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nordplayer/services/config_service.dart';
import 'package:nordplayer/theming/icon-sets/lucide_icons.dart';
import 'package:nordplayer/theming/icon-sets/material_icons.dart';

abstract class AppIconSet {
  // To make sure all icon set (that'll definitely has different margin/spacing) will ended up with the same size
  // Use material icon set as the default scale (material = 1.0)
  double get opticalScale;

  // Top Bar
  IconData get keyboardShortcut;
  IconData get search;

  // Sidebar
  IconData get sidebarClose;
  IconData get sidebarOpen;
  IconData get library;
  IconData get albums;
  IconData get allTracks;
  IconData get artists;
  IconData get genres;
  IconData get playlist;

  // Player Bar
  IconData get play;
  IconData get pause;
  IconData get next;
  IconData get previous;
  IconData get repeat;
  IconData get repeatOne;
  IconData get shuffle;
  IconData get lyrics;
  IconData get queue;
  IconData get volumeHigh;
  IconData get volumeLow;
  IconData get volumeMute;

  // Settings
  IconData get settings;
  IconData get appearanceSettings;
  IconData get librarySettings;
  IconData get advancedSettings;
  IconData get about;

  // Snack Bar type
  IconData get general;
  IconData get info;
  IconData get warning;
  IconData get success;
  IconData get error;

  // Others
  IconData get contextMenu; // Horizontal
  IconData get favorite; // Heart
  IconData get navigationLeft;
  IconData get navigationRight;
  IconData get navigationUp;
  IconData get navigationDown;
  IconData get playtime;
  IconData get preference;
  IconData get statistic;
  IconData get storage;
}

final appIconProvider = Provider<AppIconSet>((ref) {
  final iconSetName = ref.watch(configServiceProvider).requireValue.iconSet;

  switch (iconSetName) {
    case 'material':
      return MaterialIconSet();
    case 'lucide':
    default:
      return LucideIconSet();
  }
});
