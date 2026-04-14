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
    final surfaceContainer = Theme.of(context).colorScheme.surfaceContainer;

    final defaultBackgroundColor = appConfig.adaptiveBg
        ? surfaceContainer.withValues(alpha: appConfig.adaptiveBgThemeOverlay)
        : surfaceContainer;

    return FrostedGlass(
      blurSigma: 10,
      backgroundColor: backgroundColor != null
          ? appConfig.adaptiveBg
                ? backgroundColor!.withValues(alpha: appConfig.adaptiveBgThemeOverlay)
                : backgroundColor!
          : defaultBackgroundColor,
      borderRadius: 8,
      child: child,
    );
  }
}
