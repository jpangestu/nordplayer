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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Sidebar(
                  isExpanded: isExpanded,
                  selectedIndex: _selectedIndex,
                  onIndexChanged: (newIndex) {
                    setState(() {
                      _selectedIndex = newIndex;
                    });
                  },
                  onToggle: () {
                    setState(() {
                      isExpanded = !isExpanded;
                    });
                  },
                ),
                VerticalDivider(),
                Expanded(
                  child: IndexedStack(index: _selectedIndex, children: _pages),
                ),
              ],
            ),
          ),

          Divider(),

          PlayerBar(),
        ],
      ),
    );
  }
}
