import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nordplayer/services/config_service.dart';
import 'package:nordplayer/widgets/nord_snack_bar.dart';

class ArtistsPage extends ConsumerWidget {
  const ArtistsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final appConfig = ref.watch(configServiceProvider).requireValue;

    return Scaffold(
      backgroundColor: appConfig.adaptiveBg
          ? theme.colorScheme.surfaceContainer.withValues(alpha: 0.0)
          : theme.colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: .center,
          children: [
            const Text('Artists'),
            TextButton(
              onPressed: () {
                showNordSnackBar(context: context, message: 'General type example', type: .general);
              },
              child: const Text('Show snack bar general'),
            ),
            TextButton(
              onPressed: () {
                showNordSnackBar(context: context, message: 'Info type example', type: .info);
              },
              child: const Text('Show snack bar info'),
            ),
            TextButton(
              onPressed: () {
                showNordSnackBar(context: context, message: 'Warning type example', type: .warning);
              },
              child: const Text('Show snack bar warning'),
            ),
            TextButton(
              onPressed: () {
                showNordSnackBar(context: context, message: 'Error type example', type: .error);
              },
              child: const Text('Show snack bar error'),
            ),
          ],
        ),
      ),
    );
  }
}
