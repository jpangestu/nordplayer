import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:nordplayer/services/logger.dart';
import 'package:nordplayer/services/player_service.dart';
import 'package:nordplayer/services/preference_service.dart';
import 'package:nordplayer/theming/icon-sets/app_icon_set.dart';
import 'package:nordplayer/widgets/app_icon.dart';

class Playback extends ConsumerStatefulWidget {
  const Playback({super.key});

  @override
  ConsumerState<Playback> createState() => _PlaybackState();
}

class _PlaybackState extends ConsumerState<Playback> with LoggerMixin {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appIconSet = ref.watch(appIconProvider);

    final isPlaying = ref.watch(isPlayingProvider);
    final isShuffled = ref.watch(preferenceServiceProvider).shuffleMode;
    final loopMode = ref.watch(preferenceServiceProvider).loopMode;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: AppIcon(appIconSet.shuffle, color: isShuffled ? colorScheme.primary : null),
          iconSize: 24,
          onPressed: () => ref.read(playerServiceProvider).toggleShuffle(),
        ),
        IconButton(
          icon: AppIcon(appIconSet.previous),
          iconSize: 24,
          onPressed: () => ref.read(playerServiceProvider).previous(),
        ),
        IconButton(
          isSelected: true,
          icon: AppIcon(isPlaying ? appIconSet.pause : appIconSet.play),
          iconSize: 36,
          onPressed: () => ref.read(playerServiceProvider).playOrPause(),
        ),
        IconButton(
          icon: AppIcon(appIconSet.next),
          iconSize: 24,
          onPressed: () => ref.read(playerServiceProvider).next(),
        ),
        IconButton(
          icon: AppIcon(switch (loopMode) {
            PlaylistMode.none => appIconSet.repeat,
            PlaylistMode.loop => appIconSet.repeat,
            PlaylistMode.single => appIconSet.repeatOne,
          }, color: loopMode != PlaylistMode.none ? colorScheme.primary : null),
          onPressed: () => ref.read(playerServiceProvider).cycleLoopMode(),
        ),
      ],
    );
  }
}
