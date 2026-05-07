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
                showNordSnackBar(
                  context: context,
                  message: 'Created playlist 1 with 12 tracks',
                  type: .success,
                  actionLabel: 'Open Playlist',
                  onAction: (snackbarContext) {},
                );
              },
              child: const Text('Show snack bar with action button'),
            ),
          ],
        ),
      ),
    );
  }
}
