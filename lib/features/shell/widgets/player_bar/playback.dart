import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_kit/media_kit.dart';
import 'package:nordplayer/core/theme/icon-sets/app_icon_set.dart';
import 'package:nordplayer/features/shell/viewmodels/player_bar_viewmodel.dart';
import 'package:nordplayer/widgets/app_icon.dart';

/// Presentation widget for playback controls (shuffle, previous, play/pause, next, loop).
class Playback extends ConsumerWidget {
  const Playback({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final appIconSet = ref.watch(appIconProvider);

    final isPlaying = ref.watch(playerBarViewModelProvider.select((s) => s.isPlaying));
    final isShuffled = ref.watch(playerBarViewModelProvider.select((s) => s.isShuffle));
    final loopMode = ref.watch(playerBarViewModelProvider.select((s) => s.loopMode));
    final viewModel = ref.read(playerBarViewModelProvider.notifier);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: AppIcon(appIconSet.shuffle, color: isShuffled ? colorScheme.primary : null),
          iconSize: 24,
          onPressed: viewModel.toggleShuffle,
        ),
        IconButton(
          icon: AppIcon(appIconSet.previous),
          iconSize: 24,
          onPressed: viewModel.previous,
        ),
        IconButton(
          isSelected: true,
          icon: AppIcon(isPlaying ? appIconSet.pause : appIconSet.play),
          iconSize: 36,
          onPressed: viewModel.playOrPause,
        ),
        IconButton(
          icon: AppIcon(appIconSet.next),
          iconSize: 24,
          onPressed: viewModel.next,
        ),
        IconButton(
          icon: AppIcon(switch (loopMode) {
            PlaylistMode.none => appIconSet.repeat,
            PlaylistMode.loop => appIconSet.repeat,
            PlaylistMode.single => appIconSet.repeatOne,
          }, color: loopMode != PlaylistMode.none ? colorScheme.primary : null),
          iconSize: 24,
          onPressed: viewModel.cycleLoopMode,
        ),
      ],
    );
  }
}
