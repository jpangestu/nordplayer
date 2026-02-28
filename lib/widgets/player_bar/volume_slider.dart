import 'package:flutter/material.dart';

class VolumeSlider extends StatefulWidget {
  /// Volume range: 0-1
  final double volume;
  final ValueChanged<double> onChanged;

  const VolumeSlider({
    super.key,
    required this.volume,
    required this.onChanged,
  });

  @override
  State<VolumeSlider> createState() => _VolumeSliderState();
}

class _VolumeSliderState extends State<VolumeSlider> {
  double _lastNonZeroVolume = 0.5;

  @override
  void initState() {
    super.initState();
    if (widget.volume > 0) {
      _lastNonZeroVolume = widget.volume;
    }
  }

  void _handleMuteToggle() {
    if (widget.volume > 0) {
      _lastNonZeroVolume = widget.volume;
      widget.onChanged(0);
    } else {
      final restoreLevel = _lastNonZeroVolume > 0 ? _lastNonZeroVolume : 0.5;
      widget.onChanged(restoreLevel);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sliderTheme = Theme.of(context).sliderTheme;
    final isMuted = widget.volume == 0;

    return Flexible(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(
              isMuted ? Icons.volume_off_outlined : Icons.volume_up_outlined,
              size: 24,
            ),
            tooltip: isMuted ? "Unmute" : "Mute",
            onPressed: _handleMuteToggle,
          ),

          Flexible(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 120),
              child: Padding(
                padding: .only(right: 20),
                child: SliderTheme(
                  data: SliderThemeData(
                    padding: .only(right: 5),
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
                    valueIndicatorTextStyle:
                        sliderTheme.valueIndicatorTextStyle,
                  ),
                  child: Slider(
                    value: widget.volume,
                    min: 0,
                    max: 100,
                    label: '${widget.volume.round()}',
                    onChanged: (value) {
                      // If user drags, update the memory of "last volume"
                      if (value > 0) {
                        _lastNonZeroVolume = value;
                      }
                      widget.onChanged(value);
                    },
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
