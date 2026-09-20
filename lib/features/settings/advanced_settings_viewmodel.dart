import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nordplayer/core/system/config_service.dart';
import 'package:nordplayer/core/system/logger.dart';
import 'package:nordplayer/core/system/preference_service.dart';
import 'package:nordplayer/data/repositories/album_repository.dart';
import 'package:nordplayer/data/repositories/track_repository.dart';
import 'package:nordplayer/services/indexer/library_indexer.dart';
import 'package:nordplayer/services/indexer/library_watcher.dart';
import 'package:nordplayer/services/audio/player_service.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

final advancedSettingsViewModelProvider =
    Provider<AdvancedSettingsViewModel>(AdvancedSettingsViewModel.new);

class AdvancedSettingsViewModel with LoggerMixin {
  final Ref _ref;

  AdvancedSettingsViewModel(this._ref);

  /// Resets app preferences and JSON configuration back to initial defaults,
  /// while stopping playback, clearing queues, and un-watching old directories.
  Future<void> resetSettingsToDefault() async {
    log.w("Resetting all settings to default.");

    final oldPaths = _ref.read(configServiceProvider).trackDirectories;

    // Stop playback and clear the active queue
    await _ref.read(playerServiceProvider).clearQueue();

    // Reset JSON configs and SharedPreferences
    await _ref.read(configServiceProvider.notifier).resetToDefaults();
    await _ref.read(preferenceServiceProvider.notifier).resetToDefaults();

    // Stop watching old directories and mark their tracks as missing
    final watcher = _ref.read(libraryWatcherProvider);
    final indexer = _ref.read(libraryIndexerProvider);
    for (final path in oldPaths) {
      watcher.stopWatchingTrackDirectory(path);
      await indexer.markTracksInDirectoryAsMissing(path);
    }

    // Clean up orphaned artists and albums
    await _ref.read(trackRepositoryProvider).deleteOrphanedMetadata();

    log.i("Settings reset and orphaned database tracks cleared.");
  }

  /// Wipes all indexed music database records and cached album art from disk.
  Future<void> wipeAllLibraryData({Future<Directory> Function()? getCacheDir}) async {
    log.w("Starting full application data wipe...");

    try {
      // Stop playback and clear the queue
      await _ref.read(playerServiceProvider).clearQueue();

      // Clear all database tables
      await _ref.read(trackRepositoryProvider).clearAllData();

      // Allow file handles to release
      await Future.delayed(const Duration(milliseconds: 100));

      // Clear album art cache directory
      final cacheDir = getCacheDir != null ? await getCacheDir() : await getApplicationCacheDirectory();
      final artDir = Directory(p.join(cacheDir.path, 'album_art'));
      if (await artDir.exists()) {
        await artDir.delete(recursive: true);
        log.d("Album art cache cleared.");
      }

      log.i("Application data wipe complete.");

      // Invalidate cached repository data
      _ref.invalidate(randomAlbumsProvider);
      _ref.invalidate(libraryIndexerProvider);

      // Rescan if directories are configured
      final currentPaths = _ref.read(configServiceProvider).trackDirectories;
      if (currentPaths.isNotEmpty) {
        log.i("Existing track directories found. Triggering library rescan...");
        _ref.read(libraryIndexerProvider).scanLibrary();
      }
    } catch (e, s) {
      log.e("Error during full data wipe", error: e, stackTrace: s);
      rethrow;
    }
  }
}
