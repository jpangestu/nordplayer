import 'package:flutter/material.dart';

class ProgressBar extends StatelessWidget {
  final Duration position;
  final Duration duration;
  final Function(Duration) onSeek;

  const ProgressBar({
    super.key,
    required this.position,
    required this.duration,
    required this.onSeek,
  });

  @override
  Widget build(BuildContext context) {
    // Avoid division by zero errors if song hasn't loaded
    final double max = duration.inMilliseconds.toDouble();
    final double value = position.inMilliseconds.clamp(0, max).toDouble();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(width: 40,),
        Text(_formatDuration(position), style: _timeStyle(context)),
        Expanded(
          child: SliderTheme(
            // Customizing to make the track thinner and dot smaller (Modern look)
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4.0,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14.0),
              activeTrackColor: Theme.of(context).colorScheme.primary,
              inactiveTrackColor: Colors.grey[300],
            ),
            child: Slider(
              min: 0,
              max: max,
              value: value,
              onChanged: (newValue) {
                // This happens while dragging (optional: update UI immediately)
              },
              onChangeEnd: (newValue) {
                // This happens when user lets go (Seek to this time)
                onSeek(Duration(milliseconds: newValue.round()));
              },
            ),
          ),
        ),
        Text(_formatDuration(duration), style: _timeStyle(context)),
        SizedBox(width: 40,),
      ],
    );
  }

  // Helper to style the small text
  TextStyle? _timeStyle(BuildContext context) {
    return Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey);
  }

  // Helper to convert Duration to "MM:SS" string
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }
}