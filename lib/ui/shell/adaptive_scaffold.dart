import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nordplayer/config/app_config.dart';

class AdaptiveScaffold extends ConsumerWidget {
  final Widget child;

  const AdaptiveScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appConfig = ref.watch(appConfigProvider);
    final isAdaptive = ref.watch(appConfig.adaptiveBg.isEnabled.provider);
    final blurLevel = ref.watch(appConfig.adaptiveBg.blurLevel.provider).toDouble();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: isAdaptive ? Colors.transparent : colorScheme.surface,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (isAdaptive) ...[
            ColoredBox(color: colorScheme.surface.withValues(alpha: 0.85)),
            if (blurLevel > 0)
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: blurLevel, sigmaY: blurLevel),
                child: const SizedBox.expand(),
              ),
          ],

          child,
        ],
      ),
    );
  }
}
