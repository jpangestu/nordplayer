import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nordplayer/core/theme/icon-sets/app_icon_set.dart';
import 'package:nordplayer/features/shell/player_bar_viewmodel.dart';
import 'package:nordplayer/features/shell/widgets/player_bar/playback.dart';
import 'package:nordplayer/features/shell/widgets/player_bar/progress_bar.dart';
import 'package:nordplayer/features/shell/widgets/player_bar/volume_slider.dart';
import 'package:nordplayer/widgets/app_icon.dart';
import 'package:nordplayer/widgets/frosted_glass.dart';
import 'package:nordplayer/widgets/music_tile.dart';
import 'package:nordplayer/widgets/unimplemented.dart';

/// Top-level player bar component pinned to the bottom of the window.
class NordPlayerBar extends ConsumerWidget {
  const NordPlayerBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final appIconSet = ref.watch(appIconProvider);
    final uiState = ref.watch(playerBarViewModelProvider);
    final viewModel = ref.read(playerBarViewModelProvider.notifier);

    final double screenWidth = MediaQuery.sizeOf(context).width;
    final bool isLargeScreen = screenWidth > 900;
    final int leftFlex = 25;
    final int rightFlex = isLargeScreen ? 25 : 30;
    final int centerFlex = isLargeScreen ? 50 : 35;

    final backgroundColor = theme.colorScheme.surfaceContainer;

    return FrostedGlass(
      blurSigma: uiState.adaptiveBgPanelBlur,
      child: Container(
        height: 90,
        color: uiState.isAdaptiveBgOn
            ? backgroundColor.withValues(alpha: uiState.adaptiveBgThemeOverlay)
            : backgroundColor,
        child: Row(
          children: [
            if (uiState.currentTrack == null) ...[
              Expanded(flex: leftFlex, child: const SizedBox()),
            ] else ...[
              Expanded(
                flex: leftFlex,
                child: MusicTile(
                  title: uiState.currentTrack!.track.title,
                  artists: uiState.currentTrack!.artists.map((a) => a.name).toList(),
                  albumArtPath: uiState.currentTrack!.album.albumArtPath,
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
                    isSelected: uiState.showQueue,
                    tooltip: 'Show Queue',
                    onPressed: viewModel.toggleShowQueue,
                  ),
                  VolumeSlider(
                    volume: uiState.volume,
                    isMuted: uiState.isMuted,
                    onChanged: (value) => viewModel.setVolume(value.roundToDouble()),
                    onMute: viewModel.toggleMute,
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
