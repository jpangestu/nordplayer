import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nordplayer/data/repositories/config_repository.dart';
import 'package:nordplayer/data/repositories/ui_preferences_repository.dart';
import 'package:nordplayer/ui/shared/themes/icon_sets/app_icon_set.dart';
import 'package:nordplayer/ui/shared/ui/app_icon.dart';
import 'package:nordplayer/ui/shell/widgets/nord_sidebar.dart';

class SettingsLayout extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const SettingsLayout({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configRepo = ref.watch(configRepositoryProvider);
    final appConfig = configRepo.currentConfig;
    final appIconSet = ref.watch(appIconProvider);
    final uiPrefsRepo = ref.watch(uiPreferencesRepositoryProvider);
    final mainSidebarExtended = uiPrefsRepo.currentPreferences.sidebarExtended;

    bool isExtended = true;
    final double screenWidth = MediaQuery.sizeOf(context).width;
    if (screenWidth <= 850) {
      isExtended = !mainSidebarExtended;
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
        label: const Text('Library Indexer'),
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
            onDestinationSelected: (index) => navigationShell.goBranch(index, initialLocation: true),
            selectedIndex: navigationShell.currentIndex,
            leading: const SizedBox(height: 16),
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
