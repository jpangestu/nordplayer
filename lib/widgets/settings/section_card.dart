import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nordplayer/services/config_service.dart';
import 'package:nordplayer/widgets/frosted_glass.dart';

class SectionWrapper extends ConsumerWidget {
  const SectionWrapper({super.key, this.backgroundColor, required this.child});

  final Color? backgroundColor;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appConfig = ref.watch(configServiceProvider).requireValue;

    final defaultBackgroundColor = appConfig.adaptiveBg
        ? Theme.of(context).colorScheme.surfaceContainer.withValues(alpha: 0.5)
        : Theme.of(context).colorScheme.surfaceContainer;

    return FrostedGlass(
      blurSigma: 5,
      backgroundColor: backgroundColor != null
          ? appConfig.adaptiveBg
                ? backgroundColor!.withValues(alpha: 0.5)
                : backgroundColor!
          : defaultBackgroundColor,
      borderRadius: 8,
      child: child,
    );
  }
}
