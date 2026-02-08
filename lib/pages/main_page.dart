import 'package:flutter/material.dart';
import 'package:nordplayer/pages/albums_page.dart';
import 'package:nordplayer/pages/artists_page.dart';
import 'package:nordplayer/pages/library_page.dart';
import 'package:nordplayer/pages/playlists_page.dart';
import 'package:nordplayer/pages/settings/settings_page.dart';
import 'package:nordplayer/widgets/player_bar/player_bar.dart';
import 'package:nordplayer/widgets/sidebar.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;
  bool isExpanded = false;

  final List<Widget> _pages = const [
    LibraryPage(),
    PlaylistsPage(),
    AlbumsPage(),
    ArtistsPage(),
    SettingsPage(),
  ];

  List<SidebarDestination> destinations = <SidebarDestination>[
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
    SidebarDestination(
      icon: Icon(Icons.settings_outlined),
      selectedIcon: Icon(Icons.settings),
      label: Text('Settings'),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Sidebar(
                  selectedIndex: _selectedIndex,
                  destinations: destinations,
                  onDestinationSelected: (newIndex) {
                    setState(() {
                      _selectedIndex = newIndex;
                    });
                  },
                  showExtendedToggle: true,
                  isExpanded: isExpanded,
                  onExtendedToggle: () {
                    setState(() {
                      isExpanded = !isExpanded;
                    });
                  },
                ),
                VerticalDivider(width: 2,),
                Expanded(
                  child: IndexedStack(index: _selectedIndex, children: _pages),
                ),
              ],
            ),
          ),

          Divider(height: 2,),

          PlayerBar(),
        ],
      ),
    );
  }
}
