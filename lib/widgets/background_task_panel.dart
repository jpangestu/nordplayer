import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nordplayer/services/background_task_service.dart';
import 'package:nordplayer/services/config_service.dart';
import 'package:nordplayer/widgets/frosted_glass.dart';

void showBackgroundTaskPanel(BuildContext context, GlobalKey buttonKey) {
  final renderBox = buttonKey.currentContext?.findRenderObject() as RenderBox?;
  if (renderBox == null) return;
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
            left: offset.dx - 320 + renderBox.size.width,
            child: FadeTransition(opacity: animation, child: const BackgroundTaskPanel()),
          ),
        ],
      );
    },
  );
}

class BackgroundTaskPanel extends ConsumerWidget {
  const BackgroundTaskPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final appConfig = ref.watch(configServiceProvider).requireValue;
    final tasks = ref.watch(backgroundTaskServiceProvider);

    if (tasks.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      });
      return const SizedBox.shrink();
    }

    return Material(
      type: MaterialType.transparency,
      child: FrostedGlass(
        backgroundColor: appConfig.adaptiveBg
            ? theme.colorScheme.surfaceContainerHigh.withValues(alpha: appConfig.adaptiveBgThemeOverlay)
            : theme.colorScheme.surfaceContainerHigh,
        blurSigma: appConfig.adaptiveBgPanelBlur,
        borderRadius: 12.0,
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.outlineVariant, width: appConfig.adaptiveBg ? 0 : 2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'BACKGROUND TASKS',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  letterSpacing: 1.0,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 250),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (int i = 0; i < tasks.length; i++) ...[
                        if (i > 0) const SizedBox(height: 12),
                        _TaskItem(task: tasks[i]),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaskItem extends ConsumerWidget {
  final BackgroundTask task;

  const _TaskItem({required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isFailed = task.status == BackgroundTaskStatus.failed;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(task.name, style: theme.textTheme.titleSmall?.copyWith(fontSize: 13, fontWeight: FontWeight.w600)),
              if (task.message.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  task.message,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isFailed ? theme.colorScheme.error : theme.colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ],
              if (task.status == BackgroundTaskStatus.running && !task.isIndeterminate) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(value: task.progress, minHeight: 4),
                ),
              ],
            ],
          ),
        ),
        if (isFailed) ...[
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.close, size: 16, color: theme.colorScheme.onSurfaceVariant),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            splashRadius: 16,
            onPressed: () {
              ref.read(backgroundTaskServiceProvider.notifier).removeTask(task.id);
            },
          ),
        ],
      ],
    );
  }
}
