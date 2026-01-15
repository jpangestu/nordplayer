import 'package:flutter/material.dart';

import 'package:suara/pages/library.dart';
import 'package:suara/pages/settings_page.dart';
import 'package:suara/widgets/player_bar.dart';
import 'package:suara/widgets/sidebar.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const Library(),
    const Center(child: Text("Playlist Page")),
    const SettingsPage(),
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
                  onDestinationSelected: (int index) {
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                ),
                // Main Content
                Expanded(child: _pages[_selectedIndex]),
              ],
            ),
          ),

          const PlayerBar(),
        ],
      ),
    );
  }
}
