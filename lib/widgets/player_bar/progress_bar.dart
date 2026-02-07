import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

// A modified version of audio_video_progress_bar
// https://pub.dev/packages/audio_video_progress_bar (MIT License)

enum TimeLabelType { totalTime, remainingTime }

class ProgressBar extends LeafRenderObjectWidget {
  const ProgressBar({
    super.key,
    required this.progress,
    required this.total,
    this.buffered,
    this.onSeek,
    this.onDragStart,
    this.onDragUpdate,
    this.onDragEnd,
    this.barHeight = 5.0,
    this.baseBarColor,
    this.progressBarColor,
    this.bufferedBarColor,
    this.thumbRadius = 10.0,
    this.thumbColor,
    this.thumbGlowColor,
    this.thumbGlowRadius = 30.0,
    this.thumbCanPaintOutsideBar = true,
    this.timeLabelType,
    this.timeLabelTextStyle,
    this.timeLabelPadding = 0.0,
  });

  final Duration progress;
  final Duration total;
  final Duration? buffered;
  final ValueChanged<Duration>? onSeek;
  final ThumbDragStartCallback? onDragStart;
  final ThumbDragUpdateCallback? onDragUpdate;
  final VoidCallback? onDragEnd;
  final double barHeight;
  final Color? baseBarColor;
  final Color? progressBarColor;
  final Color? bufferedBarColor;
  final double thumbRadius;
  final Color? thumbColor;
  final Color? thumbGlowColor;
  final double thumbGlowRadius;
  final bool thumbCanPaintOutsideBar;
  final TimeLabelType? timeLabelType;
  final TextStyle? timeLabelTextStyle;
  final double timeLabelPadding;

  @override
  RenderObject createRenderObject(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final sliderTheme = SliderTheme.of(context);
    final textStyle = timeLabelTextStyle ?? theme.textTheme.bodyLarge;
    final textScaler = MediaQuery.textScalerOf(context);
    return _RenderProgressBar(
      progress: progress,
      total: total,
      buffered: buffered ?? Duration.zero,
      onSeek: onSeek,
      onDragStart: onDragStart,
      onDragUpdate: onDragUpdate,
      onDragEnd: onDragEnd,
      barHeight: barHeight,
      baseBarColor: baseBarColor ?? sliderTheme.inactiveTrackColor ?? primaryColor.withValues(alpha: 0.24),
      progressBarColor: progressBarColor ?? sliderTheme.activeTrackColor ??  primaryColor,
      bufferedBarColor:
          bufferedBarColor ?? sliderTheme.secondaryActiveTrackColor ?? primaryColor.withValues(alpha: 0.38),
      thumbRadius: thumbRadius,
      thumbColor: thumbColor ?? sliderTheme.thumbColor ?? primaryColor,
      thumbGlowColor:
          thumbGlowColor ?? sliderTheme.overlayColor ?? (thumbColor ?? primaryColor).withValues(alpha: 0.54),
      thumbGlowRadius: thumbGlowRadius,
      thumbCanPaintOutsideBar: thumbCanPaintOutsideBar,
      timeLabelType: timeLabelType ?? TimeLabelType.totalTime,
      timeLabelTextStyle: textStyle,
      timeLabelPadding: timeLabelPadding,
      textScaler: textScaler,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    final theme = Theme.of(context);
    final sliderTheme = SliderTheme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final textStyle = timeLabelTextStyle ?? theme.textTheme.bodyLarge;
    final textScaler = MediaQuery.textScalerOf(context);

    final renderProgressBar = renderObject as _RenderProgressBar;
    renderProgressBar
      ..barHeight = barHeight
      ..total = total
      ..buffered = buffered ?? Duration.zero
      ..progress = progress
      ..onSeek = onSeek
      ..onDragStart = onDragStart
      ..onDragUpdate = onDragUpdate
      ..onDragEnd = onDragEnd
      ..baseBarColor = baseBarColor ?? sliderTheme.inactiveTrackColor ?? primaryColor.withValues(alpha: 0.24)
      ..progressBarColor = progressBarColor ?? sliderTheme.activeTrackColor ??  primaryColor
      ..bufferedBarColor =
          bufferedBarColor ?? sliderTheme.secondaryActiveTrackColor ?? primaryColor.withValues(alpha: 38)
      ..thumbRadius = thumbRadius
      ..thumbColor = thumbColor ?? sliderTheme.thumbColor ?? primaryColor
      ..thumbGlowColor =
          thumbGlowColor ?? sliderTheme.overlayColor ?? (thumbColor ?? primaryColor).withValues(alpha: 54)
      ..thumbGlowRadius = thumbGlowRadius
      ..thumbCanPaintOutsideBar = thumbCanPaintOutsideBar
      ..timeLabelTextStyle = textStyle
      ..timeLabelPadding = timeLabelPadding
      ..textScaler = textScaler;

    if (timeLabelType != null) {
      renderProgressBar.timeLabelType = timeLabelType!;
    }
  }
}

typedef ThumbDragStartCallback = void Function(ThumbDragDetails details);
typedef ThumbDragUpdateCallback = void Function(ThumbDragDetails details);

class ThumbDragDetails {
  const ThumbDragDetails({
    this.timeStamp = Duration.zero,
    this.globalPosition = Offset.zero,
    this.localPosition = Offset.zero,
  });

  final Duration timeStamp;
  final Offset globalPosition;
  final Offset localPosition;

  @override
  String toString() =>
      '${objectRuntimeType(this, 'ThumbDragDetails')}('
      'time: $timeStamp, '
      'global: $globalPosition, '
      'local: $localPosition)';
}

class _EagerHorizontalDragGestureRecognizer
    extends HorizontalDragGestureRecognizer {
  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    resolve(GestureDisposition.accepted);
  }

  @override
  String get debugDescription => '_EagerHorizontalDragGestureRecognizer';
}

class _RenderProgressBar extends RenderBox {
  _RenderProgressBar({
    required Duration progress,
    required Duration total,
    required Duration buffered,
    ValueChanged<Duration>? onSeek,
    ThumbDragStartCallback? onDragStart,
    ThumbDragUpdateCallback? onDragUpdate,
    VoidCallback? onDragEnd,
    required double barHeight,
    required Color baseBarColor,
    required Color progressBarColor,
    required Color bufferedBarColor,
    double thumbRadius = 10.0,
    required Color thumbColor,
    required Color thumbGlowColor,
    double thumbGlowRadius = 30.0,
    bool thumbCanPaintOutsideBar = true,
    required TimeLabelType timeLabelType,
    TextStyle? timeLabelTextStyle,
    double timeLabelPadding = 0.0,
    TextScaler textScaler = TextScaler.noScaling,
  }) : _total = total,
       _buffered = buffered,
       _onSeek = onSeek,
       _onDragStartUserCallback = onDragStart,
       _onDragUpdateUserCallback = onDragUpdate,
       _onDragEndUserCallback = onDragEnd,
       _barHeight = barHeight,
       _baseBarColor = baseBarColor,
       _progressBarColor = progressBarColor,
       _bufferedBarColor = bufferedBarColor,
       _thumbRadius = thumbRadius,
       _thumbColor = thumbColor,
       _thumbGlowColor = thumbGlowColor,
       _thumbGlowRadius = thumbGlowRadius,
       _thumbCanPaintOutsideBar = thumbCanPaintOutsideBar,
       _timeLabelType = timeLabelType,
       _timeLabelTextStyle = timeLabelTextStyle,
       _timeLabelPadding = timeLabelPadding,
       _textScaler = textScaler {
    _drag = _EagerHorizontalDragGestureRecognizer()
      ..onStart = _onDragStart
      ..onUpdate = _onDragUpdate
      ..onEnd = _onDragEnd
      ..onCancel = _finishDrag;

    // Initialize the tap recognizer for the label
    _tap = TapGestureRecognizer()..onTap = _onRightLabelTap;

    if (!_userIsDraggingThumb) {
      _progress = progress;
      _thumbValue = _proportionOfTotal(_progress);
    }
  }

  _EagerHorizontalDragGestureRecognizer? _drag;
  TapGestureRecognizer? _tap;

  late double _thumbValue;
  bool _userIsDraggingThumb = false;

  double get _defaultSidePadding {
    const minPadding = 5.0;
    return (_thumbCanPaintOutsideBar) ? thumbRadius + minPadding : minPadding;
  }

  @override
  void detach() {
    _drag?.dispose();
    _tap?.dispose();
    super.detach();
  }

  @override
  void handleEvent(PointerEvent event, BoxHitTestEntry entry) {
    assert(debugHandleEvent(event, entry));
    if (event is PointerDownEvent) {
      final localPos = event.localPosition;

      // Calculate the bounding box of the Right Label
      final verticalOffset = size.height / 2 - _rightLabelSize.height / 2;
      final rightLabelRect = Rect.fromLTWH(
        size.width - _rightLabelSize.width,
        verticalOffset,
        _rightLabelSize.width,
        _rightLabelSize.height,
      );

      // Calculate the bounding box of the Left Label
      final leftLabelRect = Rect.fromLTWH(
        0,
        verticalOffset,
        _leftLabelSize.width,
        _leftLabelSize.height,
      );

      // Logic to determine who gets the event
      if (rightLabelRect.contains(localPos)) {
        _tap?.addPointer(event);
      } else if (leftLabelRect.contains(localPos)) {
        return;
      } else {
        _drag?.addPointer(event);
      }
    }
  }

  void _onRightLabelTap() {
    if (_timeLabelType == TimeLabelType.totalTime) {
      timeLabelType = TimeLabelType.remainingTime;
    } else {
      timeLabelType = TimeLabelType.totalTime;
    }
  }

  void _onDragStart(DragStartDetails details) {
    _userIsDraggingThumb = true;
    _updateThumbPosition(details.localPosition);
    onDragStart?.call(
      ThumbDragDetails(
        timeStamp: _currentThumbDuration(),
        globalPosition: details.globalPosition,
        localPosition: details.localPosition,
      ),
    );
  }

  void _onDragUpdate(DragUpdateDetails details) {
    _updateThumbPosition(details.localPosition);
    onDragUpdate?.call(
      ThumbDragDetails(
        timeStamp: _currentThumbDuration(),
        globalPosition: details.globalPosition,
        localPosition: details.localPosition,
      ),
    );
  }

  void _onDragEnd(DragEndDetails details) {
    onDragEnd?.call();
    onSeek?.call(_currentThumbDuration());
    _finishDrag();
  }

  void _finishDrag() {
    _userIsDraggingThumb = false;
    markNeedsPaint();
  }

  Duration _currentThumbDuration() {
    final thumbMilliseconds = _thumbValue * total.inMilliseconds;
    return Duration(milliseconds: thumbMilliseconds.round());
  }

  void _updateThumbPosition(Offset localPosition) {
    final dx = localPosition.dx;

    // Use MAX slot widths for the drag area too to align with paint logic
    final currentLeftWidth = _leftLabelSize.width;
    final effectiveLeftWidth = max(_maxLeftLabelWidth, currentLeftWidth);

    final lengthBefore = effectiveLeftWidth + _totalLabelPadding;
    final lengthAfter = _maxRightLabelWidth + _totalLabelPadding;

    final barCapRadius = _barHeight / 2;
    double barStart = lengthBefore + barCapRadius;
    double barEnd = size.width - lengthAfter - barCapRadius;
    final barWidth = barEnd - barStart;
    final position = (dx - barStart).clamp(0.0, barWidth);

    // Prevent division by zero
    _thumbValue = (barWidth > 0) ? (position / barWidth) : 0.0;

    _progress = _currentThumbDuration();

    // Must invalidate the text cache so the label rebuilds with the new time
    _clearLabelCache();
    markNeedsPaint();
  }

  // Note: Aggressive caching (_labelLengthDifferent) has been removed
  // to prevent overlap issues with proportional fonts.
  Duration get progress => _progress;
  Duration _progress = Duration.zero;
  set progress(Duration value) {
    final clamp = _clampDuration(value);
    if (_progress == clamp) return;
    _clearLabelCache();
    if (!_userIsDraggingThumb) {
      _progress = clamp;
      _thumbValue = _proportionOfTotal(clamp);
    }
    markNeedsPaint();
  }

  Duration get total => _total;
  Duration _total;
  set total(Duration value) {
    final clamp = (value.isNegative) ? Duration.zero : value;
    if (_total == clamp) return;
    _clearLabelCache();
    _clearMaxWidthCache();
    _total = clamp;
    _total = clamp;
    if (!_userIsDraggingThumb) {
      _thumbValue = _proportionOfTotal(progress);
    }
    markNeedsPaint();
  }

  Duration get buffered => _buffered;
  Duration _buffered;
  set buffered(Duration value) {
    final clamp = _clampDuration(value);
    if (_buffered == clamp) return;
    _buffered = clamp;
    markNeedsPaint();
  }

  Duration _clampDuration(Duration value) {
    if (value.isNegative) return Duration.zero;
    if (value.compareTo(_total) > 0) return _total;
    return value;
  }

  ValueChanged<Duration>? get onSeek => _onSeek;
  ValueChanged<Duration>? _onSeek;
  set onSeek(ValueChanged<Duration>? value) {
    if (value == _onSeek) return;
    _onSeek = value;
  }

  ThumbDragStartCallback? get onDragStart => _onDragStartUserCallback;
  ThumbDragStartCallback? _onDragStartUserCallback;
  set onDragStart(ThumbDragStartCallback? value) {
    if (value == _onDragStartUserCallback) return;
    _onDragStartUserCallback = value;
  }

  ThumbDragUpdateCallback? get onDragUpdate => _onDragUpdateUserCallback;
  ThumbDragUpdateCallback? _onDragUpdateUserCallback;
  set onDragUpdate(ThumbDragUpdateCallback? value) {
    if (value == _onDragUpdateUserCallback) return;
    _onDragUpdateUserCallback = value;
  }

  VoidCallback? get onDragEnd => _onDragEndUserCallback;
  VoidCallback? _onDragEndUserCallback;
  set onDragEnd(VoidCallback? value) {
    if (value == _onDragEndUserCallback) return;
    _onDragEndUserCallback = value;
  }

  double get barHeight => _barHeight;
  double _barHeight;
  set barHeight(double value) {
    if (_barHeight == value) return;
    _barHeight = value;
    markNeedsPaint();
  }

  Color get baseBarColor => _baseBarColor;
  Color _baseBarColor;
  set baseBarColor(Color value) {
    if (_baseBarColor == value) return;
    _baseBarColor = value;
    markNeedsPaint();
  }

  Color get progressBarColor => _progressBarColor;
  Color _progressBarColor;
  set progressBarColor(Color value) {
    if (_progressBarColor == value) return;
    _progressBarColor = value;
    markNeedsPaint();
  }

  Color get bufferedBarColor => _bufferedBarColor;
  Color _bufferedBarColor;
  set bufferedBarColor(Color value) {
    if (_bufferedBarColor == value) return;
    _bufferedBarColor = value;
    markNeedsPaint();
  }

  Color get thumbColor => _thumbColor;
  Color _thumbColor;
  set thumbColor(Color value) {
    if (_thumbColor == value) return;
    _thumbColor = value;
    markNeedsPaint();
  }

  double get thumbRadius => _thumbRadius;
  double _thumbRadius;
  set thumbRadius(double value) {
    if (_thumbRadius == value) return;
    _thumbRadius = value;
    markNeedsLayout();
  }

  Color get thumbGlowColor => _thumbGlowColor;
  Color _thumbGlowColor;
  set thumbGlowColor(Color value) {
    if (_thumbGlowColor == value) return;
    _thumbGlowColor = value;
    if (_userIsDraggingThumb) markNeedsPaint();
  }

  double get thumbGlowRadius => _thumbGlowRadius;
  double _thumbGlowRadius;
  set thumbGlowRadius(double value) {
    if (_thumbGlowRadius == value) return;
    _thumbGlowRadius = value;
    markNeedsLayout();
  }

  bool get thumbCanPaintOutsideBar => _thumbCanPaintOutsideBar;
  bool _thumbCanPaintOutsideBar;
  set thumbCanPaintOutsideBar(bool value) {
    if (_thumbCanPaintOutsideBar == value) return;
    _thumbCanPaintOutsideBar = value;
    markNeedsPaint();
  }

  TimeLabelType get timeLabelType => _timeLabelType;
  TimeLabelType _timeLabelType;
  set timeLabelType(TimeLabelType value) {
    if (_timeLabelType == value) return;
    _timeLabelType = value;
    _clearLabelCache();
    markNeedsLayout();
    markNeedsPaint();
  }

  TextStyle? get timeLabelTextStyle => _timeLabelTextStyle;
  TextStyle? _timeLabelTextStyle;
  set timeLabelTextStyle(TextStyle? value) {
    if (_timeLabelTextStyle == value) return;
    _timeLabelTextStyle = value;
    _clearLabelCache();
    markNeedsLayout();
  }

  double get timeLabelPadding => _timeLabelPadding;
  double _timeLabelPadding;
  set timeLabelPadding(double value) {
    if (_timeLabelPadding == value) return;
    _timeLabelPadding = value;
    markNeedsLayout();
  }

  TextScaler get textScaler => _textScaler;
  TextScaler _textScaler;
  set textScaler(TextScaler value) {
    if (_textScaler == value) return;
    _textScaler = value;
    _clearLabelCache();
    markNeedsLayout();
  }

  TextPainter? _cachedLeftLabel;
  Size get _leftLabelSize {
    _cachedLeftLabel ??= _leftTimeLabel();
    return _cachedLeftLabel!.size;
  }

  TextPainter? _cachedRightLabel;
  Size get _rightLabelSize {
    _cachedRightLabel ??= _rightTimeLabel();
    return _cachedRightLabel!.size;
  }

  void _clearLabelCache() {
    _cachedLeftLabel = null;
    _cachedRightLabel = null;
  }

  TextPainter _leftTimeLabel() {
    if (_cachedLeftLabel != null) return _cachedLeftLabel!;
    final text = _getTimeString(progress);
    return _layoutText(text);
  }

  TextPainter _rightTimeLabel() {
    if (_cachedRightLabel != null) return _cachedRightLabel!;
    switch (_timeLabelType) {
      case TimeLabelType.totalTime:
        final text = _getTimeString(total);
        return _layoutText(text);
      case TimeLabelType.remainingTime:
        final remaining = total - progress;
        final text = '-${_getTimeString(remaining)}';
        return _layoutText(text);
    }
  }

  double? _cachedMaxLeftWidth;
  double? _cachedMaxRightWidth;

  void _clearMaxWidthCache() {
    _cachedMaxLeftWidth = null;
    _cachedMaxRightWidth = null;
  }

  double get _maxLeftLabelWidth {
    if (_cachedMaxLeftWidth != null) return _cachedMaxLeftWidth!;
    final text = _getTimeString(total);
    final painter = _layoutText(text);
    _cachedMaxLeftWidth = painter.size.width;
    return _cachedMaxLeftWidth!;
  }

  double get _maxRightLabelWidth {
    if (_cachedMaxRightWidth != null) return _cachedMaxRightWidth!;
    final text = '-${_getTimeString(total)}';
    final painter = _layoutText(text);
    _cachedMaxRightWidth = painter.size.width;
    return _cachedMaxRightWidth!;
  }

  double get _totalLabelPadding => _defaultSidePadding + _timeLabelPadding;

  TextPainter _layoutText(String text) {
    TextPainter textPainter = TextPainter(
      text: TextSpan(text: text, style: _timeLabelTextStyle),
      textDirection: TextDirection.ltr,
      textScaler: _textScaler,
    );
    textPainter.layout(minWidth: 0, maxWidth: double.infinity);
    return textPainter;
  }

  double _proportionOfTotal(Duration duration) {
    if (total.inMilliseconds == 0) {
      return 0.0;
    }
    return duration.inMilliseconds / total.inMilliseconds;
  }

  String _getTimeString(Duration time) {
    final minutes = time.inMinutes
        .remainder(Duration.minutesPerHour)
        .toString();
    final seconds = time.inSeconds
        .remainder(Duration.secondsPerMinute)
        .toString()
        .padLeft(2, '0');
    return time.inHours > 0
        ? "${time.inHours}:${minutes.padLeft(2, "0")}:$seconds"
        : "$minutes:$seconds";
  }

  static const _minDesiredWidth = 100.0;

  @override
  double computeMinIntrinsicWidth(double height) => _minDesiredWidth;
  @override
  double computeMaxIntrinsicWidth(double height) => _minDesiredWidth;

  @override
  double computeMinIntrinsicHeight(double width) => _calculateDesiredHeight();
  @override
  double computeMaxIntrinsicHeight(double width) => _calculateDesiredHeight();

  @override
  bool hitTestSelf(Offset position) => true;

  @override
  void performLayout() {
    size = computeDryLayout(constraints);
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final desiredWidth = constraints.maxWidth;
    final desiredHeight = _calculateDesiredHeight();
    final desiredSize = Size(desiredWidth, desiredHeight);
    return constraints.constrain(desiredSize);
  }

  double _calculateDesiredHeight() {
    return max(2 * _thumbRadius, max(_barHeight, _leftLabelSize.height));
  }

  @override
  bool get isRepaintBoundary => true;

  @override
  void paint(PaintingContext context, Offset offset) {
    final canvas = context.canvas;
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    _drawProgressBarWithLabelsOnSides(canvas);
    canvas.restore();
  }

  void _drawProgressBarWithLabelsOnSides(Canvas canvas) {
    final verticalOffset = size.height / 2 - _leftLabelSize.height / 2;

    // Calculate Slots using the MAX text width (fixed slots)
    // to prevent overlap in edge cases.
    final maxLeftWidth = max(_maxLeftLabelWidth, _leftLabelSize.width);
    final maxRightWidth = max(_maxRightLabelWidth, _rightLabelSize.width);
    final padding = _totalLabelPadding;

    // Draw Left Label (Hugging the right side of the left slot)
    final leftLabelDx = maxLeftWidth - _leftLabelSize.width;
    _leftTimeLabel().paint(canvas, Offset(leftLabelDx, verticalOffset));

    // Draw Right Label (Hugging the left side of the right slot)
    final rightLabelDx = size.width - maxRightWidth;
    _rightTimeLabel().paint(canvas, Offset(rightLabelDx, verticalOffset));

    // Draw Progress Bar (Centered in the remaining space)
    final barHeight = max(2 * _thumbRadius, _barHeight);
    final barDy = size.height / 2 - barHeight / 2;

    final barDx = maxLeftWidth + padding;
    final barWidth = size.width - maxLeftWidth - maxRightWidth - (padding * 2);

    if (barWidth > 0) {
      _drawProgressBar(canvas, Offset(barDx, barDy), Size(barWidth, barHeight));
    }
  }

  void _drawProgressBar(Canvas canvas, Offset offset, Size localSize) {
    canvas.save();
    canvas.translate(offset.dx, offset.dy);

    final lineSize = Size(localSize.width, localSize.height);

    _drawBaseBar(canvas, lineSize);
    _drawBufferedBar(canvas, lineSize);
    _drawCurrentProgressBar(canvas, lineSize);
    _drawThumb(canvas, lineSize);
    canvas.restore();
  }

  void _drawBaseBar(Canvas canvas, Size localSize) {
    _drawBar(
      canvas: canvas,
      availableSize: localSize,
      widthProportion: 1.0,
      color: baseBarColor,
    );
  }

  void _drawBufferedBar(Canvas canvas, Size localSize) {
    _drawBar(
      canvas: canvas,
      availableSize: localSize,
      widthProportion: _proportionOfTotal(_buffered),
      color: bufferedBarColor,
    );
  }

  void _drawCurrentProgressBar(Canvas canvas, Size localSize) {
    _drawBar(
      canvas: canvas,
      availableSize: localSize,
      widthProportion: _proportionOfTotal(_progress),
      color: progressBarColor,
    );
  }

  void _drawBar({
    required Canvas canvas,
    required Size availableSize,
    required double widthProportion,
    required Color color,
  }) {
    const strokeCap = StrokeCap.round;
    final baseBarPaint = Paint()
      ..color = color
      ..strokeCap = strokeCap
      ..strokeWidth = _barHeight;

    final capRadius = _barHeight / 2;
    // Center vertically in available height
    final dy = availableSize.height / 2;

    final adjustedWidth = availableSize.width - _barHeight;
    final dx = widthProportion * adjustedWidth + capRadius;

    final startPoint = Offset(capRadius, dy);
    final endPoint = Offset(dx, dy);

    canvas.drawLine(startPoint, endPoint, baseBarPaint);
  }

  void _drawThumb(Canvas canvas, Size localSize) {
    final thumbPaint = Paint()..color = thumbColor;
    final dy = localSize.height / 2;

    final barCapRadius = _barHeight / 2;
    final availableWidth = localSize.width - _barHeight;
    var thumbDx = _thumbValue * availableWidth + barCapRadius;

    if (!_thumbCanPaintOutsideBar) {
      thumbDx = thumbDx.clamp(_thumbRadius, localSize.width - _thumbRadius);
    }

    final center = Offset(thumbDx, dy);
    if (_userIsDraggingThumb) {
      final thumbGlowPaint = Paint()..color = thumbGlowColor;
      canvas.drawCircle(center, thumbGlowRadius, thumbGlowPaint);
    }
    canvas.drawCircle(center, thumbRadius, thumbPaint);
  }

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);

    config.textDirection = TextDirection.ltr;
    config.label = 'Progress bar';
    config.value = '${(_thumbValue * 100).round()}%';

    config.onIncrease = increaseAction;
    final increased = _thumbValue + _semanticActionUnit;
    config.increasedValue = '${((increased).clamp(0.0, 1.0) * 100).round()}%';

    config.onDecrease = decreaseAction;
    final decreased = _thumbValue - _semanticActionUnit;
    config.decreasedValue = '${((decreased).clamp(0.0, 1.0) * 100).round()}%';
  }

  static const double _semanticActionUnit = 0.05;

  void increaseAction() {
    final newValue = _thumbValue + _semanticActionUnit;
    _thumbValue = (newValue).clamp(0.0, 1.0);
    onSeek?.call(_currentThumbDuration());
    markNeedsPaint();
    markNeedsSemanticsUpdate();
  }

  void decreaseAction() {
    final newValue = _thumbValue - _semanticActionUnit;
    _thumbValue = (newValue).clamp(0.0, 1.0);
    onSeek?.call(_currentThumbDuration());
    markNeedsPaint();
    markNeedsSemanticsUpdate();
  }
}
