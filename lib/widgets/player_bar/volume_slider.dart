import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nordplayer/theming/icon-sets/app_icon_set.dart';
import 'package:nordplayer/widgets/app_icon.dart';

class VolumeSlider extends ConsumerWidget {
  final double volume;
  final bool isMuted;
  final ValueChanged<double> onChanged;
  final VoidCallback onMute;

  const VolumeSlider({
    super.key,
    required this.volume,
    required this.isMuted,
    required this.onChanged,
    required this.onMute,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sliderTheme = Theme.of(context).sliderTheme;
    final appIconSet = ref.watch(appIconProvider);

    return Flexible(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: AppIcon(
              isMuted
                  ? appIconSet.volumeMute
                  : volume > 50
                  ? appIconSet.volumeHigh
                  : appIconSet.volumeLow,
              size: 24,
            ),
            tooltip: isMuted ? "Unmute" : "Mute",
            onPressed: onMute,
          ),
          Flexible(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 120),
              child: Padding(
                padding: const EdgeInsets.only(right: 20),
                child: SliderTheme(
                  data: SliderThemeData(
                    padding: const EdgeInsets.only(right: 5),
                    trackHeight: 3,
                    trackShape: sliderTheme.trackShape,
                    activeTrackColor: sliderTheme.activeTrackColor,
                    inactiveTrackColor: sliderTheme.inactiveTrackColor,
                    thumbColor: sliderTheme.thumbColor,
                    thumbShape: sliderTheme.thumbShape,
                    overlayColor: sliderTheme.overlayColor,
                    overlayShape: sliderTheme.overlayShape,
                    showValueIndicator: .onDrag,
                    valueIndicatorColor: sliderTheme.valueIndicatorColor,
                    valueIndicatorTextStyle: sliderTheme.valueIndicatorTextStyle,
                  ),
                  child: Slider(
                    value: isMuted ? 0.0 : volume,
                    min: 0,
                    max: 100,
                    divisions: 100,
                    label: isMuted ? '0' : '${volume.round()}',
                    onChanged: onChanged,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
