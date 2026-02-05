import 'package:flutter/material.dart';

class Sidebar extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  const Sidebar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  bool extended = false;

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      labelType: extended ? .none : .all,
      extended: extended,
      minWidth: 72,
      backgroundColor: Colors.teal,
      leading: SizedBox(
        width: extended ? 256 : 72,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: EdgeInsets.only(left: 16.0),
            child: IconButton(
              constraints: const BoxConstraints(),
              icon: const Icon(Icons.menu_outlined),
              onPressed: () {
                setState(() {
                  extended = !extended;
                });
              },
            ),
          ),
        ),
      ),
      destinations: const <NavigationRailDestination>[
        NavigationRailDestination(
          icon: Icon(Icons.library_music_outlined),
          selectedIcon: Icon(Icons.library_music),
          label: Text('Library'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.album_outlined),
          selectedIcon: Icon(Icons.album),
          label: Text('Albums'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: Text('Artists'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings),
          label: Text('Settings'),
        ),
      ],
      selectedIndex: widget.selectedIndex,
      onDestinationSelected: widget.onDestinationSelected,
    );
  }
}
