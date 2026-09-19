import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nordplayer/core/services/config_service.dart';
import 'package:nordplayer/features/settings/viewmodels/advanced_settings_viewmodel.dart';
import 'package:nordplayer/widgets/nord_alert_dialog.dart';
import 'package:nordplayer/widgets/settings/section_container.dart';
import 'package:nordplayer/widgets/settings/section_header.dart';

class AdvancedPage extends ConsumerWidget {
  const AdvancedPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final appConfig = ref.watch(configServiceProvider);

    return Scaffold(
      backgroundColor: appConfig.adaptiveBg ? Colors.transparent : theme.colorScheme.surface,
      body: ListView(
        padding: const .all(24),
        children: [
          const SectionHeader(label: 'Reset', labelType: .h1, padding: .only(bottom: 8)),
          SectionContainer(
            backgroundColor: theme.colorScheme.errorContainer,
            child: ListTile(
              title: Text(
                'Reset app settings',
                style: TextStyle(color: theme.colorScheme.onError, fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                'Themes, music locations, and player preferences',
                style: TextStyle(color: theme.colorScheme.onError.withValues(alpha: 0.74)),
              ),
              onTap: () => _showResetSettingsDialog(context, ref),
            ),
          ),
          const SizedBox(height: 4),
          SectionContainer(
            backgroundColor: theme.colorScheme.error,
            child: ListTile(
              title: Text(
                'Clear music library',
                style: TextStyle(color: theme.colorScheme.onError, fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                'Wipes database and album art (does not delete music files)',
                style: TextStyle(color: theme.colorScheme.onError.withValues(alpha: 0.74)),
              ),
              onTap: () => _showDeleteDataDialog(context, ref),
            ),
          ),
        ],
      ),
    );
  }

  /// Dialog for resetting preferences only
  Future<void> _showResetSettingsDialog(BuildContext context, WidgetRef ref) async {
    final confirmed = await _confirmAction(
      context,
      title: 'Reset Settings?',
      content: 'This will reset your theme, track directories, and player preferences.\n\nYour library database will remain intact.',
      buttonText: 'Reset Settings',
    );

    if (confirmed == true) {
      await ref.read(advancedSettingsViewModelProvider).resetSettingsToDefault();
    }
  }

  /// Dialog for wiping the database and cache
  Future<void> _showDeleteDataDialog(BuildContext context, WidgetRef ref) async {
    final confirmed = await _confirmAction(
      context,
      title: 'Delete All Library Data?',
      content: 'This will wipe your entire music database and all cached album art.\n\nYou will need to scan your library again.',
      buttonText: 'Delete Everything',
    );

    if (confirmed == true) {
      await ref.read(advancedSettingsViewModelProvider).wipeAllLibraryData();
    }
  }
}

/// Reusable confirmation dialog base
Future<bool?> _confirmAction(
  BuildContext context, {
  required String title,
  required String content,
  required String buttonText,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => NordAlertDialog(
      title: title,
      content: Text(content),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          onPressed: () => Navigator.pop(context, true),
          child: Text(buttonText),
        ),
      ],
    ),
  );
}
