import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nordplayer/ui/shell/performance/performance_metrics.dart';

class PerformancePanel extends ConsumerWidget {
  const PerformancePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final metrics = ref.watch(performanceMetricsProvider);

    return Container(
      padding: const .symmetric(horizontal: 6, vertical: 0),
      width: 270,
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
                  ref.read(performanceMetricsProvider.notifier).resetStats();
                },
                icon: const Icon(LucideIcons.rotateCcw, size: 14),
              ),
            ],
          ),

          const SizedBox(height: 6),

          _MetricRow(label: 'Frame Rate', value: metrics.formattedFrameRate, isEmphasized: true),
          _MetricRow(
            label: 'Frame Latency',
            value: '${metrics.formattedFrameTime} (${metrics.formattedFps})',
          ),
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Column(
              children: [
                _MetricRow(label: 'UI Build', value: metrics.formattedUiTime, isSubRow: true),
                _MetricRow(label: 'GPU Raster', value: metrics.formattedRasterTime, isSubRow: true),
              ],
            ),
          ),
          _MetricRow(label: 'Avg Frame Time', value: metrics.formattedAverageFrameTime),
          _MetricRow(label: 'Fastest Frame', value: metrics.formattedMinFrameTime),
          _MetricRow(label: 'Slowest Frame', value: metrics.formattedMaxFrameTime),

          const SizedBox(height: 4),

          _MetricRow(label: 'CPU Usage', value: metrics.formattedCpuUsage),
          if (metrics.gpu != null) ...[
            _MetricRow(label: 'GPU Usage', value: metrics.formattedGpuUsage),
            _MetricRow(label: 'GPU VRAM', value: metrics.formattedGpuVram),
            _MetricRow(label: 'GPU Shared', value: metrics.formattedGpuShared),
          ],
          _MetricRow(label: 'RAM (Private)', value: metrics.formattedRamPrivate),
          _MetricRow(label: 'RAM (Working Set)', value: metrics.formattedRamRss),
          _MetricRow(label: 'RAM (Committed)', value: metrics.formattedRamCommitted),
          _MetricRow(label: 'System RAM Total', value: metrics.formattedRamTotal),
          const SizedBox(height: 2),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isEmphasized;
  final bool isSubRow;

  const _MetricRow({
    required this.label,
    required this.value,
    this.isEmphasized = false,
    this.isSubRow = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final labelColor = isSubRow
        ? colorScheme.onSurfaceVariant.withValues(alpha: 0.7)
        : colorScheme.onSurfaceVariant;

    final valueColor = isEmphasized
        ? colorScheme.primary
        : (isSubRow ? colorScheme.onSurface.withValues(alpha: 0.85) : colorScheme.onSurface);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: isSubRow ? 1.5 : 3.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontFamily: 'inter', fontSize: isSubRow ? 11 : 12, color: labelColor),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'jetbrains_mono',
              fontSize: isSubRow ? 11 : 12,
              fontWeight: isEmphasized ? FontWeight.w700 : FontWeight.w600,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
