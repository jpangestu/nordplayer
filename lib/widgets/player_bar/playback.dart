import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:nordplayer/services/logger.dart';
import 'package:nordplayer/services/player_service.dart';
import 'package:nordplayer/services/preference_service.dart';

class Playback extends StatefulWidget {
  const Playback({super.key});

  @override
  State<Playback> createState() => _PlaybackState();
}

class _PlaybackState extends State<Playback> with LoggerMixin {
  final player = PlayerService().player;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListenableBuilder(
      listenable: PreferenceService(),
      builder: (context, child) {
        final isShuffled = PreferenceService().shuffleMode;
        final loopMode = PreferenceService().loopMode;

        return Row(
          mainAxisAlignment: .center,
          children: [
            IconButton(
              icon: Icon(
                Icons.shuffle,
                color: isShuffled ? colorScheme.primary : null,
              ),
              iconSize: 24,
              onPressed: () => PlayerService().toggleShuffle(),
            ),
            IconButton(
              icon: Icon(Icons.skip_previous),
              iconSize: 24,
              onPressed: () {
                player.previous();
              },
            ),
            ValueListenableBuilder<bool>(
              valueListenable: PlayerService().isPlaying,
              builder: (context, playing, _) {
                return IconButton(
                  isSelected: true,
                  icon: Icon(playing ? Icons.pause_circle : Icons.play_circle),
                  iconSize: 36,
                  onPressed: () => PlayerService().playOrPause(),
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.skip_next),
              iconSize: 24,
              onPressed: () {
                player.next();
              },
            ),
            IconButton(
              icon: Icon(
                switch (loopMode) {
                  PlaylistMode.none => Icons.repeat,
                  PlaylistMode.loop => Icons.repeat,
                  PlaylistMode.single => Icons.repeat_one,
                },
                color: loopMode != PlaylistMode.none
                    ? colorScheme.primary
                    : null,
              ),
              onPressed: () => PlayerService().cycleLoopMode(),
            ),
          ],
        );
      },
    );
  }
}
