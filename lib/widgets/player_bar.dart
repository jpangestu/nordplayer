import 'package:flutter/material.dart';
import 'package:nordplayer/widgets/progress_bar.dart';

class PlayerBar extends StatefulWidget {
  const PlayerBar({super.key});

  @override
  State<PlayerBar> createState() => _PlayerBarState();
}

class _PlayerBarState extends State<PlayerBar> {
  Duration progress = Duration(minutes: 1);
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      width: double.infinity,
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: Row(
        children: [
          Expanded(
            flex: 35,
            child: ListTile(
              leading: Icon(Icons.music_note_outlined),
              title: Text('Let Love Win'),
              subtitle: Text('TheFatRat'),
            ),
          ),
          Expanded(
            flex: 65,
            child: Column(
              mainAxisAlignment: .center,
              crossAxisAlignment: .center,
              children: [
                Padding(
                  padding: .symmetric(horizontal: 20),
                  child: ProgressBar(
                    barHeight: 4,
                    thumbRadius: 8,
                    thumbGlowRadius: 20,
                    progress: progress,
                    total: Duration(hours: 12, minutes: 3),
                    onSeek: (value) {
                      setState(() {
                        progress = value;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
