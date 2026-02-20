import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nordplayer/routes/destinations.dart';
import 'package:nordplayer/services/preference_service.dart';
import 'package:nordplayer/widgets/player_bar/player_bar.dart';
import 'package:nordplayer/widgets/sidebar.dart';

class AppLayout extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppLayout({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    final prefs = PreferenceService();
    
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                ListenableBuilder(
                  listenable: PreferenceService(),
                  builder: (context, child) {
                    bool isExtended = prefs.sidebarExtended;
                    return Sidebar(
                      selectedIndex: navigationShell.currentIndex,
                      destinations: Destinations.mainDestinations,
                      onDestinationSelected: navigationShell.goBranch,
                      showExtendedToggle: true,
                      isExtended: isExtended,
                      onExtendedToggle: () {
                        isExtended = !isExtended;
                        prefs.setSidebarExtended(isExtended);
                      },
                    );
                  },
                ),

                VerticalDivider(width: 2, thickness: 2),

                Expanded(child: navigationShell),
              ],
            ),
          ),
          Divider(height: 2, thickness: 2),
          PlayerBar(),
        ],
      ),
    );
  }
}
