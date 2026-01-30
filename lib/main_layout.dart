import 'package:flutter/material.dart';

import 'package:suara/pages/library.dart';
import 'package:suara/pages/settings/settings_layout.dart';
import 'package:suara/widgets/dynamic_background_scaffold.dart';
import 'package:suara/widgets/player_bar.dart';
import 'package:suara/widgets/sidebar.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const Library(),
    const Center(child: Text("Playlist Page")),
    const SettingsLayout(),
  ];

  @override
  Widget build(BuildContext context) {
    final Widget appBody = Row(
      children: [
        Sidebar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (int index) {
            setState(() {
              _selectedIndex = index;
            });
          },
        ),
        const VerticalDivider(width: 1),
        Expanded(child: _pages[_selectedIndex]), // Main Page
      ],
    );

    final Widget playerBar = const PlayerBar();

    return DynamicBackgroundScaffold(
      body: appBody,
      bottomNavigationBar: playerBar,
    );
  }
}
