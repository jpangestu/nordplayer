import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:nordplayer/services/logger.dart';
import 'package:nordplayer/services/player_service.dart';
import 'package:nordplayer/services/preference_service.dart';

class Playback extends ConsumerStatefulWidget {
  const Playback({super.key});

  @override
  ConsumerState<Playback> createState() => _PlaybackState();
}

class _PlaybackState extends ConsumerState<Playback> with LoggerMixin {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final player = ref.watch(playerServiceProvider);
    final isPlaying = ref.watch(isPlayingProvider);
    final isShuffled = ref.watch(preferenceServiceProvider).shuffleMode;
    final loopMode = ref.watch(preferenceServiceProvider).loopMode;

    return Row(
      mainAxisAlignment: .center,
      children: [
        IconButton(
          icon: Icon(
            Icons.shuffle,
            color: isShuffled ? colorScheme.primary : null,
          ),
          iconSize: 24,
          onPressed: () => player.toggleShuffle(),
        ),
        IconButton(
          icon: Icon(Icons.skip_previous),
          iconSize: 24,
          onPressed: () {
            player.previous();
          },
        ),
        IconButton(
          isSelected: true,
          icon: Icon(isPlaying ? Icons.pause_circle : Icons.play_circle),
          iconSize: 36,
          onPressed: () => ref.read(playerServiceProvider).playOrPause(),
        ),
        IconButton(
          icon: Icon(Icons.skip_next),
          iconSize: 24,
          onPressed: () {
            player.next();
          },
        ),
        IconButton(
          icon: Icon(switch (loopMode) {
            PlaylistMode.none => Icons.repeat,
            PlaylistMode.loop => Icons.repeat,
            PlaylistMode.single => Icons.repeat_one,
          }, color: loopMode != PlaylistMode.none ? colorScheme.primary : null),
          onPressed: () => player.cycleLoopMode(),
        ),
      ],
    );
  }
}
