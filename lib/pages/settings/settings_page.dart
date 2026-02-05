import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:suara/pages/settings/about_page.dart';
import 'package:suara/pages/settings/general_page.dart';
import 'package:suara/pages/settings/styling_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // If the width is greater than 900, we show the full sidebar.
        final bool showExtended = constraints.maxWidth >= 800;

        return Row(
          children: [
            ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
                child: NavigationRail(
                  extended: showExtended,
                  minWidth: 72,
                  backgroundColor: const Color.fromRGBO(0, 0, 0, 0.2),
                  selectedIndex: _selectedIndex,
                  destinations: const <NavigationRailDestination>[
                    NavigationRailDestination(
                      icon: Icon(Icons.settings_applications_outlined),
                      selectedIcon: Icon(Icons.settings_applications),
                      label: Text('General'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.palette_outlined),
                      selectedIcon: Icon(Icons.palette),
                      label: Text("Styling"),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.info_outline),
                      selectedIcon: Icon(Icons.info),
                      label: Text('About'),
                    ),
                  ],
                  onDestinationSelected: (index) {
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                ),
              ),
            ),

            const VerticalDivider(thickness: 1, width: 1),

            Expanded(
              child: switch (_selectedIndex) {
                // Ideally, use const constructors if your widgets are stateless
                0 => const GeneralPage(),
                1 => const StylingPage(),
                2 => const AboutPage(),
                _ => const GeneralPage(),
              },
            ),
          ],
        );
      },
    );
  }
}
