import 'dart:math' as math;

import 'package:nordplayer/core/layout/layout_node.dart';

/// Pure Dart space solver for [SplitContainer].
///
/// Given [availableExtent] (already excluding inter-pane spacing), the [sizes] of each pane,
/// and the pre-measured [fitExtents] for any [FitContentSize] panes, returns the exact pixel
/// extent for every pane without overflowing [availableExtent].
List<double> solveSplitExtents({
  required double availableExtent,
  required List<LayoutSize> sizes,
  required List<double?> fitExtents,
}) {
  final count = sizes.length;
  if (count == 0) return const [];
  if (availableExtent <= 0) return List<double>.filled(count, 0.0);

  final result = List<double>.filled(count, 0.0);
  var remaining = availableExtent;
  final flexIndices = <int>[];

  // Pass 1: Allocate FixedSize and FitContentSize panes first.
  for (var i = 0; i < count; i++) {
    final spec = sizes[i];
    switch (spec) {
      case FixedSize(:final pixels, :final minExtent, :final maxExtent):
        var extent = math.max(pixels, minExtent);
        if (maxExtent != null) extent = math.min(extent, maxExtent);
        result[i] = extent;
        remaining -= extent;
      case FitContentSize(:final minExtent, :final maxExtent):
        var extent = math.max(fitExtents[i] ?? 0.0, minExtent);
        if (maxExtent != null) extent = math.min(extent, maxExtent);
        result[i] = extent;
        remaining -= extent;
      case FlexSize():
        flexIndices.add(i);
    }
  }

  // Pass 2: Distribute remaining space across FlexSize panes iteratively so
  // minExtent / maxExtent clamps redistribute leftover space cleanly.
  if (flexIndices.isNotEmpty) {
    final active = List<int>.of(flexIndices);
    var flexPool = math.max(0.0, remaining);

    while (active.isNotEmpty) {
      final totalWeight = active.fold<double>(
        0.0,
        (sum, idx) => sum + (sizes[idx] as FlexSize).weight,
      );
      if (totalWeight <= 0) break;

      var clampedAny = false;
      final stillActive = <int>[];

      for (final idx in active) {
        final spec = sizes[idx] as FlexSize;
        final share = flexPool * (spec.weight / totalWeight);
        if (share < spec.minExtent) {
          result[idx] = spec.minExtent;
          flexPool = math.max(0.0, flexPool - spec.minExtent);
          clampedAny = true;
        } else if (spec.maxExtent != null && share > spec.maxExtent!) {
          result[idx] = spec.maxExtent!;
          flexPool = math.max(0.0, flexPool - spec.maxExtent!);
          clampedAny = true;
        } else {
          result[idx] = share;
          stillActive.add(idx);
        }
      }

      if (!clampedAny) break;
      active
        ..clear()
        ..addAll(stillActive);
    }
  }

  // Pass 3: If the sum exceeds availableExtent (e.g. narrow window where fixed/min sizes
  // sum higher than availableExtent), proportionally scale down so we never overflow.
  final totalAllocated = result.fold<double>(0.0, (a, b) => a + b);
  if (totalAllocated > availableExtent && totalAllocated > 0) {
    final scale = availableExtent / totalAllocated;
    for (var i = 0; i < count; i++) {
      result[i] *= scale;
    }
  }

  return result;
}

/// Whether the divider between [first] and [second] can be dragged to resize them.
bool canResizeDivider(LayoutSize first, LayoutSize second) {
  return first is! FitContentSize && second is! FitContentSize;
}

/// Computes updated [LayoutSize] values for an adjacent pane pair ([firstSize], [secondSize])
/// when their shared divider is dragged by [deltaPixels].
///
/// [firstExtent] and [secondExtent] are their measured pixel extents at drag start.
({LayoutSize first, LayoutSize second}) solveDividerResize({
  required LayoutSize firstSize,
  required LayoutSize secondSize,
  required double firstExtent,
  required double secondExtent,
  required double deltaPixels,
  double minFlexWeight = 0.2,
}) {
  if (!canResizeDivider(firstSize, secondSize)) {
    return (first: firstSize, second: secondSize);
  }

  final combinedExtent = firstExtent + secondExtent;
  if (combinedExtent <= 0) return (first: firstSize, second: secondSize);

  double clampExtent(double value, LayoutSize spec) {
    var clamped = math.max(value, spec.minExtent);
    if (spec.maxExtent != null) clamped = math.min(clamped, spec.maxExtent!);
    return clamped;
  }

  // Compute clamped target pixel extents while preserving combinedExtent.
  var targetFirst = clampExtent(firstExtent + deltaPixels, firstSize);
  var targetSecond = clampExtent(combinedExtent - targetFirst, secondSize);
  targetFirst = clampExtent(combinedExtent - targetSecond, firstSize);

  return switch ((firstSize, secondSize)) {
    (FlexSize f1, FlexSize f2) => () {
      final combinedWeight = f1.weight + f2.weight;
      final ratio = (targetFirst / combinedExtent).clamp(0.0, 1.0);
      var newW1 = combinedWeight * ratio;
      var newW2 = combinedWeight - newW1;
      if (newW1 < minFlexWeight) {
        newW1 = minFlexWeight;
        newW2 = math.max(minFlexWeight, combinedWeight - newW1);
      } else if (newW2 < minFlexWeight) {
        newW2 = minFlexWeight;
        newW1 = math.max(minFlexWeight, combinedWeight - newW2);
      }
      return (
        first: f1.copyWith(weight: _round2(newW1)),
        second: f2.copyWith(weight: _round2(newW2)),
      );
    }(),
    (FixedSize x1, FlexSize f2) => (
      first: x1.copyWith(pixels: targetFirst.roundToDouble()),
      second: f2,
    ),
    (FlexSize f1, FixedSize x2) => (
      first: f1,
      second: x2.copyWith(pixels: targetSecond.roundToDouble()),
    ),
    (FixedSize x1, FixedSize x2) => (
      first: x1.copyWith(pixels: targetFirst.roundToDouble()),
      second: x2.copyWith(pixels: targetSecond.roundToDouble()),
    ),
    _ => (first: firstSize, second: secondSize),
  };
}

double _round2(double v) => (v * 100).round() / 100;
