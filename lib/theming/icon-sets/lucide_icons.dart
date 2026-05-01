import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nordplayer/theming/icon-sets/app_icon_set.dart';

class LucideIconSet implements AppIconSet {
  @override
  double get opticalScale => 0.9;

  // Top Bar
  @override
  IconData get keyboardShortcut => LucideIcons.zap;
  @override
  IconData get search => LucideIcons.search;

  // Sidebar
  @override
  IconData get sidebarClose => LucideIcons.panelLeftClose;
  @override
  IconData get sidebarOpen => LucideIcons.panelLeftOpen;
  @override
  IconData get library => LucideIcons.library;
  @override
  IconData get albums => LucideIcons.disc3;
  @override
  IconData get allTracks => LucideIcons.music;
  @override
  IconData get artists => LucideIcons.users;
  @override
  IconData get genres => LucideIcons.tags;
  @override
  IconData get playlist => LucideIcons.listMusic;

  // Player Bar
  @override
  IconData get play => LucideIcons.circlePlay;
  @override
  IconData get pause => LucideIcons.circlePause;
  @override
  IconData get next => LucideIcons.skipForward;
  @override
  IconData get previous => LucideIcons.skipBack;
  @override
  IconData get repeat => LucideIcons.repeat;
  @override
  IconData get repeatOne => LucideIcons.repeat1;
  @override
  IconData get shuffle => LucideIcons.shuffle;
  @override
  IconData get lyrics => LucideIcons.micVocal;
  @override
  IconData get queue => LucideIcons.listVideo;
  @override
  IconData get volumeHigh => LucideIcons.volume2;
  @override
  IconData get volumeLow => LucideIcons.volume1;
  @override
  IconData get volumeMute => LucideIcons.volumeOff;

  // Settings
  @override
  IconData get settings => LucideIcons.settings;
  @override
  IconData get appearanceSettings => LucideIcons.palette;
  @override
  IconData get librarySettings => LucideIcons.squareLibrary;
  @override
  IconData get advancedSettings => LucideIcons.wrench;
  @override
  IconData get about => LucideIcons.info;

  // Others
  @override
  IconData get contextMenu => LucideIcons.ellipsis;
  @override
  IconData get favorite => LucideIcons.heart;
  @override
  IconData get navigationLeft => LucideIcons.chevronLeft;
  @override
  IconData get navigationRight => LucideIcons.chevronRight;
  @override
  IconData get navigationUp => LucideIcons.chevronUp;
  @override
  IconData get navigationDown => LucideIcons.chevronDown;
  @override
  IconData get playtime => LucideIcons.clock;
  @override
  IconData get preference => LucideIcons.settings2;
  @override
  IconData get statistic => LucideIcons.chartNoAxesColumn;
  @override
  IconData get storage => LucideIcons.hardDrive;
}
