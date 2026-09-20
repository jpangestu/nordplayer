import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nordplayer/core/services/config_service.dart';
import 'package:nordplayer/core/theme/theme-extension/nord_semantic_theme.dart';

class ArtistsView extends ConsumerWidget {
  const ArtistsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final appConfig = ref.watch(configServiceProvider);
    final warningColor = theme.extension<NordSemanticTheme>()!.warning;

    return Scaffold(
      backgroundColor: appConfig.adaptiveBg
          ? theme.colorScheme.surfaceContainer.withValues(alpha: 0.0)
          : theme.colorScheme.surface,
      body: Padding(
        padding: const .only(top: 32.0),
        child: Row(
          mainAxisAlignment: .center,
          children: [
            Icon(LucideIcons.construction, size: 28, color: warningColor),
            const SizedBox(width: 8),
            Text(
              'Artists page is still under construction',
              style: theme.textTheme.titleLarge!.copyWith(color: warningColor),
            ),
          ],
        ),
      ),
    );
  }
}
