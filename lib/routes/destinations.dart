import 'package:flutter/material.dart';
import 'package:nordplayer/widgets/sidebar.dart';

class Destinations {
  /// Destinations for the main sidebar
  static const List<SidebarDestination> mainDestinations = <SidebarDestination>[
    SidebarDestination(
      icon: Icon(Icons.library_music_outlined),
      selectedIcon: Icon(Icons.library_music),
      label: Text('Library'),
    ),
    SidebarDestination(
      icon: Icon(Icons.playlist_play_outlined),
      selectedIcon: Icon(Icons.playlist_play),
      label: Text('Playlists'),
    ),
    SidebarDestination(
      icon: Icon(Icons.album_outlined),
      selectedIcon: Icon(Icons.album),
      label: Text('Albums'),
    ),
    SidebarDestination(
      icon: Icon(Icons.person_outline),
      selectedIcon: Icon(Icons.person),
      label: Text('Artists'),
    ),
  ];

  /// Destinations for the settings sidebar
  static const List<SidebarDestination> settingsDestinations =
      <SidebarDestination>[
        SidebarDestination(
          icon: Icon(Icons.palette_outlined),
          selectedIcon: Icon(Icons.palette),
          label: Text('Appearance'),
          // subLabel: Text('Themes, fonts, layout, and visual styles'),
        ),
        SidebarDestination(
          icon: Icon(Icons.my_library_music_outlined),
          selectedIcon: Icon(Icons.my_library_music),
          label: Text('Library Management'),
          // subLabel: Text('Manage folders, parsing options'),
        ),
        SidebarDestination(
          icon: Icon(Icons.handyman_outlined),
          selectedIcon: Icon(Icons.handyman),
          label: Text('Advanced'),
          // subLabel: Text('Reset settings'),
        ),
      ];
}
