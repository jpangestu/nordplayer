import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nordplayer/services/config_service.dart';
import 'package:nordplayer/widgets/frosted_glass.dart';

class NordAlertDialog extends ConsumerWidget {
  const NordAlertDialog({super.key, required this.title, required this.content, required this.actions});

  final String title;
  final Widget content;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final appConfig = ref.watch(configServiceProvider).requireValue;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: FrostedGlass(
        backgroundColor: appConfig.adaptiveBg
            ? theme.colorScheme.surfaceContainer.withValues(alpha: appConfig.adaptiveBgThemeOverlay)
            : theme.colorScheme.surfaceContainer,
        blurSigma: appConfig.adaptiveBgPanelBlur,
        borderRadius: 16, // has to match the container border radius below
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 400, maxWidth: .infinity),
          child: IntrinsicWidth(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: theme.colorScheme.outline, width: 1),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const .all(24),
              child: Column(
                mainAxisSize: .min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),

                  const SizedBox(height: 16),

                  // Textfield
                  content,

                  const SizedBox(height: 24),

                  // Custom Actions
                  Row(
                    mainAxisAlignment: .end,
                    children: [
                      for (int i = 0; i < actions.length; i++) ...[
                        actions[i],
                        if (i < actions.length - 1) const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
