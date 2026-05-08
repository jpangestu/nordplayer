import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nordplayer/database/app_database.dart';
import 'package:nordplayer/services/config_service.dart';
import 'package:nordplayer/services/library_scanner.dart';
import 'package:nordplayer/services/library_watcher.dart';
import 'package:nordplayer/services/logger.dart';
import 'package:nordplayer/services/player_service.dart';
import 'package:nordplayer/services/preference_service.dart';
import 'package:nordplayer/widgets/settings/section_card.dart';
import 'package:nordplayer/widgets/settings/section_header.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class AdvancedPage extends ConsumerWidget with LoggerMixin {
  const AdvancedPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final appConfig = ref.watch(configServiceProvider).requireValue;

    return Scaffold(
      backgroundColor: appConfig.adaptiveBg ? Colors.transparent : theme.colorScheme.surface,

      body: ListView(
        padding: const .all(24),
        children: [
          const SectionHeader(label: 'Reset', labelType: .h1, padding: .only(bottom: 8)),

          SectionCard(
            backgroundColor: theme.colorScheme.errorContainer,
            child: ListTile(
              title: Text(
                'Reset app settings',
                style: TextStyle(color: theme.colorScheme.onError, fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                'Theme, music paths, and player preferences',
                style: TextStyle(color: theme.colorScheme.onError.withValues(alpha: 0.74)),
              ),
              onTap: () => _showResetSettingsDialog(context, ref),
            ),
          ),

          const SizedBox(height: 4),

          SectionCard(
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
      content:
          'This will reset your theme, music paths, and player preferences.\n\nYour library database will remain intact.',
      buttonText: 'Reset Settings',
    );

    if (confirmed == true) {
      log.w("Resetting all settings to default.");

      // Grab the paths BEFORE we overwrite the config
      final oldPaths = ref.read(configServiceProvider).requireValue.musicPaths;

      // Stop playback and clear the queue
      await ref.read(playerServiceProvider).clearQueue();

      // Reset the JSON configs
      await ref.read(configServiceProvider.notifier).resetToDefaults();
      await ref.read(preferenceServiceProvider.notifier).resetToDefaults();

      // Loop through the old paths and explicitly wipe them from the DB and Watcher
      for (final path in oldPaths) {
        ref.read(libraryWatcherProvider).stopWatchingFolder(path);
        await ref.read(libraryScannerProvider).removeTracksInDirectory(path);
      }

      log.i("Settings reset and orphaned database tracks cleared.");
    }
  }

  /// Dialog for wiping the database and cache
  Future<void> _showDeleteDataDialog(BuildContext context, WidgetRef ref) async {
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

        // Stop playback and clear the queue
        await ref.read(playerServiceProvider).clearQueue();

        // Trigger rescan library if music paths still exist
        final currentPaths = ref.read(configServiceProvider).requireValue.musicPaths;
        if (currentPaths.isNotEmpty) {
          log.i("Existing music paths found. Triggering library rescan...");

          // Force Riverpod to wake up and establish the new SQLite connection
          // before the scanner attempts to write to it.
          ref.read(appDatabaseProvider);
          ref.read(libraryScannerProvider).scanLibrary();
        }
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
