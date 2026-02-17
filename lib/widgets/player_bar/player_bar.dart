import 'package:flutter/material.dart';
import 'package:nordplayer/services/logger.dart';
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
  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.sizeOf(context).width;
    bool isLargeScreen = screenWidth > 900;
    final int lefttFlex = isLargeScreen ? 25 : 25;
    final int rightFlex = isLargeScreen ? 25 : 30;
    final int centerFlex = isLargeScreen ? 50 : 35;

    return ListenableBuilder(
      listenable: PreferenceService(),
      builder: (context, child) {
        double volume = PreferenceService().volume;

        return Container(
          height: 90,
          color: Theme.of(context).colorScheme.surfaceContainer,
          child: Row(
            children: [
              Expanded(
                flex: lefttFlex,
                child: Padding(
                  padding: .only(left: 8),
                  child: MusicTile(
                    title: 'Let Love Win',
                    artists: ['TheFatRat'],
                    albumArtPath: 'assets/let_love_win.jpg',
                    albumArtSize: 60,
                    marqueEffect: true,
                    onTap: () {},
                  ),
                ),
              ),
              Expanded(
                flex: centerFlex,
                child: Column(
                  mainAxisAlignment: .center,
                  children: [
                    Playback(),
                    Padding(
                      padding: .fromLTRB(20, 0, 20, 6),
                      child: ProgressBarSection(total: Duration(minutes: 12)),
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
                      volume: volume,
                      onChanged: (value) {
                        PreferenceService().setVolume(value);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Extracted to isolate the frequent setState()
class ProgressBarSection extends StatefulWidget {
  final Duration total;

  const ProgressBarSection({super.key, required this.total});

  @override
  State<ProgressBarSection> createState() => _ProgressBarSectionState();
}

class _ProgressBarSectionState extends State<ProgressBarSection> {
  Duration _progress = Duration.zero;
  TimeLabelType timeLabelType = PreferenceService().timeLabelType;
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: PreferenceService(),
      builder: (context, child) {
        return ProgressBar(
          total: Duration(minutes: 12),
          progress: _progress,
          // buffered: Duration(minutes: 9),
          onSeek: (value) {
            setState(() {
              _progress = value;
            });
          },
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
