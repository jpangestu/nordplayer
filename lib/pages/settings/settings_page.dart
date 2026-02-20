import 'package:flutter/material.dart';
import 'package:nordplayer/pages/settings/about_page.dart';
import 'package:nordplayer/pages/settings/advanced.dart';
import 'package:nordplayer/pages/settings/library_management_page.dart';
import 'package:nordplayer/pages/settings/appearance_page.dart';
import 'package:nordplayer/services/preference_service.dart';
import 'package:nordplayer/widgets/sidebar.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = <Widget>[
    AppearanceSettingPage(),
    LibraryManagementPage(),
    AdvancedPage(),
  ];

  List<SidebarDestination> destinations = <SidebarDestination>[
    SidebarDestination(
      icon: Icon(Icons.palette_outlined),
      selectedIcon: Icon(Icons.palette),
      label: Text('Appearance'),
      subLabel: Text('Themes, fonts, layout, and visual styles'),
    ),
    SidebarDestination(
      icon: Icon(Icons.my_library_music_outlined),
      selectedIcon: Icon(Icons.my_library_music),
      label: Text('Library Management'),
      subLabel: Text('Manage folders, parsing options'),
    ),
    SidebarDestination(
      icon: Icon(Icons.handyman_outlined),
      selectedIcon: Icon(Icons.handyman),
      label: Text('Advanced'),
      subLabel: Text('Reset settings'),
    ),
  ];

  // List<NavigationRailDestination> dest = <NavigationRailDestination>[
  //   NavigationRailDestination(
  //     icon: Icon(Icons.palette_outlined),
  //     selectedIcon: Icon(Icons.palette),
  //     label: Text('Appearance'),
  //   ),
  // ];

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
          ListenableBuilder(
            listenable: PreferenceService(),
            builder: (context, child) {
              bool mainSidebarExtended = PreferenceService().sidebarExtended;
              bool isExtended = true;
              final double screenWidth = MediaQuery.sizeOf(context).width;
              if (screenWidth <= 850) {
                mainSidebarExtended ? isExtended = false : isExtended = true;
              } else {
                isExtended = true;
              }

              return Sidebar(
                leading: SizedBox(height: 24),
                selectedIndex: _selectedIndex,
                destinations: destinations,
                onDestinationSelected: (newIndex) {
                  setState(() {
                    _selectedIndex = newIndex;
                  });
                },
                showExtendedToggle: false,
                isExtended: isExtended,
                trailing: aboutPage(context, isExtended),
                width: 220,
              );
            },
          ),
          Expanded(
            child: IndexedStack(index: _selectedIndex, children: _pages),
          ),
        ],
      ),
    );
  }
}
