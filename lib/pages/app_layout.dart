import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nordplayer/pages/queue_page.dart';
import 'package:nordplayer/services/config_service.dart';
import 'package:nordplayer/services/preference_service.dart';
import 'package:nordplayer/theming/icon-sets/app_icon_set.dart';
import 'package:nordplayer/widgets/app_icon.dart';
import 'package:nordplayer/widgets/nord_app_bar.dart';
import 'package:nordplayer/widgets/nord_sidebar.dart';
import 'package:nordplayer/widgets/nord_title_bar.dart';
import 'package:nordplayer/widgets/player_bar/nord_player_bar.dart';
import 'package:nordplayer/widgets/shortcuts.dart';

class AppLayout extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const AppLayout({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    bool isExtended = ref.watch(preferenceServiceProvider).sidebarExtended;
    bool showQueue = ref.watch(preferenceServiceProvider).showQueue;
    final appConfig = ref.watch(configServiceProvider).requireValue;
    final colorScheme = Theme.of(context).colorScheme;
    final appIconSet = ref.watch(appIconProvider);

    // IMPORTANT: Orders matters! Should refer to router.dart
    final destinations = <SidebarDestination>[
      SidebarDestination(
        icon: AppIcon(appIconSet.library),
        selectedIcon: AppIcon(appIconSet.library),
        label: const Text('Library'),
      ),
      SidebarDestination(
        icon: AppIcon(appIconSet.allTracks),
        selectedIcon: AppIcon(appIconSet.allTracks),
        label: const Text('All Tracks'),
      ),
      SidebarDestination(
        icon: AppIcon(appIconSet.playlist),
        selectedIcon: AppIcon(appIconSet.playlist),
        label: const Text('Playlists'),
      ),
      SidebarDestination(
        icon: AppIcon(appIconSet.albums),
        selectedIcon: AppIcon(appIconSet.albums),
        label: const Text('Albums'),
      ),
      SidebarDestination(
        icon: AppIcon(appIconSet.artists),
        selectedIcon: AppIcon(appIconSet.artists),
        label: const Text('Artists'),
      ),
    ];

    return Shortcuts(
      shortcuts: <ShortcutActivator, Intent>{
        const SingleActivator(LogicalKeyboardKey.space): const PlayOrPauseIntent(),
        const SingleActivator(LogicalKeyboardKey.arrowRight, control: true): const SkipToNextIntent(),
        const SingleActivator(LogicalKeyboardKey.arrowLeft, control: true): const SkipToPreviousIntent(),
        const CharacterActivator('s', control: true): const ToggleShuffleIntent(),
        const CharacterActivator('l', control: true): const CycleLoopIntent(),
        const SingleActivator(LogicalKeyboardKey.arrowUp, control: true): const VolumeUpIntent(),
        const SingleActivator(LogicalKeyboardKey.arrowDown, control: true): const VolumeDownIntent(),
        const CharacterActivator('m'): const MuteIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          PlayOrPauseIntent: PlayOrPauseAction(ref),
          SkipToNextIntent: SkipToNextAction(ref),
          SkipToPreviousIntent: SkipToPreviousAction(ref),
          ToggleShuffleIntent: ToggleShuffleAction(ref),
          CycleLoopIntent: CycleLoopAction(ref),
          VolumeUpIntent: VolumeUpAction(ref),
          VolumeDownIntent: VolumeDownAction(ref),
          MuteIntent: MuteAction(ref),
        },
        child: Focus(
          autofocus: true,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final bool isWideScreen = constraints.maxWidth > 1080;

              return Scaffold(
                backgroundColor: Colors.transparent,
                body: Column(
                  children: [
                    Container(
                      color: colorScheme.surfaceContainer.withValues(alpha: appConfig.adaptiveBgThemeOverlay),
                      child: const NordTitleBar(),
                    ),

                    const AdaptiveDivider(),

                    Expanded(
                      child: Row(
                        children: [
                          Sidebar(
                            isExtended: isExtended,
                            destinations: destinations,
                            onDestinationSelected: navigationShell.goBranch,
                            selectedIndex: navigationShell.currentIndex,
                            leading: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                              child: IconButton(
                                padding: .zero,
                                constraints: const BoxConstraints(),
                                onPressed: () {
                                  isExtended = !isExtended;
                                  ref.read(preferenceServiceProvider.notifier).setSidebarExtended(isExtended);
                                },
                                icon: isExtended ? AppIcon(appIconSet.sidebarClose) : AppIcon(appIconSet.sidebarOpen),
                                style: IconButton.styleFrom(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                              ),
                            ),
                            extendedWidth: 200,
                            isAdaptiveBgOn: appConfig.adaptiveBg,
                            adaptiveBgPanelBlur: appConfig.adaptiveBgPanelBlur,
                            adaptiveBgThemeOverlay: appConfig.adaptiveBgThemeOverlay,
                          ),

                          const AdaptiveVerticalDivider(),

                          // --- MAIN PAGES
                          Expanded(
                            child: Scaffold(
                              appBar: const NordAppBar(),
                              backgroundColor: Colors.transparent,
                              body: Stack(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(child: navigationShell),
                                      if (showQueue && isWideScreen) ...[
                                        const AdaptiveVerticalDivider(),
                                        QueuePage(isWideScreen: isWideScreen),
                                      ],
                                    ],
                                  ),
                                  if (showQueue && !isWideScreen)
                                    Positioned(
                                      top: 0,
                                      bottom: 0,
                                      right: 0,
                                      child: QueuePage(isWideScreen: isWideScreen),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const AdaptiveDivider(),

                    const NordPlayerBar(),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class AdaptiveDivider extends ConsumerWidget {
  const AdaptiveDivider({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appConfig = ref.watch(configServiceProvider).requireValue;

    if (!appConfig.adaptiveBg) {
      return const Divider(height: 2, thickness: 2);
    }

    return Divider(
      height: 2,
      thickness: 2,
      color: appConfig.adaptiveBgThemeOverlay != 1.0
          ? Colors.transparent
          : Theme.of(context).dividerTheme.color!.withValues(alpha: appConfig.adaptiveBgThemeOverlay),
    );
  }
}

class AdaptiveVerticalDivider extends ConsumerWidget {
  const AdaptiveVerticalDivider({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appConfig = ref.watch(configServiceProvider).requireValue;

    if (!appConfig.adaptiveBg) {
      return const VerticalDivider(width: 2, thickness: 2);
    }

    return VerticalDivider(
      width: 2,
      thickness: 2,
      color: appConfig.adaptiveBgThemeOverlay != 1.0
          ? Colors.transparent
          : Theme.of(context).dividerTheme.color!.withValues(alpha: appConfig.adaptiveBgThemeOverlay),
    );
  }
}
