import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nordplayer/core/theme/icon-sets/app_icon_set.dart';
import 'package:nordplayer/features/queue/queue_view.dart';
import 'package:nordplayer/features/shell/viewmodels/shell_viewmodel.dart';
import 'package:nordplayer/features/shell/widgets/nord_app_bar.dart';
import 'package:nordplayer/features/shell/widgets/nord_sidebar.dart';
import 'package:nordplayer/features/shell/widgets/player_bar/nord_player_bar.dart';
import 'package:nordplayer/features/shell/widgets/search_result_panel.dart';
import 'package:nordplayer/features/shell/widgets/title_bar/nord_title_bar.dart';
import 'package:nordplayer/widgets/app_icon.dart';

/// Top-level layout coordinating title bar, responsive sidebar, main route viewport,
/// slide-out queue panel, and player bar.
class AppLayout extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const AppLayout({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shellState = ref.watch(shellViewModelProvider);
    final shellViewModel = ref.read(shellViewModelProvider.notifier);
    final appIconSet = ref.watch(appIconProvider);

    // IMPORTANT: Orders matters! Must align with routes/router.dart branches
    final destinations = <SidebarDestination>[
      SidebarDestination(
        icon: AppIcon(appIconSet.library),
        label: const Text('Library'),
      ),
      SidebarDestination(
        icon: AppIcon(appIconSet.tracks),
        label: const Text('Tracks'),
      ),
      SidebarDestination(
        icon: AppIcon(appIconSet.playlist),
        label: const Text('Playlists'),
      ),
      SidebarDestination(
        icon: AppIcon(appIconSet.albums),
        label: const Text('Albums'),
      ),
      SidebarDestination(
        icon: AppIcon(appIconSet.artists),
        label: const Text('Artists'),
      ),
      SidebarDestination(
        icon: AppIcon(appIconSet.settings),
        label: const Text('Settings'),
        alignToBottom: true,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isWideScreen = constraints.maxWidth >= 1080;

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Column(
            children: [
              const NordTitleBar(),
              const AdaptiveDivider(),
              Expanded(
                child: Row(
                  children: [
                    Sidebar(
                      isExtended: shellState.isSidebarExtended,
                      destinations: destinations,
                      onDestinationSelected: (index) =>
                          navigationShell.goBranch(index, initialLocation: true),
                      selectedIndex: navigationShell.currentIndex,
                      leading: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        child: IconButton(
                          padding: .zero,
                          constraints: const BoxConstraints(),
                          onPressed: shellViewModel.toggleSidebar,
                          icon: shellState.isSidebarExtended
                              ? AppIcon(appIconSet.sidebarClose)
                              : AppIcon(appIconSet.sidebarOpen),
                          style: IconButton.styleFrom(
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ),
                      extendedWidth: 200,
                      isAdaptiveBgOn: shellState.isAdaptiveBg,
                      adaptiveBgPanelBlur: shellState.adaptiveBgPanelBlur,
                      adaptiveBgThemeOverlay: shellState.adaptiveBgThemeOverlay,
                    ),

                    const AdaptiveVerticalDivider(),

                    // --- MAIN PAGES
                    Expanded(
                      child: Scaffold(
                        appBar: const NordAppBar(),
                        backgroundColor: Colors.transparent,
                        body: Stack(
                          children: [
                            navigationShell,
                            if (shellState.showQueue && !isWideScreen)
                              const Positioned(
                                top: 0,
                                bottom: 0,
                                right: 0,
                                child: QueueView(),
                              ),

                            // Aligns perfectly under the AppBar's centerTitle
                            const Align(
                              alignment: Alignment.topCenter,
                              child: SearchResultsDropdown(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (shellState.showQueue && isWideScreen) ...[
                      const AdaptiveVerticalDivider(),
                      const QueueView(),
                    ],
                  ],
                ),
              ),

              const AdaptiveDivider(),
              const NordPlayerBar(),
            ],
          ),
        );
      },
    );
  }
}

/// Divider that dynamically respects adaptive background themes and opacity.
class AdaptiveDivider extends ConsumerWidget {
  const AdaptiveDivider({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdaptiveBg = ref.watch(shellViewModelProvider.select((s) => s.isAdaptiveBg));
    final overlay = ref.watch(shellViewModelProvider.select((s) => s.adaptiveBgThemeOverlay));

    if (!isAdaptiveBg) {
      return Divider(height: 2, thickness: 2, color: Theme.of(context).colorScheme.outlineVariant);
    }

    return Divider(
      height: 2,
      thickness: 2,
      color: overlay != 1.0
          ? Colors.transparent
          : Theme.of(context).colorScheme.outlineVariant,
    );
  }
}

/// Vertical divider that dynamically respects adaptive background themes and opacity.
class AdaptiveVerticalDivider extends ConsumerWidget {
  const AdaptiveVerticalDivider({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdaptiveBg = ref.watch(shellViewModelProvider.select((s) => s.isAdaptiveBg));
    final overlay = ref.watch(shellViewModelProvider.select((s) => s.adaptiveBgThemeOverlay));

    if (!isAdaptiveBg) {
      return VerticalDivider(
        width: 2,
        thickness: 2,
        color: Theme.of(context).colorScheme.outlineVariant,
      );
    }

    return VerticalDivider(
      width: 2,
      thickness: 2,
      color: overlay != 1.0
          ? Colors.transparent
          : Theme.of(context).colorScheme.outlineVariant,
    );
  }
}
