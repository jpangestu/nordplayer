import 'dart:async';

import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:nordplayer/database/app_database.dart';
import 'package:nordplayer/services/logger.dart';
import 'package:nordplayer/services/player_service.dart';
import 'package:nordplayer/services/preference_service.dart';
import 'package:nordplayer/widgets/music_tile.dart';
import 'package:nordplayer/widgets/player_bar/playback.dart';
import 'package:nordplayer/widgets/player_bar/progress_bar.dart';
import 'package:nordplayer/widgets/player_bar/volume_slider.dart';

class PlayerBar extends StatefulWidget {
  const PlayerBar({super.key});

  @override
  State<PlayerBar> createState() => _PlayerBarState();
}

class _PlayerBarState extends State<PlayerBar> with LoggerMixin {
  final player = PlayerService().player;

  @override
  Widget build(BuildContext context) {
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
          StreamBuilder<Playlist>(
            stream: player.stream.playlist,
            builder: (context, snapshot) {
              final playlist = snapshot.data;
              final media = playlist?.medias[playlist.index];
              final song = media?.extras?['data'] as SongWithArtists?;

              if (song == null) {
                return Expanded(flex: lefttFlex, child: const SizedBox());
              }

              return Expanded(
                flex: lefttFlex,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: MusicTile(
                    title: song.track.title,
                    artists: song.artists.map((a) => a.name).toList(),
                    albumArtPath: song.album.albumArtPath,
                    albumArtSize: 60,
                    onTap: () {},
                  ),
                ),
              );
            },
          ),

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
                ListenableBuilder(
                  listenable: PreferenceService(),
                  builder: (context, child) {
                    final volume = PreferenceService().volume;
                    return VolumeSlider(
                      volume: volume,
                      onChanged: (value) {
                        PlayerService().setVolume(value.roundToDouble());
                      },
                    );
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

class ProgressBarSection extends StatefulWidget {
  const ProgressBarSection({super.key});

  @override
  State<ProgressBarSection> createState() => _ProgressBarSectionState();
}

class _ProgressBarSectionState extends State<ProgressBarSection> {
  TimeLabelType timeLabelType = PreferenceService().timeLabelType;

  Duration _position = Duration.zero;
  Duration _total = Duration.zero;
  // Duration _buffered = Duration.zero;

  StreamSubscription<Duration>? _posSub;
  StreamSubscription<Duration?>? _durSub;
  // StreamSubscription<Duration>? _bufSub;

  @override
  void initState() {
    super.initState();
    final player = PlayerService().player;

    // Listen to streams and update local state
    _posSub = player.stream.position.listen((p) {
      if (mounted) setState(() => _position = p);
    });
    _durSub = player.stream.duration.listen((d) {
      if (mounted) setState(() => _total = d);
    });
    // _bufSub = player.stream.buffer.listen((b) {
    //   if (mounted) setState(() => _buffered = b);
    // });
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _durSub?.cancel();
    // _bufSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: PreferenceService(),
      builder: (context, child) {
        return ProgressBar(
          progress: _position,
          // buffered: _buffered,
          total: _total,
          onSeek: (value) => PlayerService().player.seek(value),
          onRightTimeLabelTap: () {
            if (timeLabelType == .totalTime) {
              timeLabelType = .remainingTime;
            } else {
              timeLabelType = .totalTime;
            }
            PreferenceService().setTimeLabelType(timeLabelType);
          },
          barHeight: 5,
          thumbRadius: 6,
          thumbGlowRadius: 14,
          timeLabelTextStyle: TextStyle(fontSize: 14),
          timeLabelType: timeLabelType,
        );
      },
    );
  }
}
