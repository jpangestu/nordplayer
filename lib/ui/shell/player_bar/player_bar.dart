import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nordplayer/config/app_config.dart';
import 'package:nordplayer/ui/shell/adaptive_surface.dart';
import 'package:nordplayer/ui/shell/player_bar/progress_bar.dart';
import 'package:nordplayer/ui/shell/player_bar/volume_slider.dart';

class PlayerBar extends ConsumerWidget {
  const PlayerBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appConfig = ref.watch(appConfigProvider);
    final playerBarHeight = ref.watch(appConfig.ui.playerBar.height.provider);

    return AdaptiveSurface(
      elevation: .mid,
      height: playerBarHeight,
      padding: const .symmetric(horizontal: 16),
      child: Row(
        children: [
          const Expanded(flex: 2, child: Placeholder()),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: Column(
              mainAxisAlignment: .center,
              crossAxisAlignment: .center,
              children: [
                Row(
                  crossAxisAlignment: .center,
                  mainAxisAlignment: .center,
                  mainAxisSize: .min,
                  children: [
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(LucideIcons.shuffle),
                      iconSize: 17,
                      tooltip: 'Shuffle',
                      visualDensity: .compact,
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(LucideIcons.skipBack),
                      iconSize: 18,
                      tooltip: 'Previous',
                      visualDensity: .compact,
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(LucideIcons.play),
                      iconSize: 24,
                      tooltip: 'Play',
                      visualDensity: .compact,
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(LucideIcons.skipForward),
                      iconSize: 18,
                      tooltip: 'Next',
                      visualDensity: .compact,
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(LucideIcons.repeat),
                      iconSize: 17,
                      tooltip: 'Repeat',
                      visualDensity: .compact,
                    ),
                  ],
                ),
                const ProgressBar(progress: Duration.zero, total: Duration.zero),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: Align(
              alignment: .centerRight,
              child: SizedBox(
                width: 160,
                child: VolumeSlider(volume: 100, isMuted: false, onChanged: (_) {}, onMute: () {}),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
