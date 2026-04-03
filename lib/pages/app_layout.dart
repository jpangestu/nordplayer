import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nordplayer/pages/queue_page.dart';
import 'package:nordplayer/routes/destinations.dart';
import 'package:nordplayer/services/config_service.dart';
import 'package:nordplayer/services/preference_service.dart';
import 'package:nordplayer/widgets/frosted_glass.dart';
import 'package:nordplayer/widgets/nordplayer_app_bar.dart';
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

    return Shortcuts(
      shortcuts: <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.space): const PlayOrPauseIntent(),
        SingleActivator(LogicalKeyboardKey.arrowRight, control: true):
            const SkipToNextIntent(),
        SingleActivator(LogicalKeyboardKey.arrowLeft, control: true):
            const SkipToPreviousIntent(),
        CharacterActivator('s', control: true): const ToggleShuffleIntent(),
        CharacterActivator('l', control: true): const CycleLoopIntent(),
        SingleActivator(LogicalKeyboardKey.arrowUp, control: true):
            const VolumeUpIntent(),
        SingleActivator(LogicalKeyboardKey.arrowDown, control: true):
            const VolumeDownIntent(),
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
                    Expanded(
                      child: Row(
                        children: [
                          FrostedGlass(
                            blurSigma: 10,
                            child: Sidebar(
                              isAdaptive: appConfig.adaptiveBg,
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
                          ),

                          appConfig.adaptiveBg
                              ? VerticalDivider(
                                  width: 2,
                                  thickness: 2,
                                  color: Colors.transparent,
                                )
                              : const VerticalDivider(width: 2, thickness: 2),

                          Expanded(
                            child: Scaffold(
                              appBar: NordplayerAppBar(),
                              extendBodyBehindAppBar:
                                  navigationShell.currentIndex == 0
                                  ? true
                                  : false,
                              backgroundColor: Colors.transparent,
                              body: Stack(
                                children: [
                                  // --- LAYER 1: PAGES + PINNED QUEUE---
                                  Row(
                                    children: [
                                      Expanded(child: navigationShell),

                                      appConfig.adaptiveBg
                                          ? VerticalDivider(
                                              width: 2,
                                              thickness: 2,
                                              color: Colors.transparent,
                                            )
                                          : const VerticalDivider(
                                              width: 2,
                                              thickness: 2,
                                            ),

                                      if (showQueue && isWideScreen)
                                        QueuePage(
                                          isWideScreen: isWideScreen,
                                          isAppBarAllowContentBehindIt:
                                              navigationShell.currentIndex == 0
                                              ? true
                                              : false,
                                        ),
                                    ],
                                  ),

                                  // --- LAYER 2: FLOATING QUEUE ---
                                  if (showQueue && !isWideScreen) ...[
                                    Positioned(
                                      top: 0,
                                      bottom: 0,
                                      right: 0,
                                      child: QueuePage(
                                        isWideScreen: isWideScreen,
                                        isAppBarAllowContentBehindIt:
                                            navigationShell.currentIndex == 0
                                            ? true
                                            : false,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    appConfig.adaptiveBg
                        ? Divider(
                            height: 2,
                            thickness: 2,
                            color: Colors.transparent,
                          )
                        : const Divider(height: 2, thickness: 2),

                    FrostedGlass(blurSigma: 10, child: PlayerBar()),
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
