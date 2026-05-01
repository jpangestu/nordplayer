import 'package:flutter/material.dart';
import 'package:nordplayer/theming/icon-sets/app_icon_set.dart';

class MaterialIconSet implements AppIconSet {
  @override
  double get opticalScale => 1.0;

  // Top Bar
  @override
  IconData get keyboardShortcut => Icons.bolt;
  @override
  IconData get search => Icons.search;

  // Sidebar
  @override
  IconData get sidebarClose => Icons.menu_open;
  @override
  IconData get sidebarOpen => Icons.menu;
  @override
  IconData get library => Icons.library_music;
  @override
  IconData get albums => Icons.album;
  @override
  IconData get allTracks => Icons.music_note;
  @override
  IconData get artists => Icons.people;
  @override
  IconData get genres => Icons.label;
  @override
  IconData get playlist => Icons.queue_music;

  // Player Bar
  @override
  IconData get play => Icons.play_circle;
  @override
  IconData get pause => Icons.pause_circle;
  @override
  IconData get next => Icons.skip_next;
  @override
  IconData get previous => Icons.skip_previous;
  @override
  IconData get repeat => Icons.repeat;
  @override
  IconData get repeatOne => Icons.repeat_one;
  @override
  IconData get shuffle => Icons.shuffle;
  @override
  IconData get lyrics => Icons.lyrics_outlined;
  @override
  IconData get queue => Icons.format_list_bulleted;
  @override
  IconData get volumeHigh => Icons.volume_up;
  @override
  IconData get volumeLow => Icons.volume_down;
  @override
  IconData get volumeMute => Icons.volume_off;

  // Settings
  @override
  IconData get settings => Icons.settings_outlined;
  @override
  IconData get appearanceSettings => Icons.palette;
  @override
  IconData get librarySettings => Icons.library_music_outlined;
  @override
  IconData get advancedSettings => Icons.build;
  @override
  IconData get about => Icons.info;

  // Others
  @override
  IconData get contextMenu => Icons.more_horiz;
  @override
  IconData get favorite => Icons.favorite_outline;
  @override
  IconData get navigationLeft => Icons.chevron_left;
  @override
  IconData get navigationRight => Icons.chevron_right;
  @override
  IconData get navigationUp => Icons.keyboard_arrow_up;
  @override
  IconData get navigationDown => Icons.keyboard_arrow_down;
  @override
  IconData get playtime => Icons.schedule;
  @override
  IconData get preference => Icons.tune;
  @override
  IconData get statistic => Icons.bar_chart;
  @override
  IconData get storage => Icons.storage;
}
