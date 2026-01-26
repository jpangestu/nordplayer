import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:suara/models/song.dart';
import 'package:suara/services/audio_manager.dart';
import 'package:suara/widgets/position_data.dart';
// import 'package:suara/widgets/progress_bar.dart';

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
                if (!snapshot.hasData) {
                  return SizedBox();
                }

                return Column(
                  mainAxisAlignment: .center,
                  crossAxisAlignment: .start,
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.only(left: 30),
                      title: Text(
                        snapshot.data!.title,
                        maxLines: 1,
                        overflow: .ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 18,
                        ),
                      ),
                      subtitle: Text(
                        snapshot.data!.artist,
                        maxLines: 1,
                        overflow: .ellipsis,
                      ),
                      onTap: () {},
                    ),
                  ],
                );
              },
            ),
          ),
          Expanded(
            flex: 7,
            child: Column(
              mainAxisAlignment: .center,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      StreamBuilder(
                        stream: AudioManager().loopModeStream,
                        initialData: AudioManager().loopMode,
                        builder: (context, snapshot) {
                          final loopMode = snapshot.data ?? LoopMode.off;
                          return IconButton(
                            onPressed: () {
                              AudioManager().cycleLoopMode();
                            },
                            icon: Icon(switch (loopMode) {
                              LoopMode.off => Icons.repeat,
                              LoopMode.all => Icons.repeat_on,
                              LoopMode.one => Icons.repeat_one_on_outlined,
                            }),
                          );
                        },
                      ),
                      IconButton(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        icon: Icon(Icons.skip_previous),
                        onPressed: () {
                          AudioManager().previous();
                        },
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
                        icon: Icon(Icons.skip_next),
                        onPressed: () {
                          AudioManager().next();
                        },
                      ),
                      StreamBuilder(
                        stream: AudioManager().shuffleModeStream,
                        initialData: AudioManager().isShuffleEnabled,
                        builder: (context, snapshot) {
                          bool isShuffle = snapshot.data ?? false;
                          return IconButton(
                            onPressed: () {
                              AudioManager().toggleShuffle();
                            },
                            icon: Icon(
                              isShuffle
                                  ? Icons.shuffle_on_outlined
                                  : Icons.shuffle,
                            ),
                          );
                        },
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

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      child: ProgressBar(
                        progress: positionData.position,
                        buffered: positionData.duration,
                        total: positionData.duration,
                        timeLabelLocation: TimeLabelLocation.sides,
                        // timeLabelPadding: 20,
                        onSeek: (newPosition) {
                          AudioManager().seek(newPosition);
                        },
                      ),
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
