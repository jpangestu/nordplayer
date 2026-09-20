import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nordplayer/core/services/background_task_service.dart';
import 'package:nordplayer/core/services/config_service.dart';
import 'package:nordplayer/core/services/logger.dart';
import 'package:nordplayer/services/library_indexer/library_indexer.dart';
import 'package:nordplayer/services/library_watcher.dart';

final libraryIndexerViewModelProvider =
    Provider<LibraryIndexerViewModel>(LibraryIndexerViewModel.new);

final isLibraryScanningProvider = Provider<bool>((ref) {
  final tasks = ref.watch(backgroundTaskServiceProvider);
  return tasks.any((t) => t.id == 'library-scan' && t.status == BackgroundTaskStatus.running);
});

final isLibraryReindexingProvider = Provider<bool>((ref) {
  final tasks = ref.watch(backgroundTaskServiceProvider);
  return tasks.any((t) => t.id == 'metadata-reindex' && t.status == BackgroundTaskStatus.running);
});

final isLibraryFingerprintingProvider = Provider<bool>((ref) {
  final tasks = ref.watch(backgroundTaskServiceProvider);
  return tasks.any((t) => t.id == 'fingerprint-generation' && t.status == BackgroundTaskStatus.running);
});

final isAnyLibraryTaskRunningProvider = Provider<bool>((ref) {
  return ref.watch(isLibraryScanningProvider) ||
      ref.watch(isLibraryReindexingProvider) ||
      ref.watch(isLibraryFingerprintingProvider);
});

class LibraryIndexerViewModel(final Ref _ref) with LoggerMixin {
  /// Checks if any background task is currently active.
  bool get isTaskRunning => _ref.read(isAnyLibraryTaskRunningProvider);

  /// Adds folders to the track directories list and triggers a library scan if new paths were added.
  Future<bool> addFolders(List<String> selectedPaths) async {
    if (selectedPaths.isEmpty) return false;

    final currentPaths = _ref.read(configServiceProvider).trackDirectories;
    final updatedPaths = List<String>.from(currentPaths);
    bool hasChanges = false;

    for (final path in selectedPaths) {
      if (path.isNotEmpty && !updatedPaths.contains(path)) {
        updatedPaths.add(path);
        hasChanges = true;
      }
    }

    if (hasChanges) {
      _ref.read(configServiceProvider.notifier).updateConfig(trackDirectories: updatedPaths);
      triggerScan();
      return true;
    }
    return false;
  }

  /// Removes a folder from track directories, stops directory watching, and marks tracks in it as missing.
  Future<void> removeFolder(String path) async {
    final currentPaths = _ref.read(configServiceProvider).trackDirectories;
    final updatedPaths = List<String>.from(currentPaths)..remove(path);
    _ref.read(configServiceProvider.notifier).updateConfig(trackDirectories: updatedPaths);

    _ref.read(libraryWatcherProvider).stopWatchingTrackDirectory(path);
    await _ref.read(libraryIndexerProvider).markTracksInDirectoryAsMissing(path);
  }

  /// Adds a new artist delimiter if not already present.
  bool addDelimiter(String delimiter) {
    final normalized = delimiter.trim().toLowerCase();
    if (normalized.isEmpty) return false;

    final currentDelimiters = _ref.read(configServiceProvider).artistDelimiters;
    if (currentDelimiters.contains(normalized)) return false;

    final updated = List<String>.from(currentDelimiters)..add(normalized);
    _ref.read(configServiceProvider.notifier).updateConfig(artistDelimiters: updated);
    return true;
  }

  /// Removes an artist delimiter.
  void removeDelimiter(String delimiter) {
    final updated = List<String>.from(_ref.read(configServiceProvider).artistDelimiters)
      ..remove(delimiter);
    _ref.read(configServiceProvider.notifier).updateConfig(artistDelimiters: updated);
  }

  /// Resets artist delimiters to defaults.
  void resetDelimitersToDefault() {
    _ref
        .read(configServiceProvider.notifier)
        .updateConfig(artistDelimiters: AppConfig.defaultArtistDelimiters);
  }

  /// Adds an artist exclusion if not already present (case-insensitive).
  bool addExclusion(String exclusion) {
    final trimmed = exclusion.trim();
    if (trimmed.isEmpty) return false;

    final currentExclusions = _ref.read(configServiceProvider).artistExclusions;
    final alreadyExists = currentExclusions.any((e) => e.toLowerCase() == trimmed.toLowerCase());
    if (alreadyExists) return false;

    final updated = List<String>.from(currentExclusions)..add(trimmed);
    _ref.read(configServiceProvider.notifier).updateConfig(artistExclusions: updated);
    return true;
  }

  /// Removes an artist exclusion.
  void removeExclusion(String exclusion) {
    final updated = List<String>.from(_ref.read(configServiceProvider).artistExclusions)
      ..remove(exclusion);
    _ref.read(configServiceProvider.notifier).updateConfig(artistExclusions: updated);
  }

  /// Resets artist exclusions to defaults.
  void resetExclusionsToDefault() {
    _ref
        .read(configServiceProvider.notifier)
        .updateConfig(artistExclusions: AppConfig.defaultArtistExclusions);
  }

  /// Triggers a normal library scan if no task is running.
  bool triggerScan() {
    if (isTaskRunning) {
      log.w("Cannot trigger scan: background task already running.");
      return false;
    }
    _ref.read(libraryIndexerProvider).scanLibrary();
    return true;
  }

  /// Triggers a full library reindex if no task is running.
  bool triggerReindex() {
    if (isTaskRunning) {
      log.w("Cannot trigger reindex: background task already running.");
      return false;
    }
    _ref.read(libraryIndexerProvider).reindexTracks();
    return true;
  }

  /// Toggles directory watching on or off.
  void toggleWatchFolders(bool value) {
    _ref.read(configServiceProvider.notifier).updateConfig(watchTrackDirectories: value);
  }

  /// Triggers missing fingerprint generation if no task is running.
  bool triggerFingerprint() {
    if (isTaskRunning) {
      log.w("Cannot trigger fingerprint generation: background task already running.");
      return false;
    }
    _ref.read(libraryIndexerProvider).generateMissingFingerprints();
    return true;
  }
}
