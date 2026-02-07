import 'package:flutter/material.dart';
import 'package:nordplayer/widgets/player_bar/playback.dart';
import 'package:nordplayer/widgets/player_bar/progress_bar.dart';
import 'package:nordplayer/widgets/player_bar/volume_slider.dart';

class PlayerBar extends StatefulWidget {
  const PlayerBar({super.key});

  @override
  State<PlayerBar> createState() => _PlayerBarState();
}

class _PlayerBarState extends State<PlayerBar> {
  Duration _progress = Duration(minutes: 1);
  double _volume = 0.5;

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
          Expanded(
            flex: lefttFlex,
            child: ListTile(
              leading: Icon(Icons.music_note_outlined),
              title: Text('Let Love Win'),
              subtitle: Text('TheFatRat'),
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
                  child: ProgressBar(
                    barHeight: 5,
                    thumbRadius: 6,
                    thumbGlowRadius: 14,
                    timeLabelTextStyle: TextStyle(fontSize: 14),
                    progress: _progress,
                    // buffered: Duration(minutes: 9),
                    total: Duration(minutes: 12),
                    onSeek: (value) {
                      setState(() {
                        _progress = value;
                      });
                    },
                  ),
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
                  volume: _volume,
                  onChanged: (value) {
                    setState(() {
                      _volume = value;
                    });
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
