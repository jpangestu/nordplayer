import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nordplayer/pages/queue_page.dart';
import 'package:nordplayer/routes/destinations.dart';
import 'package:nordplayer/services/config_service.dart';
import 'package:nordplayer/services/preference_service.dart';
import 'package:nordplayer/widgets/nordplayer_app_bar.dart';
import 'package:nordplayer/widgets/nordplayer_title_bar.dart';
import 'package:nordplayer/widgets/player_bar/player_bar.dart';
import 'package:nordplayer/widgets/shortcuts.dart';
import 'package:nordplayer/widgets/sidebar.dart';

class AppLayout extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const AppLayout({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    bool isExtended = ref.watch(preferenceServiceProvider).sidebarExtended;
    bool showQueue = ref.watch(preferenceServiceProvider).showQueue;
    final appConfig = ref.watch(configServiceProvider).requireValue;
    final colorScheme = Theme.of(context).colorScheme;

    return Shortcuts(
      shortcuts: <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.space): const PlayOrPauseIntent(),
        SingleActivator(LogicalKeyboardKey.arrowRight, control: true): const SkipToNextIntent(),
        SingleActivator(LogicalKeyboardKey.arrowLeft, control: true): const SkipToPreviousIntent(),
        CharacterActivator('s', control: true): const ToggleShuffleIntent(),
        CharacterActivator('l', control: true): const CycleLoopIntent(),
        SingleActivator(LogicalKeyboardKey.arrowUp, control: true): const VolumeUpIntent(),
        SingleActivator(LogicalKeyboardKey.arrowDown, control: true): const VolumeDownIntent(),
        CharacterActivator('m'): const MuteIntent(),
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
                      child: NordplayerTitleBar(),
                    ),

                    const AdaptiveDivider(),

                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            color: colorScheme.surface.withValues(alpha: appConfig.adaptiveBgThemeOverlay),
                            child: Sidebar(
                              isExtended: isExtended,
                              destinations: Destinations.mainDestinations,
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
                                  icon: isExtended ? Icon(LucideIcons.panelLeftClose) : Icon(LucideIcons.panelLeftOpen),
                                  style: IconButton.styleFrom(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                                ),
                              ),
                              extendedWidth: 200,
                              isAdaptiveBgOn: appConfig.adaptiveBg,
                              adaptiveBgPanelBlur: appConfig.adaptiveBgPanelBlur,
                              adaptiveBgThemeOverlay: appConfig.adaptiveBgThemeOverlay,
                            ),
                          ),

                          const AdaptiveVerticalDivider(),

                          Expanded(
                            child: Scaffold(
                              appBar: NordplayerAppBar(),
                              extendBodyBehindAppBar: navigationShell.currentIndex == 0 ? true : false,
                              backgroundColor: Colors.transparent,
                              body: LayoutBuilder(
                                builder: (context, constraints) {
                                  final double pageWidth = constraints.maxWidth;

                                  if (showQueue && isWideScreen) {
                                    return Stack(
                                      children: [
                                        Container(
                                          width: pageWidth,
                                          color: colorScheme.surface.withValues(
                                            alpha: appConfig.adaptiveBgThemeOverlay,
                                          ),
                                        ),

                                        Row(
                                          children: [
                                            Expanded(child: navigationShell),

                                            const AdaptiveVerticalDivider(),

                                            QueuePage(
                                              isWideScreen: isWideScreen,
                                              isAppBarAllowContentBehindIt: navigationShell.currentIndex == 0
                                                  ? true
                                                  : false,
                                            ),
                                          ],
                                        ),
                                      ],
                                    );
                                  }

                                  return Stack(
                                    children: [
                                      // Middle Layer: The Scrim/Dimmer (Only if Queue is open)
                                      Container(
                                        width: showQueue ? pageWidth - 300 : pageWidth,
                                        color: colorScheme.surface.withValues(alpha: appConfig.adaptiveBgThemeOverlay),
                                      ),

                                      navigationShell,

                                      // Top Layer: The Floating Queue (Only if Queue is open)
                                      if (showQueue)
                                        Positioned(
                                          top: 0,
                                          bottom: 0,
                                          right: 0,
                                          child: QueuePage(
                                            isWideScreen: isWideScreen,
                                            isAppBarAllowContentBehindIt: navigationShell.currentIndex == 0,
                                          ),
                                        ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const AdaptiveDivider(),

                    Container(
                      color: colorScheme.surfaceContainer.withValues(alpha: appConfig.adaptiveBgThemeOverlay),
                      child: PlayerBar(),
                    ),
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
