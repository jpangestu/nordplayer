import 'package:flutter/gestures.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

class const VolumeSlider({
  super.key,
  required final double volume,
  required final bool isMuted,
  required final ValueChanged<double> onChanged,
  required final VoidCallback onMute,
  final double scrollStep = 5.0,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tooltipTextStyle =
        theme.textTheme.labelSmall?.copyWith(
          color: colorScheme.onInverseSurface,
          fontWeight: FontWeight.bold,
          height: 1.0,
          fontFeatures: const [FontFeature.tabularFigures()],
        ) ??
        TextStyle(
          color: colorScheme.onInverseSurface,
          fontWeight: FontWeight.bold,
          height: 1.0,
          fontFeatures: const [FontFeature.tabularFigures()],
        );

    final effectiveVolume = isMuted ? 0.0 : volume.clamp(0.0, 100.0);
    final icon = switch (effectiveVolume) {
      <= 0 => LucideIcons.volumeOff,
      <= 50 => LucideIcons.volume1,
      _ => LucideIcons.volume2,
    };

    return Listener(
      onPointerSignal: (event) {
        if (event is PointerScrollEvent && event.scrollDelta.dy != 0) {
          GestureBinding.instance.pointerSignalResolver.register(event, (resolvedEvent) {
            if (resolvedEvent is! PointerScrollEvent) return;
            final delta = resolvedEvent.scrollDelta.dy < 0 ? scrollStep : -scrollStep;
            final next = (effectiveVolume + delta).clamp(0.0, 100.0);
            if (next != effectiveVolume) {
              onChanged(next);
            }
          });
        }
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(icon, size: 20),
            tooltip: isMuted ? 'Unmute' : 'Mute',
            onPressed: onMute,
            padding: const .all(4),
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            style: const ButtonStyle(tapTargetSize: .shrinkWrap),
          ),
          Flexible(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 120),
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  padding: const .symmetric(horizontal: 6),
                  trackHeight: 3,
                  showValueIndicator: .onDrag,
                  tickMarkShape: SliderTickMarkShape.noTickMark,
                  valueIndicatorShape: const _VolumeTooltipShape(),
                  valueIndicatorColor: colorScheme.inverseSurface,
                  valueIndicatorTextStyle: tooltipTextStyle,
                ),
                child: Slider(
                  value: effectiveVolume,
                  min: 0,
                  max: 100,
                  divisions: 100,
                  label: '${effectiveVolume.round()}',
                  onChanged: onChanged,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VolumeTooltipShape extends SliderComponentShape {
  const _VolumeTooltipShape();

  static const double _horizontalPadding = 8.0;
  static const double _verticalPadding = 5.5;
  static const double _triangleHeight = 5.0;
  static const double _verticalGap = 2.0;

  @override
  Size getPreferredSize(
    bool isEnabled,
    bool isDiscrete, {
    TextPainter? labelPainter,
    double? textScaleFactor,
  }) {
    if (labelPainter == null) return Size.zero;
    final scaledFontSize = labelPainter.textScaler.scale(
      labelPainter.text?.style?.fontSize ?? 11.0,
    );
    final capHeight = scaledFontSize * 0.72;
    return Size(
      labelPainter.width + _horizontalPadding * 2,
      capHeight + _verticalPadding * 2 + _triangleHeight,
    );
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final scale = activationAnimation.value;
    if (scale == 0.0) return;

    final canvas = context.canvas;
    final thumbRadius =
        (sliderTheme.thumbShape?.getPreferredSize(true, isDiscrete).shortestSide ?? 12.0) / 2;

    final baseline = labelPainter.computeDistanceToActualBaseline(TextBaseline.alphabetic);
    final scaledFontSize = labelPainter.textScaler.scale(
      labelPainter.text?.style?.fontSize ?? 11.0,
    );
    final capHeight = scaledFontSize * 0.72;

    final bubbleWidth = labelPainter.width + _horizontalPadding * 2;
    final bubbleHeight = capHeight + _verticalPadding * 2;
    final bubbleBottom = -_verticalGap - _triangleHeight;
    final tooltipCenterY = bubbleBottom - bubbleHeight / 2;

    final tooltipRect = Rect.fromCenter(
      center: Offset(0, tooltipCenterY),
      width: bubbleWidth,
      height: bubbleHeight,
    );
    final tooltipRRect = RRect.fromRectAndRadius(tooltipRect, const Radius.circular(6));
    final bgPaint = Paint()..color = sliderTheme.valueIndicatorColor ?? Colors.black;

    final trianglePath = Path()
      ..moveTo(-5, tooltipRect.bottom - 1)
      ..lineTo(5, tooltipRect.bottom - 1)
      ..lineTo(0, tooltipRect.bottom + _triangleHeight)
      ..close();

    canvas.save();
    canvas.translate(center.dx, center.dy - thumbRadius);
    canvas.scale(scale, scale);

    canvas.drawRRect(tooltipRRect, bgPaint);
    canvas.drawPath(trianglePath, bgPaint);
    labelPainter.paint(
      canvas,
      Offset(-labelPainter.width / 2, tooltipCenterY - (baseline - capHeight / 2)),
    );

    canvas.restore();
  }
}
