import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nordplayer/services/config_service.dart';
import 'package:nordplayer/theming/theme-extension/nord_semantic_theme.dart';

class ArtistsPage extends ConsumerStatefulWidget {
  const ArtistsPage({super.key});

  @override
  ConsumerState<ArtistsPage> createState() => _ArtistsPageState();
}

class _ArtistsPageState extends ConsumerState<ArtistsPage> {
  final TextEditingController _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appConfig = ref.watch(configServiceProvider).requireValue;
    final warningColor = Theme.of(context).extension<NordSemanticTheme>()!.warning;

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
              style: Theme.of(context).textTheme.titleLarge!.copyWith(color: warningColor),
            ),
          ],
        ),
      ),
    );
  }
}
