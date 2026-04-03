import 'package:flutter/material.dart';

class SliderTile extends StatefulWidget {
  final Widget? leading;
  final String label;
  final double value;
  final double min;
  final double max;
  final String Function(double) labelBuilder;
  final ValueChanged<double>? onChanged;
  final ValueChanged<double>? onChangeEnd;

  const SliderTile({
    super.key,
    this.leading,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.labelBuilder,
    this.onChanged,
    this.onChangeEnd,
  });

  @override
  State<SliderTile> createState() => _SliderTileState();
}

class _SliderTileState extends State<SliderTile> {
  late double _localValue;

  @override
  void initState() {
    super.initState();
    _localValue = widget.value;
  }

  @override
  void didUpdateWidget(covariant SliderTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _localValue = widget.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: widget.leading,
      title: Row(
        crossAxisAlignment: .center,
        children: [
          SizedBox(
            width: widget.leading != null ? 160 - 40 : 160, // 40 is the width of the leading icon
            child: Text(
              widget.label,
              style: const TextStyle(fontWeight: FontWeight.w500, height: 1.0),
            ),
          ),

          const SizedBox(width: 8),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(
                context,
              ).copyWith(overlayShape: SliderComponentShape.noOverlay),
              child: Slider(
                value: _localValue,
                min: widget.min,
                max: widget.max,
                onChanged: (val) {
                  setState(() => _localValue = val);
                  widget.onChanged?.call(val);
                },
                onChangeEnd: widget.onChangeEnd,
              ),
            ),
          ),

          const SizedBox(width: 8),

          SizedBox(
            width: 48,
            child: Text(
              widget.labelBuilder(_localValue),
              textAlign: TextAlign.left,
              style: const TextStyle(
                fontFeatures: [FontFeature.tabularFigures()],
                height: 1.0,
              ),
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}
