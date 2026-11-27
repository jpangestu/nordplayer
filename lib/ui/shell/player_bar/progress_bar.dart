import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:material_ui/material_ui.dart';

// A modified version of audio_video_progress_bar
// https://pub.dev/packages/audio_video_progress_bar (MIT License)

/// Defines the time display mode for track duration in the player bar.
enum TimeLabelType { totalTime, remainingTime }

class const ProgressBar({
  super.key,
  required final Duration progress,
  required final Duration total,
  final Duration? buffered,
  final ValueChanged<Duration>? onSeek,
  final ThumbDragStartCallback? onDragStart,
  final ThumbDragUpdateCallback? onDragUpdate,
  final VoidCallback? onDragEnd,
  final double? barHeight,
  final Color? baseBarColor,
  final Color? progressBarColor,
  final Color? bufferedBarColor,
  final double? thumbRadius,
  final Color? thumbColor,
  final Color? thumbGlowColor,
  final double? thumbGlowRadius,
  final bool thumbCanPaintOutsideBar = true,
  final TimeLabelType? timeLabelType,
  final VoidCallback? onRightTimeLabelTap,
  final TextStyle? timeLabelTextStyle,
  final double timeLabelPadding = 0.0,
}) extends StatefulWidget {
  @override
  State<ProgressBar> createState() => _ProgressBarState();
}

class _ProgressBarState extends State<ProgressBar> {
  final GlobalKey _renderBarKey = GlobalKey();
  final LayerLink _layerLink = LayerLink();
  final OverlayPortalController _tooltipController = OverlayPortalController();
  final ValueNotifier<_HoverTooltipData?> _tooltipNotifier = ValueNotifier(null);
  final _TooltipTextCache _tooltipTextCache = _TooltipTextCache();

  _RenderProgressBar? get _renderBar =>
      _renderBarKey.currentContext?.findRenderObject() as _RenderProgressBar?;

  @override
  void initState() {
    super.initState();
    _tooltipNotifier.addListener(_syncTooltipVisibility);
  }

  @override
  void didUpdateWidget(ProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.total != widget.total && _tooltipNotifier.value != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _renderBar?.refreshTooltip();
      });
    }
  }

  @override
  void dispose() {
    _tooltipNotifier
      ..removeListener(_syncTooltipVisibility)
      ..dispose();
    _tooltipTextCache.dispose();
    super.dispose();
  }

  void _syncTooltipVisibility() {
    if (!mounted) return;
    final hasTooltip = _tooltipNotifier.value != null;
    if (hasTooltip && !_tooltipController.isShowing && Overlay.maybeOf(context) != null) {
      _tooltipController.show();
    } else if (!hasTooltip && _tooltipController.isShowing) {
      _tooltipController.hide();
    }
  }

  @override
  Widget build(BuildContext context) {
    return OverlayPortal(
      controller: _tooltipController,
      overlayChildBuilder: (overlayContext) {
        final theme = Theme.of(overlayContext);
        final tooltipBgColor = theme.colorScheme.inverseSurface;
        final tooltipStyle =
            theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onInverseSurface,
              fontWeight: FontWeight.bold,
            ) ??
            TextStyle(color: theme.colorScheme.onInverseSurface, fontWeight: FontWeight.bold);
        final textScaler = MediaQuery.textScalerOf(overlayContext);

        return IgnorePointer(
          child: Stack(
            children: [
              CompositedTransformFollower(
                link: _layerLink,
                showWhenUnlinked: false,
                targetAnchor: Alignment.topLeft,
                followerAnchor: Alignment.topLeft,
                child: CustomPaint(
                  painter: _HoverTooltipPainter(
                    tooltipNotifier: _tooltipNotifier,
                    textCache: _tooltipTextCache,
                    bgColor: tooltipBgColor,
                    textStyle: tooltipStyle,
                    textScaler: textScaler,
                  ),
                ),
              ),
            ],
          ),
        );
      },
      child: CompositedTransformTarget(
        link: _layerLink,
        child: MouseRegion(
          onHover: (event) => _renderBar?.updateHover(event.localPosition),
          onExit: (_) => _renderBar?.updateHover(null),
          child: _RawProgressBar(
            key: _renderBarKey,
            config: widget,
            tooltipNotifier: _tooltipNotifier,
          ),
        ),
      ),
    );
  }
}

typedef _HoverTooltipData = ({
  String timeString,
  double cursorDx,
  double barDy,
  double maxLeftWidth,
  double maxRightWidth,
  double totalWidth,
});

class _TooltipTextCache {
  String? _timeString;
  TextStyle? _textStyle;
  TextScaler? _textScaler;
  TextPainter? _painter;

  TextPainter resolve(String timeString, TextStyle style, TextScaler textScaler) {
    if (_painter != null &&
        _timeString == timeString &&
        _textStyle == style &&
        _textScaler == textScaler) {
      return _painter!;
    }

    _painter?.dispose();
    _timeString = timeString;
    _textStyle = style;
    _textScaler = textScaler;
    _painter = TextPainter(
      text: TextSpan(
        text: timeString,
        style: style.copyWith(height: 1.0, fontFeatures: const [FontFeature.tabularFigures()]),
      ),
      textDirection: TextDirection.ltr,
      textScaler: textScaler,
    )..layout();
    return _painter!;
  }

  void dispose() {
    _painter?.dispose();
    _painter = null;
  }
}

class _HoverTooltipPainter extends CustomPainter {
  _HoverTooltipPainter({
    required this.tooltipNotifier,
    required this.textCache,
    required this.bgColor,
    required this.textStyle,
    required this.textScaler,
  }) : super(repaint: tooltipNotifier);

  final ValueListenable<_HoverTooltipData?> tooltipNotifier;
  final _TooltipTextCache textCache;
  final Color bgColor;
  final TextStyle textStyle;
  final TextScaler textScaler;

  @override
  void paint(Canvas canvas, Size size) {
    final data = tooltipNotifier.value;
    if (data == null) return;

    final textPainter = textCache.resolve(data.timeString, textStyle, textScaler);
    final baseline = textPainter.computeDistanceToActualBaseline(TextBaseline.alphabetic);
    final scaledFontSize = textScaler.scale(textStyle.fontSize ?? 11.0);
    final capHeight = scaledFontSize * 0.72;

    const horizontalPadding = 8.0;
    const verticalPadding = 5.5;
    final bubbleWidth = textPainter.width + horizontalPadding * 2;
    final bubbleHeight = capHeight + verticalPadding * 2;
    const triangleHeight = 5.0;
    const verticalGap = 2.0;

    final bubbleBottom = data.barDy - verticalGap - triangleHeight;
    final tooltipCenterY = bubbleBottom - bubbleHeight / 2;

    final halfBubbleWidth = bubbleWidth / 2;
    final minTooltipX = data.maxLeftWidth + halfBubbleWidth;
    final maxTooltipX = data.totalWidth - data.maxRightWidth - halfBubbleWidth;
    final clampedTooltipDx = minTooltipX <= maxTooltipX
        ? data.cursorDx.clamp(minTooltipX, maxTooltipX)
        : (minTooltipX + maxTooltipX) / 2;

    final tooltipRect = Rect.fromCenter(
      center: Offset(clampedTooltipDx, tooltipCenterY),
      width: bubbleWidth,
      height: bubbleHeight,
    );

    final tooltipRRect = RRect.fromRectAndRadius(tooltipRect, const Radius.circular(6));
    final bgPaint = Paint()..color = bgColor;
    canvas.drawRRect(tooltipRRect, bgPaint);

    // Clamp the pointer arrow horizontally so it never detaches from the tooltip bubble
    final minTriangleX = tooltipRect.left + 6.0;
    final maxTriangleX = tooltipRect.right - 6.0;
    final clampedTriangleDx = minTriangleX <= maxTriangleX
        ? data.cursorDx.clamp(minTriangleX, maxTriangleX)
        : tooltipRect.center.dx;

    final trianglePath = Path()
      ..moveTo(clampedTriangleDx - 5, tooltipRect.bottom - 1)
      ..lineTo(clampedTriangleDx + 5, tooltipRect.bottom - 1)
      ..lineTo(clampedTriangleDx, tooltipRect.bottom + triangleHeight)
      ..close();
    canvas.drawPath(trianglePath, bgPaint);

    textPainter.paint(
      canvas,
      Offset(clampedTooltipDx - textPainter.width / 2, tooltipCenterY - (baseline - capHeight / 2)),
    );
  }

  @override
  bool shouldRepaint(_HoverTooltipPainter oldDelegate) {
    return oldDelegate.tooltipNotifier != tooltipNotifier ||
        oldDelegate.bgColor != bgColor ||
        oldDelegate.textStyle != textStyle ||
        oldDelegate.textScaler != textScaler;
  }
}

typedef _ProgressBarPaintStyle = ({
  Color baseBarColor,
  Color progressBarColor,
  Color bufferedBarColor,
  Color thumbColor,
  Color thumbGlowColor,
  bool thumbCanPaintOutsideBar,
});

typedef _ProgressBarLayoutStyle = ({
  double barHeight,
  double thumbRadius,
  double thumbGlowRadius,
  double timeLabelPadding,
  TextStyle? timeLabelTextStyle,
  TextScaler textScaler,
});

class const _RawProgressBar({
  super.key,
  required final ProgressBar config,
  required final ValueNotifier<_HoverTooltipData?> tooltipNotifier,
}) extends LeafRenderObjectWidget {
  ({_ProgressBarPaintStyle paint, _ProgressBarLayoutStyle layout}) _resolveStyles(
    BuildContext context,
  ) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final sliderTheme = SliderTheme.of(context);

    final double resolvedThumbRadius =
        config.thumbRadius ??
        switch (sliderTheme.thumbShape) {
          RoundSliderThumbShape(:final enabledThumbRadius) => enabledThumbRadius,
          final shape? => shape.getPreferredSize(true, false).shortestSide / 2,
          null => 10.0,
        };

    final double resolvedThumbGlowRadius =
        config.thumbGlowRadius ??
        switch (sliderTheme.overlayShape) {
          RoundSliderOverlayShape(:final overlayRadius) => overlayRadius,
          final shape? => shape.getPreferredSize(true, false).shortestSide / 2,
          null => 24.0,
        };

    return (
      paint: (
        baseBarColor:
            config.baseBarColor ??
            sliderTheme.inactiveTrackColor ??
            primaryColor.withValues(alpha: 0.24),
        progressBarColor: config.progressBarColor ?? sliderTheme.activeTrackColor ?? primaryColor,
        bufferedBarColor:
            config.bufferedBarColor ??
            sliderTheme.secondaryActiveTrackColor ??
            primaryColor.withValues(alpha: 0.38),
        thumbColor: config.thumbColor ?? sliderTheme.thumbColor ?? primaryColor,
        thumbGlowColor:
            config.thumbGlowColor ??
            sliderTheme.overlayColor ??
            (config.thumbColor ?? primaryColor).withValues(alpha: 0.54),
        thumbCanPaintOutsideBar: config.thumbCanPaintOutsideBar,
      ),
      layout: (
        barHeight: config.barHeight ?? sliderTheme.trackHeight ?? 5.0,
        thumbRadius: resolvedThumbRadius,
        thumbGlowRadius: resolvedThumbGlowRadius,
        timeLabelPadding: config.timeLabelPadding,
        timeLabelTextStyle: config.timeLabelTextStyle ?? theme.textTheme.bodyMedium,
        textScaler: MediaQuery.textScalerOf(context),
      ),
    );
  }

  @override
  RenderObject createRenderObject(BuildContext context) {
    final styles = _resolveStyles(context);

    return _RenderProgressBar(
      progress: config.progress,
      total: config.total,
      buffered: config.buffered ?? Duration.zero,
      onSeek: config.onSeek,
      onDragStart: config.onDragStart,
      onDragUpdate: config.onDragUpdate,
      onDragEnd: config.onDragEnd,
      onRightTimeLabelTap: config.onRightTimeLabelTap,
      timeLabelType: config.timeLabelType ?? TimeLabelType.totalTime,
      paintStyle: styles.paint,
      layoutStyle: styles.layout,
      tooltipNotifier: tooltipNotifier,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    final styles = _resolveStyles(context);

    (renderObject as _RenderProgressBar)
      ..total = config.total
      ..buffered = config.buffered ?? Duration.zero
      ..progress = config.progress
      ..onSeek = config.onSeek
      ..onDragStart = config.onDragStart
      ..onDragUpdate = config.onDragUpdate
      ..onDragEnd = config.onDragEnd
      ..onRightTimeLabelTap = config.onRightTimeLabelTap
      ..timeLabelType = config.timeLabelType ?? TimeLabelType.totalTime
      ..paintStyle = styles.paint
      ..layoutStyle = styles.layout
      ..tooltipNotifier = tooltipNotifier;
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

class _EagerHorizontalDragGestureRecognizer extends HorizontalDragGestureRecognizer {
  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    resolve(GestureDisposition.accepted);
  }

  @override
  String get debugDescription => '_EagerHorizontalDragGestureRecognizer';
}

typedef _BarMetrics = ({
  double maxLeftWidth,
  double maxRightWidth,
  double barDx,
  double barDy,
  double barWidth,
  double barHeight,
  double barStart,
  double barEnd,
  double trackWidth,
});

class _RenderProgressBar extends RenderBox {
  _RenderProgressBar({
    required Duration progress,
    required this._total,
    required this._buffered,
    this.onSeek,
    this.onDragStart,
    this.onDragUpdate,
    this.onDragEnd,
    this.onRightTimeLabelTap,
    required this._timeLabelType,
    required this._paintStyle,
    required this._layoutStyle,
    required this.tooltipNotifier,
  }) {
    _drag = _EagerHorizontalDragGestureRecognizer()
      ..onStart = _onDragStart
      ..onUpdate = _onDragUpdate
      ..onEnd = _onDragEnd
      ..onCancel = _finishDrag;

    _tap = TapGestureRecognizer()..onTap = () => onRightTimeLabelTap?.call();

    _progress = _clampDuration(progress);
    _thumbValue = _proportionOfTotal(_progress);
  }

  _EagerHorizontalDragGestureRecognizer? _drag;
  TapGestureRecognizer? _tap;

  ValueChanged<Duration>? onSeek;
  ThumbDragStartCallback? onDragStart;
  ThumbDragUpdateCallback? onDragUpdate;
  VoidCallback? onDragEnd;
  VoidCallback? onRightTimeLabelTap;
  ValueNotifier<_HoverTooltipData?> tooltipNotifier;

  late double _thumbValue;
  bool _userIsDraggingThumb = false;
  Offset? _hoverPosition;
  Offset? _lastDragLocalPosition;

  void updateHover(Offset? position) {
    if (_userIsDraggingThumb) return;
    if (_hoverPosition != position) {
      _hoverPosition = position;
      markNeedsPaint();
    }
    refreshTooltip();
  }

  void refreshTooltip() {
    if (!hasSize) {
      tooltipNotifier.value = null;
      return;
    }
    if (_userIsDraggingThumb) {
      tooltipNotifier.value = _computeThumbTooltip();
    } else if (_hoverPosition != null) {
      tooltipNotifier.value = _computeHoverTooltip(_hoverPosition!);
    } else {
      tooltipNotifier.value = null;
    }
  }

  double get _defaultSidePadding {
    const minPadding = 5.0;
    return _paintStyle.thumbCanPaintOutsideBar ? _layoutStyle.thumbRadius + minPadding : minPadding;
  }

  double get _totalLabelPadding => _defaultSidePadding + _layoutStyle.timeLabelPadding;

  _BarMetrics _computeBarMetrics() {
    final maxLeftWidth = max(_maxLeftLabelWidth, _leftLabelSize.width);
    final maxRightWidth = max(_maxRightLabelWidth, _rightLabelSize.width);
    final padding = _totalLabelPadding;
    final barHeight = max(2 * _layoutStyle.thumbRadius, _layoutStyle.barHeight);
    final barDy = size.height / 2 - barHeight / 2;
    final barDx = maxLeftWidth + padding;
    final barWidth = size.width - maxLeftWidth - maxRightWidth - (padding * 2);
    final barCapRadius = _layoutStyle.barHeight / 2;
    final barStart = barDx + barCapRadius;
    final barEnd = barDx + barWidth - barCapRadius;
    final trackWidth = barEnd - barStart;
    return (
      maxLeftWidth: maxLeftWidth,
      maxRightWidth: maxRightWidth,
      barDx: barDx,
      barDy: barDy,
      barWidth: barWidth,
      barHeight: barHeight,
      barStart: barStart,
      barEnd: barEnd,
      trackWidth: trackWidth,
    );
  }

  double _hoverProportionForDx(double dx, _BarMetrics metrics) {
    if (metrics.trackWidth > 0) {
      return ((dx - metrics.barStart) / metrics.trackWidth).clamp(0.0, 1.0);
    }
    if (metrics.barWidth > 0) {
      return ((dx - metrics.barDx) / metrics.barWidth).clamp(0.0, 1.0);
    }
    return 0.0;
  }

  _HoverTooltipData? _computeHoverTooltip(Offset localPosition) {
    final metrics = _computeBarMetrics();
    if (metrics.barWidth <= 0) return null;

    final dx = localPosition.dx;
    if (dx < metrics.barDx || dx > metrics.barDx + metrics.barWidth) {
      return null;
    }

    final hoverProportion = _hoverProportionForDx(dx, metrics);
    final hoverDuration = Duration(milliseconds: (hoverProportion * _total.inMilliseconds).round());
    return (
      timeString: _getTimeString(hoverDuration),
      cursorDx: dx,
      barDy: metrics.barDy,
      maxLeftWidth: metrics.maxLeftWidth,
      maxRightWidth: metrics.maxRightWidth,
      totalWidth: size.width,
    );
  }

  _HoverTooltipData? _computeThumbTooltip() {
    final metrics = _computeBarMetrics();
    if (metrics.barWidth <= 0) return null;

    final availableWidth = max(0.0, metrics.trackWidth);
    var thumbDx = metrics.barDx + _thumbValue * availableWidth + (_layoutStyle.barHeight / 2);
    if (!_paintStyle.thumbCanPaintOutsideBar) {
      final minX = metrics.barDx + _layoutStyle.thumbRadius;
      final maxX = metrics.barDx + metrics.barWidth - _layoutStyle.thumbRadius;
      thumbDx = minX <= maxX ? thumbDx.clamp(minX, maxX) : metrics.barDx + metrics.barWidth / 2;
    }

    return (
      timeString: _getTimeString(_currentThumbDuration()),
      cursorDx: thumbDx,
      barDy: metrics.barDy,
      maxLeftWidth: metrics.maxLeftWidth,
      maxRightWidth: metrics.maxRightWidth,
      totalWidth: size.width,
    );
  }

  Rect get _leftLabelHitRect {
    final maxLeftWidth = max(_maxLeftLabelWidth, _leftLabelSize.width);
    return Rect.fromLTWH(0, 0, maxLeftWidth + _layoutStyle.timeLabelPadding, size.height);
  }

  Rect get _rightLabelHitRect {
    final maxRightWidth = max(_maxRightLabelWidth, _rightLabelSize.width);
    final leftDx = size.width - (maxRightWidth + _layoutStyle.timeLabelPadding);
    return Rect.fromLTWH(leftDx, 0, maxRightWidth + _layoutStyle.timeLabelPadding, size.height);
  }

  @override
  void dispose() {
    _drag?.dispose();
    _drag = null;
    _tap?.dispose();
    _tap = null;
    _clearLabelCache();
    super.dispose();
  }

  @override
  void handleEvent(PointerEvent event, BoxHitTestEntry entry) {
    assert(debugHandleEvent(event, entry));
    if (event is PointerDownEvent) {
      final dx = event.localPosition.dx;
      final metrics = _computeBarMetrics();

      final thumbCenterDx = metrics.barStart + _thumbValue * max(0.0, metrics.trackWidth);
      final distanceToThumb =
          (event.localPosition - Offset(thumbCenterDx, size.height / 2)).distance;

      // Clickable seek region matches the progress bar's hover tooltip bounds
      final progressStart = metrics.barDx;
      final progressEnd = metrics.barDx + metrics.barWidth;

      if (_rightLabelHitRect.contains(event.localPosition)) {
        _tap?.addPointer(event);
      } else if (_leftLabelHitRect.contains(event.localPosition)) {
        return;
      } else if (metrics.barWidth > 0 &&
          ((dx >= progressStart && dx <= progressEnd) ||
              distanceToThumb <= max(_layoutStyle.thumbRadius, 15.0))) {
        _drag?.addPointer(event);
      }
    }
  }

  void _onDragStart(DragStartDetails details) {
    _userIsDraggingThumb = true;
    _lastDragLocalPosition = details.localPosition;
    _updateThumbPosition(details.localPosition);
    refreshTooltip();
    onDragStart?.call(
      ThumbDragDetails(
        timeStamp: _currentThumbDuration(),
        globalPosition: details.globalPosition,
        localPosition: details.localPosition,
      ),
    );
  }

  void _onDragUpdate(DragUpdateDetails details) {
    _lastDragLocalPosition = details.localPosition;
    _updateThumbPosition(details.localPosition);
    refreshTooltip();
    onDragUpdate?.call(
      ThumbDragDetails(
        timeStamp: _currentThumbDuration(),
        globalPosition: details.globalPosition,
        localPosition: details.localPosition,
      ),
    );
  }

  void _onDragEnd(DragEndDetails details) {
    final endPosition = _lastDragLocalPosition;
    onDragEnd?.call();
    onSeek?.call(_currentThumbDuration());
    _finishDrag(endPosition: endPosition);
  }

  void _finishDrag({Offset? endPosition}) {
    _userIsDraggingThumb = false;
    _lastDragLocalPosition = null;
    final isInsideWidget =
        hasSize &&
        endPosition != null &&
        endPosition.dx >= 0 &&
        endPosition.dx <= size.width &&
        endPosition.dy >= 0 &&
        endPosition.dy <= size.height;
    _hoverPosition = isInsideWidget ? endPosition : null;
    refreshTooltip();
    markNeedsPaint();
  }

  Duration _currentThumbDuration() {
    final thumbMilliseconds = _thumbValue * _total.inMilliseconds;
    return Duration(milliseconds: thumbMilliseconds.round());
  }

  void _updateThumbPosition(Offset localPosition) {
    final metrics = _computeBarMetrics();
    _thumbValue = _hoverProportionForDx(localPosition.dx, metrics);
    _progress = _currentThumbDuration();
    _clearLabelCache();
    markNeedsPaint();
  }

  Duration _progress = Duration.zero;
  set progress(Duration value) {
    final clamp = _clampDuration(value);
    if (_progress == clamp) return;
    if (!_userIsDraggingThumb) {
      _clearLabelCache();
      _progress = clamp;
      _thumbValue = _proportionOfTotal(clamp);
      markNeedsPaint();
    }
  }

  Duration _total;
  set total(Duration value) {
    final clamp = value.isNegative ? Duration.zero : value;
    if (_total == clamp) return;
    _clearLabelCache();
    _clearMaxWidthCache();
    _total = clamp;
    if (!_userIsDraggingThumb) {
      _progress = _clampDuration(_progress);
      _thumbValue = _proportionOfTotal(_progress);
    }
    markNeedsLayout();
  }

  Duration _buffered;
  set buffered(Duration value) {
    final clamp = _clampDuration(value);
    if (_buffered == clamp) return;
    _buffered = clamp;
    markNeedsPaint();
  }

  TimeLabelType _timeLabelType;
  set timeLabelType(TimeLabelType value) {
    if (_timeLabelType == value) return;
    _timeLabelType = value;
    _clearLabelCache();
    markNeedsLayout();
  }

  _ProgressBarPaintStyle _paintStyle;
  set paintStyle(_ProgressBarPaintStyle value) {
    if (_paintStyle == value) return;
    _paintStyle = value;
    markNeedsPaint();
  }

  _ProgressBarLayoutStyle _layoutStyle;
  set layoutStyle(_ProgressBarLayoutStyle value) {
    if (_layoutStyle == value) return;
    final textChanged =
        _layoutStyle.timeLabelTextStyle != value.timeLabelTextStyle ||
        _layoutStyle.textScaler != value.textScaler;
    _layoutStyle = value;
    if (textChanged) {
      _clearLabelCache();
      _clearMaxWidthCache();
    }
    markNeedsLayout();
  }

  Duration _clampDuration(Duration value) {
    if (value.isNegative) return Duration.zero;
    if (value.compareTo(_total) > 0) return _total;
    return value;
  }

  TextPainter? _cachedLeftLabel;
  Size get _leftLabelSize => _leftTimeLabel().size;

  TextPainter? _cachedRightLabel;
  Size get _rightLabelSize => _rightTimeLabel().size;

  void _clearLabelCache() {
    _cachedLeftLabel?.dispose();
    _cachedLeftLabel = null;
    _cachedRightLabel?.dispose();
    _cachedRightLabel = null;
  }

  TextPainter _leftTimeLabel() {
    return _cachedLeftLabel ??= _layoutText(_getTimeString(_progress));
  }

  TextPainter _rightTimeLabel() {
    if (_cachedRightLabel != null) return _cachedRightLabel!;
    final text = switch (_timeLabelType) {
      TimeLabelType.totalTime => _getTimeString(_total),
      TimeLabelType.remainingTime => '-${_getTimeString(_total - _progress)}',
    };
    return _cachedRightLabel = _layoutText(text);
  }

  double? _cachedMaxLeftWidth;
  double? _cachedMaxRightWidth;

  void _clearMaxWidthCache() {
    _cachedMaxLeftWidth = null;
    _cachedMaxRightWidth = null;
  }

  double get _maxLeftLabelWidth {
    if (_cachedMaxLeftWidth != null) return _cachedMaxLeftWidth!;
    final painter = _layoutText(_getTimeString(_total));
    _cachedMaxLeftWidth = painter.size.width;
    painter.dispose();
    return _cachedMaxLeftWidth!;
  }

  double get _maxRightLabelWidth {
    if (_cachedMaxRightWidth != null) return _cachedMaxRightWidth!;
    final painter = _layoutText('-${_getTimeString(_total)}');
    _cachedMaxRightWidth = painter.size.width;
    painter.dispose();
    return _cachedMaxRightWidth!;
  }

  TextPainter _layoutText(String text) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: _layoutStyle.timeLabelTextStyle?.copyWith(
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
      textDirection: TextDirection.ltr,
      textScaler: _layoutStyle.textScaler,
    );
    textPainter.layout(minWidth: 0, maxWidth: double.infinity);
    return textPainter;
  }

  double _proportionOfTotal(Duration duration) {
    if (_total.inMilliseconds == 0) return 0.0;
    return (duration.inMilliseconds / _total.inMilliseconds).clamp(0.0, 1.0);
  }

  String _getTimeString(Duration time) {
    final safeTime = time.isNegative ? Duration.zero : time;
    final minutes = safeTime.inMinutes.remainder(Duration.minutesPerHour).toString();
    final seconds = safeTime.inSeconds
        .remainder(Duration.secondsPerMinute)
        .toString()
        .padLeft(2, '0');
    return safeTime.inHours > 0
        ? '${safeTime.inHours}:${minutes.padLeft(2, '0')}:$seconds'
        : '$minutes:$seconds';
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
    return constraints.constrain(Size(constraints.maxWidth, _calculateDesiredHeight()));
  }

  double _calculateDesiredHeight() {
    return max(2 * _layoutStyle.thumbRadius, max(_layoutStyle.barHeight, _leftLabelSize.height));
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
    final metrics = _computeBarMetrics();

    final leftLabelDx = metrics.maxLeftWidth - _leftLabelSize.width;
    _leftTimeLabel().paint(canvas, Offset(leftLabelDx, verticalOffset));

    final rightLabelDx = size.width - metrics.maxRightWidth;
    _rightTimeLabel().paint(canvas, Offset(rightLabelDx, verticalOffset));

    if (metrics.barWidth > 0) {
      final isHoveringBar =
          !_userIsDraggingThumb &&
          _hoverPosition != null &&
          _hoverPosition!.dx >= metrics.barDx &&
          _hoverPosition!.dx <= (metrics.barDx + metrics.barWidth);

      final hoverProportion = isHoveringBar
          ? _hoverProportionForDx(_hoverPosition!.dx, metrics)
          : null;

      _drawProgressBar(
        canvas,
        Offset(metrics.barDx, metrics.barDy),
        Size(metrics.barWidth, metrics.barHeight),
        hoverProportion,
      );
    }
  }

  void _drawProgressBar(Canvas canvas, Offset offset, Size localSize, double? hoverProportion) {
    canvas.save();
    canvas.translate(offset.dx, offset.dy);

    _drawBar(canvas, localSize, 1.0, _paintStyle.baseBarColor);
    _drawBar(canvas, localSize, _proportionOfTotal(_buffered), _paintStyle.bufferedBarColor);
    if (hoverProportion != null) {
      _drawBar(
        canvas,
        localSize,
        hoverProportion,
        _paintStyle.progressBarColor.withValues(alpha: 0.35),
      );
    }
    _drawBar(canvas, localSize, _proportionOfTotal(_progress), _paintStyle.progressBarColor);
    _drawThumb(canvas, localSize);
    canvas.restore();
  }

  void _drawBar(Canvas canvas, Size availableSize, double widthProportion, Color color) {
    final barHeight = _layoutStyle.barHeight;
    final paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeWidth = barHeight;

    final capRadius = barHeight / 2;
    final dy = availableSize.height / 2;
    final adjustedWidth = max(0.0, availableSize.width - barHeight);
    final dx = widthProportion * adjustedWidth + capRadius;

    canvas.drawLine(Offset(capRadius, dy), Offset(dx, dy), paint);
  }

  void _drawThumb(Canvas canvas, Size localSize) {
    final barHeight = _layoutStyle.barHeight;
    final thumbRadius = _layoutStyle.thumbRadius;
    final dy = localSize.height / 2;

    final barCapRadius = barHeight / 2;
    final availableWidth = max(0.0, localSize.width - barHeight);
    var thumbDx = _thumbValue * availableWidth + barCapRadius;

    if (!_paintStyle.thumbCanPaintOutsideBar) {
      final minX = thumbRadius;
      final maxX = localSize.width - thumbRadius;
      thumbDx = minX <= maxX ? thumbDx.clamp(minX, maxX) : localSize.width / 2;
    }

    final center = Offset(thumbDx, dy);
    if (_userIsDraggingThumb) {
      canvas.drawCircle(
        center,
        _layoutStyle.thumbGlowRadius,
        Paint()..color = _paintStyle.thumbGlowColor,
      );
    }
    canvas.drawCircle(center, thumbRadius, Paint()..color = _paintStyle.thumbColor);
  }

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);

    config.textDirection = TextDirection.ltr;
    config.label = 'Progress bar';
    config.value = '${(_thumbValue * 100).round()}%';

    config.onIncrease = increaseAction;
    final increased = _thumbValue + _semanticActionUnit;
    config.increasedValue = '${(increased.clamp(0.0, 1.0) * 100).round()}%';

    config.onDecrease = decreaseAction;
    final decreased = _thumbValue - _semanticActionUnit;
    config.decreasedValue = '${(decreased.clamp(0.0, 1.0) * 100).round()}%';
  }

  static const double _semanticActionUnit = 0.05;

  void increaseAction() {
    _thumbValue = (_thumbValue + _semanticActionUnit).clamp(0.0, 1.0);
    onSeek?.call(_currentThumbDuration());
    markNeedsPaint();
    markNeedsSemanticsUpdate();
  }

  void decreaseAction() {
    _thumbValue = (_thumbValue - _semanticActionUnit).clamp(0.0, 1.0);
    onSeek?.call(_currentThumbDuration());
    markNeedsPaint();
    markNeedsSemanticsUpdate();
  }
}
