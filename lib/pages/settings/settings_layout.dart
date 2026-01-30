import 'package:flutter/material.dart';
import 'package:suara/pages/settings/about.dart';
import 'package:suara/pages/settings/general.dart';
import 'package:suara/pages/settings/styling.dart';

class SettingsLayout extends StatefulWidget {
  const SettingsLayout({super.key});

  @override
  State<SettingsLayout> createState() => _SettingsLayoutState();
}

class _SettingsLayoutState extends State<SettingsLayout> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        NavigationRail(
          extended: true,
          backgroundColor: Color.fromRGBO(0, 0, 0, 0.2),
          selectedIndex: _selectedIndex,
          destinations: const <NavigationRailDestination>[
            NavigationRailDestination(
              icon: Icon(Icons.settings_applications_outlined),
              selectedIcon: Icon(Icons.settings_applications),
              label: Text('General'),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.settings_display_outlined),
              selectedIcon: Icon(Icons.settings_display),
              label: Text("Theme & Style"),
            ),
            NavigationRailDestination(icon: Icon(Icons.info_outline), label: Text('About'))
          ],
          onDestinationSelected: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
        ),

        const VerticalDivider(thickness: 1, width: 1),
        
        Expanded(
          child: switch (_selectedIndex) {
            0 => General(),
            1 => Styling(),
            2 => About(),
            _ => General(),
          },
        ),
      ],
    );
  }
}
