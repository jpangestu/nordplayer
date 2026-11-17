import 'dart:async';

import 'package:app_resource_monitor/app_resource_monitor.dart';
import 'package:flutter/scheduler.dart' show FrameTiming;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

// To get informations about rendering perfomance (frame time), we need either
// [WidgetBinding.instance.addTimingsCallback], or [dart:ui.PlatformDispatcher.onReportTimings].
// The documentation recommends to use the former instead of the later due to the later only allows
// one callback, which prevents multiple libraries from registering listeners simultaneously.

final performanceMetricsProvider =
    NotifierProvider<PerformanceMetricsNotifier, PerformanceMetricsState>(
      PerformanceMetricsNotifier.new,
    );

class PerformanceMetricsNotifier extends Notifier<PerformanceMetricsState> {
  static const Duration _interval = Duration(milliseconds: 500);

  final List<DateTime> _frameHistory = [];
  int _frameRate = 0;
  final List<double> _recentFrameTimes = [];
  double _minFrameTime = 0;
  double _maxFrameTime = 0;

  /// The timestamp when performance metrics were last emitted to Riverpod's [state].
  DateTime _lastStateUpdate = DateTime.now();

  StreamSubscription<ResourceMetrics>? _resourceMetricsSub;

  @override
  PerformanceMetricsState build() {
    WidgetsBinding.instance.addTimingsCallback(timingsCallback);

    _resourceMetricsSub = AppResourceMonitor.instance
        .stream(interval: _interval, emitImmediately: true)
        .listen(_onListenResourceMetrics);

    ref.onDispose(() {
      WidgetsBinding.instance.removeTimingsCallback(timingsCallback);
      _resourceMetricsSub?.cancel();
    });

    return const PerformanceMetricsState.initial();
  }

  void timingsCallback(List<FrameTiming> timings) {
    if (timings.isEmpty) return;

    final now = DateTime.now();
    for (final timing in timings) {
      _frameHistory.add(now);
      final totalMs = timing.totalSpan.inMicroseconds / 1000.0;
      if (totalMs > 0.0) {
        _recentFrameTimes.add(totalMs);
        if (_recentFrameTimes.length > 60) {
          _recentFrameTimes.removeAt(0);
        }
        if (_minFrameTime == 0.0 || totalMs < _minFrameTime) {
          _minFrameTime = totalMs;
        }
        if (totalMs > _maxFrameTime) {
          _maxFrameTime = totalMs;
        }
      }
    }

    _frameHistory.removeWhere((t) => now.difference(t) > const Duration(seconds: 1));
    _frameRate = _frameHistory.length;

    if (now.difference(_lastStateUpdate) >= _interval) {
      _lastStateUpdate = now;

      final lastTiming = timings.last;

      // We use .inMicroseconds / 1.000 to preserce floating point precision
      final uiTimeMs = lastTiming.buildDuration.inMicroseconds / 1000.0;
      final rasterTimeMs = lastTiming.rasterDuration.inMicroseconds / 1000.0;
      final frameTimeMs = lastTiming.totalSpan.inMicroseconds / 1000.0;
      final fps = frameTimeMs > 0 ? (1000.0 / frameTimeMs) : 0.0;
      final avgFrameTimeMs = _recentFrameTimes.isEmpty
          ? 0.0
          : _recentFrameTimes.reduce((a, b) => a + b) / _recentFrameTimes.length;

      state = state.copyWith(
        fps: fps,
        frameTimeMs: frameTimeMs,
        uiTimeMs: uiTimeMs,
        rasterTimeMs: rasterTimeMs,
        frameRate: _frameRate,
        averageFrameTimeMs: avgFrameTimeMs,
        minFrameTimeMs: _minFrameTime,
        maxFrameTimeMs: _maxFrameTime,
      );
    }
  }

  void _onListenResourceMetrics(ResourceMetrics resourceMetrics) {
    // Since [timingsCallback] only runs when Flutter produces a frame, a static UI leaves the
    // frame history untouched. Pruning here ensures the sliding 1-second window empties and
    // [frameRate] correctly reflects 0 Hz when rendering pauses.
    _frameHistory.removeWhere((t) => DateTime.now().difference(t) > const Duration(seconds: 1));

    state = state.copyWith(
      frameRate: _frameHistory.length,
      cpuPercent: resourceMetrics.cpuUsagePercent,
      gpu: resourceMetrics.gpu,
      memory: resourceMetrics.memory,
    );
  }

  /// Resets min, max, and rolling average performance stats.
  void resetStats() {
    _recentFrameTimes.clear();
    _minFrameTime = 0.0;
    _maxFrameTime = 0.0;
    state = state.copyWith(averageFrameTimeMs: 0.0, minFrameTimeMs: 0.0, maxFrameTimeMs: 0.0);
  }
}

@immutable
class PerformanceMetricsState {
  // Rendering metrics
  final double fps;
  final double frameTimeMs;
  final double uiTimeMs;
  final double rasterTimeMs;
  final int frameRate;

  // Aggregate / Rolling stats
  final double averageFrameTimeMs;
  final double minFrameTimeMs;
  final double maxFrameTimeMs;

  // System resource metrics
  final double cpuPercent;
  final MemorySnapshot? memory;
  final GpuSnapshot? gpu;

  const PerformanceMetricsState({
    this.fps = 0.0,
    this.frameTimeMs = 0.0,
    this.uiTimeMs = 0.0,
    this.rasterTimeMs = 0.0,
    this.frameRate = 0,
    this.averageFrameTimeMs = 0.0,
    this.minFrameTimeMs = 0.0,
    this.maxFrameTimeMs = 0.0,
    this.cpuPercent = 0.0,
    this.memory,
    this.gpu,
  });

  const PerformanceMetricsState.initial() : this();

  PerformanceMetricsState copyWith({
    double? fps,
    double? frameTimeMs,
    double? uiTimeMs,
    double? rasterTimeMs,
    int? frameRate,
    double? averageFrameTimeMs,
    double? minFrameTimeMs,
    double? maxFrameTimeMs,
    double? cpuPercent,
    MemorySnapshot? memory,
    GpuSnapshot? gpu,
  }) {
    return PerformanceMetricsState(
      fps: fps ?? this.fps,
      frameTimeMs: frameTimeMs ?? this.frameTimeMs,
      uiTimeMs: uiTimeMs ?? this.uiTimeMs,
      rasterTimeMs: rasterTimeMs ?? this.rasterTimeMs,
      frameRate: frameRate ?? this.frameRate,
      averageFrameTimeMs: averageFrameTimeMs ?? this.averageFrameTimeMs,
      minFrameTimeMs: minFrameTimeMs ?? this.minFrameTimeMs,
      maxFrameTimeMs: maxFrameTimeMs ?? this.maxFrameTimeMs,
      cpuPercent: cpuPercent ?? this.cpuPercent,
      memory: memory ?? this.memory,
      gpu: gpu ?? this.gpu,
    );
  }

  // Formatters
  String get formattedFps => '${fps.round()} FPS';
  String get formattedFrameTime => '${frameTimeMs.toStringAsFixed(1)} ms';
  String get formattedUiTime => '${uiTimeMs.toStringAsFixed(1)} ms';
  String get formattedRasterTime => '${rasterTimeMs.toStringAsFixed(1)} ms';
  String get formattedFrameRate => '$frameRate Hz';

  String get formattedAverageFrameTime => '${averageFrameTimeMs.toStringAsFixed(1)} ms';
  String get formattedMinFrameTime => '${minFrameTimeMs.toStringAsFixed(1)} ms';
  String get formattedMaxFrameTime => '${maxFrameTimeMs.toStringAsFixed(1)} ms';

  String get formattedCpuUsage => '${cpuPercent.toStringAsFixed(1)}%';
  String get formattedGpuUsage => gpu != null ? '${gpu!.usagePercent.toStringAsFixed(1)}%' : '-';
  String get formattedGpuVram => gpu != null ? gpu!.vram.format() : '-';
  String get formattedGpuShared => gpu != null ? gpu!.shared.format() : '-';
  String get formattedRamPrivate => memory != null ? memory!.private.format() : '0 B';
  String get formattedRamRss => memory != null ? memory!.rss.format() : '0 B';
  String get formattedRamCommitted => memory != null ? memory!.committed.format() : '0 B';
  String get formattedRamTotal => memory != null ? memory!.totalSystem.format() : '0 B';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PerformanceMetricsState &&
          runtimeType == other.runtimeType &&
          fps == other.fps &&
          frameTimeMs == other.frameTimeMs &&
          uiTimeMs == other.uiTimeMs &&
          rasterTimeMs == other.rasterTimeMs &&
          frameRate == other.frameRate &&
          averageFrameTimeMs == other.averageFrameTimeMs &&
          minFrameTimeMs == other.minFrameTimeMs &&
          maxFrameTimeMs == other.maxFrameTimeMs &&
          cpuPercent == other.cpuPercent &&
          memory == other.memory &&
          gpu == other.gpu;

  @override
  int get hashCode => Object.hash(
    fps,
    frameTimeMs,
    uiTimeMs,
    rasterTimeMs,
    frameRate,
    averageFrameTimeMs,
    minFrameTimeMs,
    maxFrameTimeMs,
    cpuPercent,
    memory,
    gpu,
  );
}
