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
    final theme = Theme.of(context);
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
        backgroundColor: theme.colorScheme.surface,
        leading: Container(
          color:
              theme.navigationRailTheme.backgroundColor ??
              theme.colorScheme.surfaceContainer,
        ),
        leadingWidth: isExtended ? 220 : 64,
        centerTitle: true,
        title: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(22),
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search settings",
                hintStyle: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                prefixIcon: const Icon(Icons.search, size: 20),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onChanged: (value) {
                // Future: Add search filtering logic here
              },
            ),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            isSelected: true,
            icon: Icon(Icons.settings, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(
        children: [
          Sidebar(
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
