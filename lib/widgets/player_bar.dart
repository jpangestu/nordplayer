import 'package:flutter/material.dart';
import 'package:suara/models/song.dart';
import 'package:suara/services/audio_manager.dart';

import 'package:suara/widgets/position_data.dart';
import 'package:suara/widgets/progress_bar.dart';

class PlayerBar extends StatelessWidget {
  const PlayerBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90 + 10,
      width: double.infinity,
      color: Colors.blueGrey,
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: StreamBuilder<Song?>(
              stream: AudioManager().currentSongStream,
              builder: (context, snapshot) {
                if(!snapshot.hasData) {
                  return SizedBox();
                }

                return Column(
                  mainAxisAlignment: .center,
                  crossAxisAlignment: .start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      child: Text(snapshot.data!.title, maxLines: 1, overflow: .ellipsis, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 18),)
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      child: Text(snapshot.data!.artist, maxLines: 1, overflow: .ellipsis,),
                    )
                
                  ],
                );
              },
            ),
          ),
          Expanded(
            flex: 7,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        onPressed: () {},
                        icon: Icon(Icons.repeat),
                      ),
                      IconButton(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        onPressed: () {},
                        icon: Icon(Icons.skip_previous),
                      ),
                      StreamBuilder<bool>(
                        stream: AudioManager().playingStream,
                        builder: (context, snapshot) {
                          final isPlaying = snapshot.data ?? false;

                          return IconButton(
                            iconSize: 40,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            icon: Icon(
                              isPlaying
                                  ? Icons.pause_circle
                                  : Icons.play_circle,
                            ),
                            onPressed: () {
                              if (isPlaying) {
                                AudioManager().pause();
                              } else {
                                AudioManager().resume();
                              }
                            },
                          );
                        },
                      ),
                      IconButton(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        onPressed: () {},
                        icon: Icon(Icons.skip_next),
                      ),
                      IconButton(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        onPressed: () {},
                        icon: Icon(Icons.shuffle),
                      ),
                    ],
                  ),
                ),
                StreamBuilder(
                  stream: AudioManager().positionDataStream,
                  builder: (context, snapshot) {
                    final positionData =
                        snapshot.data ??
                        PositionData(
                          Duration.zero,
                          Duration.zero,
                          Duration.zero,
                        );

                    return ProgressBar(
                      position: positionData.position,
                      duration: positionData.duration,
                      onSeek: (newPosition) {
                        AudioManager().seek(newPosition);
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
