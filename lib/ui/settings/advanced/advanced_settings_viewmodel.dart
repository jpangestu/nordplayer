import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nordplayer/config/app_config.dart';
import 'package:nordplayer/data/repositories/album_repository.dart';
import 'package:nordplayer/data/repositories/config_repository.dart';
import 'package:nordplayer/data/repositories/indexer_repository.dart';
import 'package:nordplayer/data/repositories/playback_repository.dart';
import 'package:nordplayer/data/repositories/settings_repository.dart';
import 'package:nordplayer/data/repositories/track_repository.dart';
import 'package:nordplayer/ui/settings/advanced/advanced_settings_ui_state.dart';
import 'package:nordplayer/utils/logger.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// ViewModel managing operations and state for Advanced Settings (data resets, cache wipes).
class AdvancedSettingsViewModel extends Notifier<AdvancedSettingsUiState> with LoggerMixin {
  ConfigRepository get _configRepo => ref.read(configRepositoryProvider);
  SettingsRepository get _settingsRepo => ref.read(settingsRepositoryProvider);
  PlaybackRepository get _playbackRepo => ref.read(playbackRepositoryProvider);
  IndexerRepository get _indexerRepo => ref.read(indexerRepositoryProvider);
  TrackRepository get _trackRepo => ref.read(trackRepositoryProvider);

  @override
  AdvancedSettingsUiState build() {
    final configRepo = ref.watch(configRepositoryProvider);

    final configSub = configRepo.watchConfig().listen((config) {
      state = state.copyWith(adaptiveBg: config.adaptiveBg);
    });

    ref.onDispose(configSub.cancel);

    return AdvancedSettingsUiState(
      adaptiveBg: configRepo.currentConfig.adaptiveBg,
    );
  }

  /// Resets app preferences and JSON configuration back to initial defaults,
  /// while stopping playback, clearing queues, and un-watching old directories.
  Future<void> resetSettingsToDefault() async {
    log.w("Resetting all settings to default.");
    state = state.copyWith(isProcessing: true);

    try {
      final oldPaths = _configRepo.currentConfig.trackDirectories;

      // Stop playback and clear the active queue
      await _playbackRepo.clearQueue();

      // Reset JSON configs and SharedPreferences
      _configRepo.updateConfig(AppConfig());
      await _settingsRepo.resetToDefaults();

      // Stop watching old directories and mark their tracks as missing
      for (final path in oldPaths) {
        _indexerRepo.stopWatchingDirectory(path);
        await _indexerRepo.markTracksInDirectoryAsMissing(path);
      }

      // Clean up orphaned artists and albums
      await _trackRepo.deleteOrphanedMetadata();

      log.i("Settings reset and orphaned database tracks cleared.");
    } finally {
      state = state.copyWith(isProcessing: false);
    }
  }

  /// Wipes all indexed music database records and cached album art from disk.
  Future<void> wipeAllLibraryData({Future<Directory> Function()? getCacheDir}) async {
    log.w("Starting full application data wipe...");
    state = state.copyWith(isProcessing: true);

    try {
      // Stop playback and clear the queue
      await _playbackRepo.clearQueue();

      // Clear all database tables
      await _trackRepo.clearAllData();

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
      ref.invalidate(randomAlbumsProvider);
      ref.invalidate(indexerRepositoryProvider);

      // Rescan if directories are configured
      final currentPaths = _configRepo.currentConfig.trackDirectories;
      if (currentPaths.isNotEmpty) {
        log.i("Existing track directories found. Triggering library rescan...");
        _indexerRepo.scanLibrary();
      }
    } catch (e, s) {
      log.e("Error during full data wipe", error: e, stackTrace: s);
      rethrow;
    } finally {
      state = state.copyWith(isProcessing: false);
    }
  }
}

/// Riverpod provider for [AdvancedSettingsViewModel] and [AdvancedSettingsUiState].
final advancedSettingsViewModelProvider =
    NotifierProvider<AdvancedSettingsViewModel, AdvancedSettingsUiState>(AdvancedSettingsViewModel.new);
