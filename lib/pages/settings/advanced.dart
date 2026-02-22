import 'dart:io';

import 'package:flutter/material.dart';
import 'package:nordplayer/database/app_database.dart';
import 'package:nordplayer/services/preference_service.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nordplayer/services/config_service.dart';
import 'package:nordplayer/services/logger.dart';
import 'package:nordplayer/widgets/section_header.dart';

class AdvancedPage extends ConsumerWidget with LoggerMixin {
  const AdvancedPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final errorColor = Theme.of(context).colorScheme.error;

    return ListView(
      padding: .all(16),
      children: [
        SectionHeader(label: 'Reset', labelType: .h1),

        ListTile(
          leading: Icon(Icons.refresh_rounded, color: errorColor),
          title: Text(
            'Reset app settings',
            style: TextStyle(color: errorColor, fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            'Theme, music paths, and player preferences',
            style: TextStyle(color: errorColor.withValues(alpha: 0.74)),
          ),
          onTap: () => _showResetSettingsDialog(context, ref),
        ),

        const SizedBox(height: 8),

        ListTile(
          leading: Icon(Icons.delete_forever_outlined, color: errorColor),
          title: Text(
            'Clear music library',
            style: TextStyle(color: errorColor, fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            'Wipes database and album art (does not delete music files)',
            style: TextStyle(color: errorColor.withValues(alpha: 0.74)),
          ),
          onTap: () => _showDeleteDataDialog(context, ref),
        ),

        SizedBox(height: 8),
        Divider(),
      ],
    );
  }

  /// Dialog for resetting preferences only
  Future<void> _showResetSettingsDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirmed = await _confirmAction(
      context,
      title: 'Reset Settings?',
      content:
          'This will reset your theme, music paths, and player preferences.\n\nYour library database will remain intact.',
      buttonText: 'Reset Settings',
    );

    if (confirmed == true) {
      log.w("Resetting all settings to default.");
      await ConfigService().resetToDefaults();
      await ref.read(preferenceServiceProvider.notifier).resetToDefaults();
    }
  }

  /// Dialog for wiping the database and cache
  Future<void> _showDeleteDataDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirmed = await _confirmAction(
      context,
      title: 'Delete All Library Data?',
      content:
          'This will wipe your entire music database and all cached album art.\n\nYou will need to scan your library again.',
      buttonText: 'Delete Everything',
    );

    if (confirmed == true) {
      log.w("User confirmed full data deletion.");
      log.w("Starting full application data wipe...");

      try {
        ref.invalidate(appDatabaseProvider);
        log.d("Database connection closed.");

        final dbDir = await getApplicationSupportDirectory();
        final dbPath = p.join(dbDir.path, 'database.sqlite');
        final dbFiles = [dbPath, '$dbPath-wal', '$dbPath-shm'];

        for (final path in dbFiles) {
          final file = File(path);
          if (await file.exists()) {
            try {
              await file.delete();
              log.d("Deleted database file: $path");
            } catch (e) {
              log.e("Could not delete $path: $e");
            }
          }
        }

        final cacheDir = await getApplicationCacheDirectory();
        final artDir = Directory(p.join(cacheDir.path, 'album_art'));
        if (await artDir.exists()) {
          await artDir.delete(recursive: true);
          log.d("Album art cache cleared.");
        }

        log.i("Application data wipe complete.");
      } catch (e, s) {
        log.e("Error during data wipe", error: e, stackTrace: s);
      }
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
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(content),
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
          child: Text(buttonText),
        ),
      ],
    ),
  );
}
