import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nordplayer/services/config_service.dart';
import 'package:nordplayer/widgets/frosted_glass.dart';

class SectionWrapper extends ConsumerWidget {
  const SectionWrapper({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appConfig = ref.watch(configServiceProvider).requireValue;

    return FrostedGlass(
      blurSigma: 5,
      backgroundColor: appConfig.adaptiveBg
          ? Theme.of(
              context,
            ).colorScheme.surfaceContainer.withValues(alpha: 0.5)
          : Theme.of(context).colorScheme.surfaceContainer,
      borderRadius: 8,
      child: child,
    );
  }
}
