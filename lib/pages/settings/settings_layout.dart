import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nordplayer/services/config_service.dart';
import 'package:nordplayer/services/preference_service.dart';
import 'package:nordplayer/theming/icon-sets/app_icon_set.dart';
import 'package:nordplayer/widgets/app_icon.dart';
import 'package:nordplayer/widgets/sidebar.dart';

class SettingsLayout extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const SettingsLayout({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appConfig = ref.watch(configServiceProvider).requireValue;
    final appIconSet = ref.watch(appIconProvider);
    bool mainSidebarExtended = ref.watch(preferenceServiceProvider).sidebarExtended;
    bool isExtended = true;
    final double screenWidth = MediaQuery.sizeOf(context).width;
    if (screenWidth <= 850) {
      mainSidebarExtended ? isExtended = false : isExtended = true;
    } else {
      isExtended = true;
    }

    // IMPORTANT: Orders matters! Should refer to router.dart
    final destinations = <SidebarDestination>[
      SidebarDestination(
        icon: AppIcon(appIconSet.appearanceSettings),
        selectedIcon: AppIcon(appIconSet.appearanceSettings),
        label: const Text('Appearance'),
      ),
      SidebarDestination(
        icon: AppIcon(appIconSet.librarySettings),
        selectedIcon: AppIcon(appIconSet.librarySettings),
        label: const Text('Library Management'),
      ),
      SidebarDestination(
        icon: AppIcon(appIconSet.advancedSettings),
        selectedIcon: AppIcon(appIconSet.advancedSettings),
        label: const Text('Advanced'),
      ),
      SidebarDestination(
        icon: AppIcon(appIconSet.about),
        selectedIcon: AppIcon(appIconSet.about),
        label: const Text('About'),
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Row(
        children: [
          Sidebar(
            isExtended: isExtended,
            destinations: destinations,
            onDestinationSelected: navigationShell.goBranch,
            selectedIndex: navigationShell.currentIndex,
            leading: SizedBox(height: 16),
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
            extendedWidth: 220,
            isAdaptiveBgOn: appConfig.adaptiveBg,
            adaptiveBgPanelBlur: appConfig.adaptiveBgPanelBlur,
            adaptiveBgThemeOverlay: appConfig.adaptiveBgThemeOverlay,
          ),
          Expanded(child: navigationShell),
        ],
      ),
    );
  }
}
