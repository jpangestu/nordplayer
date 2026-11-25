import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nordplayer/config/app_config.dart';
import 'package:nordplayer/ui/shell/title_bar/performance_metrics/performance_metrics.dart';

class PerformancePanel extends ConsumerStatefulWidget {
  const PerformancePanel({super.key});

  @override
  ConsumerState<PerformancePanel> createState() => _PerformancePanelState();
}

class _PerformancePanelState extends ConsumerState<PerformancePanel> {
  bool _isInEditMode = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final perfMetrics = ref.watch(performanceMetricsProvider);

    return Container(
      padding: const .symmetric(horizontal: 6, vertical: 0),
      width: _isInEditMode ? 270 : 260,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'PERFORMANCE METRICS',
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
              const Spacer(),
              IconButton(
                visualDensity: .compact,
                onPressed: () {
                  setState(() {
                    _isInEditMode = !_isInEditMode;
                  });
                },
                icon: const Icon(LucideIcons.settings2),
                iconSize: 14,
              ),
              IconButton(
                visualDensity: .compact,
                onPressed: () {
                  ref.read(performanceMetricsProvider.notifier).resetStats();
                },
                icon: const Icon(LucideIcons.rotateCcw),
                iconSize: 14,
              ),
            ],
          ),

          const SizedBox(height: 6),

          _MetricRow(
            isInEditMode: _isInEditMode,
            metric: .frameRate,
            value: perfMetrics.formattedFrameRate,
          ),
          _MetricRow(
            isInEditMode: _isInEditMode,
            metric: .frameTime,
            value: '${perfMetrics.formattedFrameTime} (${perfMetrics.formattedFps})',
          ),
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Column(
              children: [
                _MetricRow(
                  isInEditMode: _isInEditMode,
                  metric: .uiTime,
                  value: perfMetrics.formattedUiTime,
                ),
                _MetricRow(
                  isInEditMode: _isInEditMode,
                  metric: .rasterTime,
                  value: perfMetrics.formattedRasterTime,
                ),
              ],
            ),
          ),
          _MetricRow(
            isInEditMode: _isInEditMode,
            metric: .averageFrameTime,
            value: perfMetrics.formattedAverageFrameTime,
          ),
          _MetricRow(
            isInEditMode: _isInEditMode,
            metric: .maxFrameTime,
            value: perfMetrics.formattedMinFrameTime,
          ),
          _MetricRow(
            isInEditMode: _isInEditMode,
            metric: .minFrameTime,
            value: perfMetrics.formattedMaxFrameTime,
          ),

          const SizedBox(height: 4),

          _MetricRow(
            isInEditMode: _isInEditMode,
            metric: .cpuUsage,
            value: perfMetrics.formattedCpuUsage,
          ),
          if (perfMetrics.gpu != null) ...[
            _MetricRow(
              isInEditMode: _isInEditMode,
              metric: .gpuUsage,
              value: perfMetrics.formattedGpuUsage,
            ),
            _MetricRow(
              isInEditMode: _isInEditMode,
              metric: .gpuVram,
              value: perfMetrics.formattedGpuVram,
            ),
            _MetricRow(
              isInEditMode: _isInEditMode,
              metric: .gpuShared,
              value: perfMetrics.formattedGpuShared,
            ),
          ],
          _MetricRow(
            isInEditMode: _isInEditMode,
            metric: .ramPrivate,
            value: perfMetrics.formattedRamPrivate,
          ),
          _MetricRow(
            isInEditMode: _isInEditMode,
            metric: .ramRss,
            value: perfMetrics.formattedRamRss,
          ),
          _MetricRow(
            isInEditMode: _isInEditMode,
            metric: .ramCommitted,
            value: perfMetrics.formattedRamCommitted,
          ),
          _MetricRow(
            isInEditMode: _isInEditMode,
            metric: .ramTotal,
            value: perfMetrics.formattedRamTotal,
          ),
          const SizedBox(height: 2),
        ],
      ),
    );
  }
}

class const _MetricRow({
  required final bool isInEditMode,
  required final PerformanceMetric metric,
  required final String value,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final labelColor = metric.isSubRow
        ? colorScheme.onSurfaceVariant.withValues(alpha: 0.8)
        : colorScheme.onSurfaceVariant;

    final valueColor = metric.isSubRow
        ? colorScheme.onSurface.withValues(alpha: 0.9)
        : colorScheme.onSurface;

    final appConfig = ref.watch(appConfigProvider);
    final metricsVisibilityMap = ref.watch(appConfig.performance.metricsVisibility.provider);
    bool isShown = metricsVisibilityMap[metric.key] ?? false;

    return Padding(
      padding: .symmetric(vertical: metric.isSubRow ? 1.5 : 3.0),
      child: Row(
        children: [
          if (isInEditMode) ...[
            GestureDetector(
              onTap: () {
                // Creates a new map and override
                appConfig.performance.metricsVisibility.value = {
                  ...appConfig.performance.metricsVisibility.value,
                  metric.key: !isShown,
                };
              },
              child: Icon(isShown ? LucideIcons.eye : LucideIcons.eyeClosed, size: 11),
            ),
          ],
          const SizedBox(width: 4),
          Text(
            metric.label,
            style: TextStyle(
              fontFamily: 'inter',
              fontSize: metric.isSubRow ? 11 : 12,
              color: labelColor,
            ),
          ),

          const Spacer(),

          Text(
            value,
            style: TextStyle(
              fontFamily: 'jetbrains_mono',
              fontSize: metric.isSubRow ? 11 : 12,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
