import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nordplayer/pages/settings/about_page.dart';
import 'package:nordplayer/routes/destinations.dart';
import 'package:nordplayer/services/preference_service.dart';
import 'package:nordplayer/widgets/sidebar.dart';

class SettingsLayout extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const SettingsLayout({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    bool mainSidebarExtended = ref
        .watch(preferenceServiceProvider)
        .sidebarExtended;
    bool isExtended = true;
    final double screenWidth = MediaQuery.sizeOf(context).width;
    if (screenWidth <= 850) {
      mainSidebarExtended ? isExtended = false : isExtended = true;
    } else {
      isExtended = true;
    }

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
            selectedIndex: navigationShell.currentIndex,
            destinations: Destinations.settingsDestinations,
            onDestinationSelected: navigationShell.goBranch,
            showExtendedToggle: false,
            isExtended: isExtended,
            trailing: aboutPage(context, isExtended),
            width: 220,
          ),
          Expanded(child: navigationShell),
        ],
      ),
    );
  }
}
