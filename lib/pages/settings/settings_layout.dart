import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nordplayer/routes/destinations.dart';
import 'package:nordplayer/services/config_service.dart';
import 'package:nordplayer/services/preference_service.dart';
import 'package:nordplayer/widgets/frosted_glass.dart';
import 'package:nordplayer/widgets/sidebar.dart';

class SettingsLayout extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const SettingsLayout({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appConfig = ref.watch(configServiceProvider).requireValue;
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
      backgroundColor: Colors.transparent,
      body: Row(
        children: [
          FrostedGlass(
            blurSigma: 5,
            child: Sidebar(
              isAdaptive: appConfig.adaptiveBg,
              leading: SizedBox(height: 16),
              selectedIndex: navigationShell.currentIndex,
              destinations: Destinations.settingsDestinations,
              onDestinationSelected: navigationShell.goBranch,
              showExtendedToggle: false,
              isExtended: isExtended,
              width: 220,
            ),
          ),
          Expanded(child: navigationShell),
        ],
      ),
    );
  }
}
