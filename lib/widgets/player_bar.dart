import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:suara/models/song.dart';
import 'package:suara/services/audio_service.dart';
import 'package:suara/widgets/album_art.dart';
import 'package:suara/widgets/position_data.dart';

class PlayerBar extends StatelessWidget {
  const PlayerBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      width: double.infinity,
      color: Colors.blueGrey,
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: StreamBuilder<Song?>(
              stream: AudioService().currentSongStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return SizedBox();
                }

                return ListTile(
                  contentPadding: EdgeInsets.only(left: 20),
                  leading: AlbumArt(artPath: snapshot.data!.artPath),
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
                        stream: AudioService().loopModeStream,
                        initialData: AudioService().loopMode,
                        builder: (context, snapshot) {
                          final loopMode = snapshot.data ?? LoopMode.off;
                          return IconButton(
                            onPressed: () {
                              AudioService().cycleLoopMode();
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
                          AudioService().previous();
                        },
                      ),
                      StreamBuilder<bool>(
                        stream: AudioService().playingStream,
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
                                AudioService().pause();
                              } else {
                                AudioService().resume();
                              }
                            },
                          );
                        },
                      ),
                      IconButton(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        icon: Icon(Icons.skip_next),
                        onPressed: () {
                          AudioService().next();
                        },
                      ),
                      StreamBuilder(
                        stream: AudioService().shuffleModeStream,
                        initialData: AudioService().isShuffleEnabled,
                        builder: (context, snapshot) {
                          bool isShuffle = snapshot.data ?? false;
                          return IconButton(
                            onPressed: () {
                              AudioService().toggleShuffle();
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
                  stream: AudioService().positionDataStream,
                  builder: (context, snapshot) {
                    final positionData =
                        snapshot.data ??
                        PositionData(
                          Duration.zero,
                          Duration.zero,
                          Duration.zero,
                        );

                    return Padding(
                      padding: const EdgeInsets.fromLTRB(30, 5, 30, 5),
                      child: ProgressBar(
                        progress: positionData.position,
                        total: positionData.duration,
                        barHeight: 4,
                        thumbRadius: 7,
                        thumbGlowRadius: 14,
                        timeLabelLocation: TimeLabelLocation.sides,
                        timeLabelType: TimeLabelType.totalTime,
                        onSeek: (newPosition) {
                          AudioService().seek(newPosition);
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
