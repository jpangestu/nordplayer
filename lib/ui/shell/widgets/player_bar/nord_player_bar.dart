import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nordplayer/ui/shared/themes/icon_sets/app_icon_set.dart';
import 'package:nordplayer/ui/shared/ui/app_icon.dart';
import 'package:nordplayer/ui/shared/ui/frosted_glass.dart';
import 'package:nordplayer/ui/shared/ui/music_tile.dart';
import 'package:nordplayer/ui/shared/ui/unimplemented.dart';
import 'package:nordplayer/ui/shell/player_bar_viewmodel.dart';
import 'package:nordplayer/ui/shell/widgets/player_bar/playback.dart';
import 'package:nordplayer/ui/shell/widgets/player_bar/progress_bar.dart';
import 'package:nordplayer/ui/shell/widgets/player_bar/volume_slider.dart';

/// Top-level player bar component pinned to the bottom of the window.
class NordPlayerBar extends ConsumerWidget {
  const NordPlayerBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isAdaptiveBgOn = ref.watch(playerBarViewModelProvider.select((s) => s.isAdaptiveBgOn));
    final adaptiveBgPanelBlur = ref.watch(playerBarViewModelProvider.select((s) => s.adaptiveBgPanelBlur));
    final adaptiveBgThemeOverlay = ref.watch(playerBarViewModelProvider.select((s) => s.adaptiveBgThemeOverlay));

    final double screenWidth = MediaQuery.sizeOf(context).width;
    final bool isLargeScreen = screenWidth > 900;
    final int leftFlex = 25;
    final int rightFlex = isLargeScreen ? 25 : 30;
    final int centerFlex = isLargeScreen ? 50 : 35;

    final backgroundColor = theme.colorScheme.surfaceContainer;

    return FrostedGlass(
      blurSigma: adaptiveBgPanelBlur,
      child: Container(
        height: 90,
        color: isAdaptiveBgOn
            ? backgroundColor.withValues(alpha: adaptiveBgThemeOverlay)
            : backgroundColor,
        child: Row(
          children: [
            Expanded(
              flex: leftFlex,
              child: const PlayerBarTrackSection(),
            ),
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
              child: const PlayerBarActionsSection(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Track info section isolated from high-frequency playback position ticks.
class PlayerBarTrackSection extends ConsumerWidget {
  const PlayerBarTrackSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTrack = ref.watch(playerBarViewModelProvider.select((s) => s.currentTrack));
    if (currentTrack == null) {
      return const SizedBox();
    }

    return MusicTile(
      title: currentTrack.track.title,
      artists: currentTrack.artists.map((a) => a.name).toList(),
      albumArtPath: currentTrack.album.albumArtPath,
      albumArtSize: 60,
      onTap: () {},
      padding: const .only(left: 16),
      marqueeEffect: true,
    );
  }
}

/// Action buttons section (lyrics, queue, volume) isolated from position updates.
class PlayerBarActionsSection extends ConsumerWidget {
  const PlayerBarActionsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appIconSet = ref.watch(appIconProvider);
    final showQueue = ref.watch(playerBarViewModelProvider.select((s) => s.showQueue));
    final volume = ref.watch(playerBarViewModelProvider.select((s) => s.volume));
    final isMuted = ref.watch(playerBarViewModelProvider.select((s) => s.isMuted));
    final viewModel = ref.read(playerBarViewModelProvider.notifier);

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
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
          isSelected: showQueue,
          tooltip: 'Show Queue',
          onPressed: viewModel.toggleShowQueue,
        ),
        VolumeSlider(
          volume: volume,
          isMuted: isMuted,
          onChanged: (value) => viewModel.setVolume(value.roundToDouble()),
          onMute: viewModel.toggleMute,
        ),
      ],
    );
  }
}

/// Progress bar section binding position, duration, and time label actions to the ViewModel.
class ProgressBarSection extends ConsumerWidget {
  const ProgressBarSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final position = ref.watch(playerBarViewModelProvider.select((s) => s.position));
    final duration = ref.watch(playerBarViewModelProvider.select((s) => s.duration));
    final timeLabelType = ref.watch(playerBarViewModelProvider.select((s) => s.timeLabelType));
    final viewModel = ref.read(playerBarViewModelProvider.notifier);

    return ProgressBar(
      progress: position,
      total: duration,
      onSeek: viewModel.seek,
      onRightTimeLabelTap: viewModel.toggleTimeLabelType,
      barHeight: 5,
      thumbRadius: 6,
      thumbGlowRadius: 14,
      timeLabelType: timeLabelType,
    );
  }
}
