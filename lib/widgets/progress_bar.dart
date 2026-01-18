import 'package:flutter/material.dart';

class ProgressBar extends StatelessWidget {
  final Duration position;
  final Duration duration;
  final ValueChanged<Duration> onSeek;

  const ProgressBar({
    super.key,
    required this.position,
    required this.duration,
    required this.onSeek,
  });

  @override
  Widget build(BuildContext context) {
    // If the song hasn't loaded (duration is 0), we force max to 1.0 to avoid "Division by Zero" errors.
    final double max = duration.inMilliseconds.toDouble();
    final double safeMax = max > 0 ? max : 1.0;

    // If sync lag makes position > duration, cap it at max.
    final double value = position.inMilliseconds.toDouble();
    final double safeValue = value > safeMax ? safeMax : value;

    return Slider(
      min: 0.0,
      max: safeMax,
      value: safeValue,
      onChanged: (newValue) {
        onSeek(Duration(milliseconds: newValue.toInt()));
      },
    );
  }
}
