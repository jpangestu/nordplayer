import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nordplayer/config/app_config.dart';
import 'package:nordplayer/ui/shell/performance/performance_metrics.dart';

class PerformanceIndicator extends ConsumerWidget {
  const PerformanceIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appConfig = ref.watch(appConfigProvider);
    final metricsVisibility = ref.watch(appConfig.performance.metricsVisibility.provider);
    final perfMetrics = ref.watch(performanceMetricsProvider);

    final visibleMetrics = PerformanceMetric.values.where((metric) {
      final isVisible = metricsVisibility[metric.key] ?? metric.defaultVisible;
      return isVisible && metric.isAvailable(perfMetrics);
    });

    if (visibleMetrics.isEmpty) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        for (final metric in visibleMetrics) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              metric.format(perfMetrics),
              style: const TextStyle(fontFamily: 'jetbrains_mono', fontSize: 11),
            ),
          ),
          if (metric != visibleMetrics.last)
            const Text('|', style: TextStyle(fontFamily: 'jetbrains_mono', fontSize: 11)),
        ],
      ],
    );
  }
}
