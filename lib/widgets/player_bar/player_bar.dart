import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nordplayer/services/logger.dart';
import 'package:nordplayer/services/player_service.dart';
import 'package:nordplayer/services/preference_service.dart';
import 'package:nordplayer/widgets/music_tile.dart';
import 'package:nordplayer/widgets/player_bar/playback.dart';
import 'package:nordplayer/widgets/player_bar/progress_bar.dart';
import 'package:nordplayer/widgets/player_bar/volume_slider.dart';

class PlayerBar extends ConsumerStatefulWidget {
  const PlayerBar({super.key});

  @override
  ConsumerState<PlayerBar> createState() => _PlayerBarState();
}

class _PlayerBarState extends ConsumerState<PlayerBar> with LoggerMixin {
  @override
  Widget build(BuildContext context) {
    final player = ref.watch(playerServiceProvider);
    final currentSong = ref.watch(currentSongProvider).value;

    final double screenWidth = MediaQuery.sizeOf(context).width;
    bool isLargeScreen = screenWidth > 900;
    final int lefttFlex = isLargeScreen ? 25 : 25;
    final int rightFlex = isLargeScreen ? 25 : 30;
    final int centerFlex = isLargeScreen ? 50 : 35;

    return Container(
      height: 90,
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: Row(
        children: [
          if (currentSong == null) ...[
            Expanded(flex: lefttFlex, child: const SizedBox()),
          ] else ...[
            Expanded(
              flex: lefttFlex,
              child: MusicTile(
                title: currentSong.track.title,
                artists: currentSong.artists.map((a) => a.name).toList(),
                albumArtPath: currentSong.album.albumArtPath,
                albumArtSize: 60,
                onTap: () {},
                padding: const .only(left: 16),
                marqueeEffect: true,
              ),
            ),
          ],

          // StreamBuilder<Playlist>(
          //   stream: player.mkPlayer.stream.playlist,
          //   builder: (context, snapshot) {
          //     final playlist = snapshot.data;
          //     final media = playlist?.medias[playlist.index];
          //     final song = media?.extras?['data'] as SongWithArtists?;

          //     if (song == null) {
          //       return Expanded(flex: lefttFlex, child: const SizedBox());
          //     }

          //     return Expanded(
          //       flex: lefttFlex,
          //       child: Padding(
          //         padding: const EdgeInsets.only(left: 8),
          //         child: MusicTile(
          //           title: song.track.title,
          //           artists: song.artists.map((a) => a.name).toList(),
          //           albumArtPath: song.album.albumArtPath,
          //           albumArtSize: 60,
          //           onTap: () {},
          //           marqueeEffect: true,
          //         ),
          //       ),
          //     );
          //   },
          // ),

          Expanded(
            flex: centerFlex,
            child: Column(
              mainAxisAlignment: .center,
              children: [
                Playback(),
                Padding(
                  padding: .fromLTRB(20, 0, 20, 6),
                  child: ProgressBarSection(),
                ),
              ],
            ),
          ),
          Expanded(
            flex: rightFlex,
            child: Row(
              mainAxisAlignment: .end,
              children: [
                IconButton(
                  icon: const Icon(Icons.lyrics_outlined),
                  iconSize: 24,
                  tooltip: 'Show Lyrics',
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.queue_music_outlined),
                  iconSize: 24,
                  tooltip: 'Show Queue',
                  onPressed: () {},
                ),
                VolumeSlider(
                  volume: ref.watch(preferenceServiceProvider).volume,
                  onChanged: (value) {
                    player.setVolume(value.roundToDouble());
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ProgressBarSection extends ConsumerWidget {
  const ProgressBarSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final position = ref.watch(positionStreamProvider).value ?? Duration.zero;
    // final buffer = ref.watch(bufferStreamProvider).value ?? Duration.zero;
    final total = ref.watch(durationStreamProvider).value ?? Duration.zero;
    TimeLabelType timeLabelType = ref
        .watch(preferenceServiceProvider)
        .timeLabelType;

    return ProgressBar(
      progress: position,
      // buffered: _buffered,
      total: total,
      onSeek: (value) => ref.read(playerServiceProvider).mkPlayer.seek(value),
      onRightTimeLabelTap: () {
        final newType = timeLabelType == TimeLabelType.totalTime
            ? TimeLabelType.remainingTime
            : TimeLabelType.totalTime;

        ref.read(preferenceServiceProvider.notifier).setTimeLabelType(newType);
      },
      barHeight: 5,
      thumbRadius: 6,
      thumbGlowRadius: 14,
      timeLabelTextStyle: TextStyle(fontSize: 14),
      timeLabelType: timeLabelType,
    );
  }
}
