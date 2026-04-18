import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nordplayer/services/config_service.dart';

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
      body: Center(child: Text('Artists')),
    );
  }
}
