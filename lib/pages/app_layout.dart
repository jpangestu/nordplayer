import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nordplayer/routes/destinations.dart';
import 'package:nordplayer/services/preference_service.dart';
import 'package:nordplayer/widgets/player_bar/player_bar.dart';
import 'package:nordplayer/widgets/shortcuts.dart';
import 'package:nordplayer/widgets/sidebar.dart';

class AppLayout extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const AppLayout({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    bool isExtended = ref.watch(preferenceServiceProvider).sidebarExtended;

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
          child: Scaffold(
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
          ),
        ),
      ),
    );
  }
}
