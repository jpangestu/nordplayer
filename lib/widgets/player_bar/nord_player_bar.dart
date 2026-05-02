import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nordplayer/services/config_service.dart';
import 'package:nordplayer/services/logger.dart';
import 'package:nordplayer/services/player_service.dart';
import 'package:nordplayer/services/preference_service.dart';
import 'package:nordplayer/theming/icon-sets/app_icon_set.dart';
import 'package:nordplayer/utils/unimplemented.dart';
import 'package:nordplayer/widgets/app_icon.dart';
import 'package:nordplayer/widgets/frosted_glass.dart';
import 'package:nordplayer/widgets/music_tile.dart';
import 'package:nordplayer/widgets/player_bar/playback.dart';
import 'package:nordplayer/widgets/player_bar/progress_bar.dart';
import 'package:nordplayer/widgets/player_bar/volume_slider.dart';

class NordPlayerBar extends ConsumerStatefulWidget {
  const NordPlayerBar({super.key});

  @override
  ConsumerState<NordPlayerBar> createState() => _PlayerBarState();
}

class _PlayerBarState extends ConsumerState<NordPlayerBar> with LoggerMixin {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appConfig = ref.watch(configServiceProvider).requireValue;

    final player = ref.watch(playerServiceProvider);
    final currentTrack = ref.watch(currentTrackProvider);
    final isAdaptiveBgOn = ref.watch(configServiceProvider).value?.adaptiveBg ?? false;
    final appIconSet = ref.watch(appIconProvider);

    final double screenWidth = MediaQuery.sizeOf(context).width;
    bool isLargeScreen = screenWidth > 900;
    final int lefttFlex = isLargeScreen ? 25 : 25;
    final int rightFlex = isLargeScreen ? 25 : 30;
    final int centerFlex = isLargeScreen ? 50 : 35;

    final backgroundColor = theme.colorScheme.surfaceContainer;

    return FrostedGlass(
      blurSigma: appConfig.adaptiveBgPanelBlur,
      child: Container(
        height: 90,
        color: isAdaptiveBgOn ? backgroundColor.withValues(alpha: appConfig.adaptiveBgThemeOverlay) : backgroundColor,
        child: Row(
          children: [
            if (currentTrack == null) ...[
              Expanded(flex: lefttFlex, child: const SizedBox()),
            ] else ...[
              Expanded(
                flex: lefttFlex,
                child: MusicTile(
                  title: currentTrack.track.title,
                  artists: currentTrack.artists.map((a) => a.name).toList(),
                  albumArtPath: currentTrack.album.albumArtPath,
                  albumArtSize: 60,
                  onTap: () {},
                  padding: const .only(left: 16),
                  marqueeEffect: true,
                ),
              ),
            ],

            Expanded(
              flex: centerFlex,
              child: const Column(
                mainAxisAlignment: .center,
                children: [
                  Playback(),
                  Padding(padding: .fromLTRB(20, 0, 20, 6), child: ProgressBarSection()),
                ],
              ),
            ),
            Expanded(
              flex: rightFlex,
              child: Row(
                mainAxisAlignment: .end,
                children: [
                  IconButton(
                    icon: AppIcon(appIconSet.lyrics),
                    iconSize: 24,
                    tooltip: 'Show Lyrics',
                    onPressed: () {
                      unimplemented(context);
                    },
                  ),
                  IconButton(
                    icon: AppIcon(appIconSet.queue),
                    iconSize: 24,
                    tooltip: 'Show Queue',
                    // isSelected: true,
                    onPressed: () {
                      final showQueue = ref.read(preferenceServiceProvider).showQueue;
                      ref.read(preferenceServiceProvider.notifier).setShowQueue(!showQueue);
                    },
                  ),
                  VolumeSlider(
                    volume: ref.watch(preferenceServiceProvider).volume,
                    isMuted: ref.watch(preferenceServiceProvider).isMuted,
                    onChanged: (value) {
                      player.setVolume(value.roundToDouble());
                    },
                    onMute: () {
                      player.toggleMute();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
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
    TimeLabelType timeLabelType = ref.watch(preferenceServiceProvider).timeLabelType;

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
      timeLabelTextStyle: const TextStyle(fontSize: 14),
      timeLabelType: timeLabelType,
    );
  }
}
