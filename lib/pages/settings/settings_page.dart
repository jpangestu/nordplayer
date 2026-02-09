import 'package:flutter/material.dart';
import 'package:nordplayer/pages/settings/about_page.dart';
import 'package:nordplayer/pages/settings/advanced.dart';
import 'package:nordplayer/pages/settings/library_setting_page.dart';
import 'package:nordplayer/pages/settings/styling_page.dart';
import 'package:nordplayer/widgets/sidebar.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool showExtendedToggle = false;
  bool isExpanded = true;
  int _selectedIndex = 0;

  final List<Widget> _pages = <Widget>[
    StylingSettingPage(),
    LibrarySettingPage(),
    AdvancedPage(),
  ];

  List<SidebarDestination> destinations = <SidebarDestination>[
    SidebarDestination(
      icon: Icon(Icons.palette_outlined),
      selectedIcon: Icon(Icons.palette),
      label: Text('Styling'),
    ),
    SidebarDestination(
      icon: Icon(Icons.my_library_music_outlined),
      selectedIcon: Icon(Icons.my_library_music),
      label: Text('Library'),
    ),
    SidebarDestination(
      icon: Icon(Icons.handyman_outlined),
      selectedIcon: Icon(Icons.handyman),
      label: Text('Advanced'),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
        centerTitle: true,
        backgroundColor: Theme.of(context).navigationRailTheme.backgroundColor,
      ),
      body: Row(
        children: [
          Sidebar(
            leading: SizedBox(height: 24),
            selectedIndex: _selectedIndex,
            destinations: destinations,
            onDestinationSelected: (newIndex) {
              setState(() {
                _selectedIndex = newIndex;
              });
            },
            showExtendedToggle: false,
            isExpanded: isExpanded,
            bottom: aboutPage(context, isExpanded),
          ),
          Expanded(
            child: IndexedStack(index: _selectedIndex, children: _pages),
          ),
        ],
      ),
    );
  }
}
