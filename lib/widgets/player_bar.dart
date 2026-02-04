import 'dart:ui';

import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:suara/services/audio_service.dart';
import 'package:suara/widgets/album_art.dart';

class PlayerBar extends StatelessWidget {
  const PlayerBar({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Listen for state changes (Play/Pause, Song Change, Shuffle, Loop)
    return ListenableBuilder(
      listenable: AudioService(),
      builder: (context, _) {
        final audio = AudioService();
        final song = audio.currentSong;

        return ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(
              height: 90,
              width: double.infinity,
              color: const Color.fromRGBO(0, 0, 0, 0.25),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: song == null
                        ? const SizedBox()
                        : ListTile(
                            contentPadding: const EdgeInsets.only(left: 20),
                            leading: AlbumArt(artPath: song.artPath),
                            title: Text(
                              song.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 18,
                              ),
                            ),
                            subtitle: Text(
                              song.artist,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () {},
                          ),
                  ),
                  Expanded(
                    flex: 7,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // LOOP BUTTON
                              IconButton(
                                onPressed: () {
                                  audio.cycleLoopMode();
                                },
                                icon: Icon(switch (audio.loopMode) {
                                  LoopMode.off => Icons.repeat,
                                  LoopMode.all => Icons.repeat_on,
                                  LoopMode.one => Icons.repeat_one_on_outlined,
                                }),
                              ),

                              // PREVIOUS BUTTON
                              IconButton(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                icon: const Icon(Icons.skip_previous),
                                onPressed: () {
                                  audio.previous();
                                },
                              ),

                              // PLAY/PAUSE BUTTON
                              IconButton(
                                iconSize: 40,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                icon: Icon(
                                  audio.isPlaying
                                      ? Icons.pause_circle
                                      : Icons.play_circle,
                                ),
                                onPressed: () {
                                  if (audio.isPlaying) {
                                    audio.pause();
                                  } else {
                                    audio.resume();
                                  }
                                },
                              ),

                              // NEXT BUTTON
                              IconButton(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                icon: const Icon(Icons.skip_next),
                                onPressed: () {
                                  audio.next();
                                },
                              ),

                              // SHUFFLE BUTTON
                              IconButton(
                                onPressed: () {
                                  audio.toggleShuffle();
                                },
                                icon: Icon(
                                  audio.isShuffleEnabled
                                      ? Icons.shuffle_on_outlined
                                      : Icons.shuffle,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // PROGRESS BAR (Kept as Stream for 60fps performance)
                        StreamBuilder<PositionData>(
                          stream: audio.positionDataStream,
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
                                buffered: positionData.bufferedPosition,
                                barHeight: 4,
                                thumbRadius: 7,
                                thumbGlowRadius: 14,
                                timeLabelLocation: TimeLabelLocation.sides,
                                timeLabelType: TimeLabelType.totalTime,
                                onSeek: (newPosition) {
                                  audio.seek(newPosition);
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
            ),
          ),
        );
      },
    );
  }
}
