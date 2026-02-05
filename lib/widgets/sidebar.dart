import 'dart:ui';

import 'package:flutter/material.dart';

class Sidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected; // The "Callback" function

  const Sidebar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: NavigationRail(
          selectedIndex: selectedIndex,
          labelType: NavigationRailLabelType.all,
          backgroundColor: Color.fromRGBO(0, 0, 0, 0.25),
          onDestinationSelected: onDestinationSelected,
          destinations: const <NavigationRailDestination>[
            NavigationRailDestination(
              icon: Icon(Icons.library_music_outlined),
              selectedIcon: Icon(Icons.library_music),
              label: Text("Library"),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.album_outlined),
              selectedIcon: Icon(Icons.album),
              label: Text("Albums"),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: Text("Artists"),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: Text("Settings"),
            ),
          ],
        ),
      ),
    );
  }
}
