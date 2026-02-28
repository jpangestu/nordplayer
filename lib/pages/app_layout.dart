import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nordplayer/routes/destinations.dart';
import 'package:nordplayer/services/preference_service.dart';
import 'package:nordplayer/widgets/player_bar/player_bar.dart';
import 'package:nordplayer/widgets/sidebar.dart';

class AppLayout extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const AppLayout({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    bool isExtended = ref.watch(preferenceServiceProvider).sidebarExtended;

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Sidebar(
                  selectedIndex:
                      navigationShell.currentIndex <
                          Destinations.mainDestinations.length
                      ? navigationShell.currentIndex
                      : null,
                  destinations: Destinations.mainDestinations,
                  onDestinationSelected: navigationShell.goBranch,
                  showExtendedToggle: true,
                  isExtended: isExtended,
                  onExtendedToggle: () {
                    isExtended = !isExtended;
                    ref
                        .read(preferenceServiceProvider.notifier)
                        .setSidebarExtended(isExtended);
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
