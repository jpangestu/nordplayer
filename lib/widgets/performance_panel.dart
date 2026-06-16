import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nordplayer/services/config_service.dart';
import 'package:nordplayer/services/performance_tracker.dart';
import 'package:nordplayer/theming/icon-sets/app_icon_set.dart';
import 'package:nordplayer/widgets/frosted_glass.dart';

void showPerformancePanel(BuildContext context, GlobalKey buttonKey) {
  final renderBox = buttonKey.currentContext!.findRenderObject() as RenderBox;
  final offset = renderBox.localToGlobal(Offset.zero);

  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss',
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 150),
    pageBuilder: (context, animation, secondaryAnimation) {
      return Stack(
        children: [
          Positioned(
            // Position 8 pixels below the bottom edge of the button
            top: offset.dy + renderBox.size.height + 8,
            // Align the right edge of the panel with the right edge of the button
            // 300 is the fixed width of this details panel to accommodate the toggles
            left: offset.dx - 300 + renderBox.size.width,
            child: FadeTransition(opacity: animation, child: const PerformancePanel()),
          ),
        ],
      );
    },
  );
}

class PerformancePanel extends ConsumerWidget {
  const PerformancePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final appConfig = ref.watch(configServiceProvider).requireValue;

    return Material(
      type: MaterialType.transparency,
      child: FrostedGlass(
        backgroundColor: appConfig.adaptiveBg
            ? theme.colorScheme.surfaceContainerHigh.withValues(alpha: appConfig.adaptiveBgThemeOverlay)
            : theme.colorScheme.surfaceContainerHigh,
        blurSigma: appConfig.adaptiveBgPanelBlur,
        borderRadius: 12.0,
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.outlineVariant, width: appConfig.adaptiveBg ? 0 : 2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: AnimatedBuilder(
            animation: PerformanceTracker.instance,
            builder: (context, _) {
              final tracker = PerformanceTracker.instance;
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'PERFORMANCE METRICS',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          letterSpacing: 1.0,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _PerformanceConfigRow(
                    label: 'Frame Latency',
                    value: tracker.formatLatency(tracker.currentFrameTime),
                    prefKey: 'frameLatency',
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(left: 32.0),
                    child: Column(
                      children: [
                        _PerformanceConfigRow(
                          label: 'UI Build',
                          value: tracker.formatLatency(tracker.currentUiTime),
                          textStyle: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontFamily: 'jetbrains_mono',
                            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                          ),
                        ),
                        _PerformanceConfigRow(
                          label: 'GPU Raster',
                          value: tracker.formatLatency(tracker.currentGpuTime),
                          textStyle: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontFamily: 'jetbrains_mono',
                            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                          ),
                        ),
                        const SizedBox(height: 4),
                        _PerformanceConfigRow(
                          label: 'Potential FPS',
                          value: tracker.isIdle ? 'Idle' : '${tracker.potentialFps} FPS',
                          prefKey: 'potentialFps',
                          textStyle: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontFamily: 'jetbrains_mono',
                            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  _PerformanceConfigRow(
                    label: 'Average Frame Time',
                    value: tracker.isIdle || tracker.averageFrameTime == 0.0
                        ? 'Idle'
                        : tracker.formatLatency(tracker.averageFrameTime),
                    prefKey: 'averageFrameTime',
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(left: 32.0),
                    child: _PerformanceConfigRow(
                      label: 'Avg Potential FPS',
                      value: tracker.isIdle ? 'Idle' : '${tracker.averagePotentialFps} FPS',
                      prefKey: 'avgPotentialFps',
                      textStyle: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'jetbrains_mono',
                        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _PerformanceConfigRow(
                    label: 'Fastest Frame Time',
                    value: tracker.minFrameTime > 0.0 ? tracker.formatLatency(tracker.minFrameTime) : '-',
                    prefKey: 'minFrameTime',
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(left: 32.0),
                    child: _PerformanceConfigRow(
                      label: 'Max Potential FPS',
                      value: tracker.maxPotentialFps > 0 ? '${tracker.maxPotentialFps} FPS' : '-',
                      prefKey: 'maxPotentialFps',
                      textStyle: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'jetbrains_mono',
                        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _PerformanceConfigRow(
                    label: 'Slowest Frame Time',
                    value: tracker.maxFrameTime > 0.0 ? tracker.formatLatency(tracker.maxFrameTime) : '-',
                    prefKey: 'maxFrameTime',
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(left: 32.0),
                    child: _PerformanceConfigRow(
                      label: 'Min Potential FPS',
                      value: tracker.minPotentialFps > 0 ? '${tracker.minPotentialFps} FPS' : '-',
                      prefKey: 'minPotentialFps',
                      textStyle: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'jetbrains_mono',
                        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _PerformanceConfigRow(
                    label: 'Actual Frame Rate',
                    value: tracker.isIdle ? 'Idle' : '${tracker.actualFrameRate} Hz',
                    prefKey: 'actualFrameRate',
                  ),
                  const Divider(height: 16),
                  _PerformanceConfigRow(
                    label: 'CPU Usage',
                    value: '${tracker.cpuUsage.toStringAsFixed(1)} %',
                    prefKey: 'cpuUsage',
                  ),
                  const SizedBox(height: 8),
                  _PerformanceConfigRow(
                    label: 'RAM Usage',
                    value: tracker.formatRam(tracker.ramBytes),
                    prefKey: 'ramUsage',
                  ),
                  const Divider(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        tracker.resetStats();
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Reset Performance Stats', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PerformanceConfigRow extends ConsumerWidget {
  final String label;
  final String value;
  final String? prefKey;
  final TextStyle? textStyle;

  const _PerformanceConfigRow({required this.label, required this.value, this.prefKey, this.textStyle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tracker = PerformanceTracker.instance;
    final appIconSet = ref.watch(appIconProvider);

    return AnimatedBuilder(
      animation: tracker,
      builder: (context, _) {
        final isVisible = prefKey != null ? tracker.isVisible(prefKey!) : false;
        return Row(
          children: [
            if (prefKey != null) ...[
              // Visibility Eye Toggle
              SizedBox(
                width: 24,
                height: 24,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    isVisible ? appIconSet.visible : appIconSet.invisible,
                    size: 16,
                    color: isVisible
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  ),
                  onPressed: () {
                    tracker.toggleVisibility(prefKey!);
                  },
                  tooltip: isVisible ? 'Hide from Title Bar' : 'Show on Title Bar',
                ),
              ),
              const SizedBox(width: 8),
            ],

            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(label, style: textStyle ?? theme.textTheme.bodyMedium),
                  Text(
                    value,
                    style:
                        textStyle ??
                        theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontFamily: 'jetbrains_mono',
                          color: theme.colorScheme.onSurface,
                        ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
