import 'package:flutter/material.dart';
import 'package:nordplayer/services/config_service.dart';
import 'package:nordplayer/widgets/section_header.dart';

class AdvancedPage extends StatelessWidget {
  const AdvancedPage({super.key});

  @override
  Widget build(BuildContext context) {
    final errorColor = Theme.of(context).colorScheme.error;

    return ListView(
      padding: .all(16),
      children: [
        SectionHeader(label: 'Reset'),

        ListTile(
          leading: Icon(Icons.restore_page_outlined, color: errorColor),
          title: Text(
            'Reset App Settings',
            style: TextStyle(color: errorColor, fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            'Reverts theme and paths to default',
            style: TextStyle(color: errorColor.withValues(alpha: 0.74)),
          ),
          onTap: () => _showConfirmationDialog(context),
        ),

        SizedBox(height: 8),
        Divider(),
      ],
    );
  }

  Future<void> _showConfirmationDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reset Settings?'),
          content: Text(
            'This will reset your theme, music paths, and all other preferences to their default values.\n\nThis action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Reset Everything'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await ConfigService().resetToDefaults();
    }
  }
}
