import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nordplayer/services/config_service.dart';
import 'package:nordplayer/widgets/frosted_glass.dart';

class SectionCard extends ConsumerWidget {
  const SectionCard({super.key, this.backgroundColor, required this.child});

  final Color? backgroundColor;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appConfig = ref.watch(configServiceProvider).requireValue;
    final surfaceContainerLow = Theme.of(context).colorScheme.surfaceContainerLow;

    final defaultBackgroundColor = appConfig.adaptiveBg
        ? surfaceContainerLow.withValues(alpha: appConfig.adaptiveBgThemeOverlay)
        : surfaceContainerLow;

    return FrostedGlass(
      blurSigma: appConfig.adaptiveBgPanelBlur,
      backgroundColor: backgroundColor != null
          ? appConfig.adaptiveBg
                ? backgroundColor!.withValues(alpha: appConfig.adaptiveBgThemeOverlay)
                : backgroundColor!
          : defaultBackgroundColor,
      borderRadius: 8,
      child: Padding(padding: const EdgeInsets.all(4.0), child: child), // TODO: fix layout
    );
  }
}
