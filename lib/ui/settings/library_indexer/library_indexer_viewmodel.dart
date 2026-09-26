import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nordplayer/config/app_config.dart';
import 'package:nordplayer/data/repositories/config_repository.dart';
import 'package:nordplayer/data/repositories/indexer_repository.dart';
import 'package:nordplayer/data/services/system/background_task_service.dart';
import 'package:nordplayer/ui/settings/library_indexer/library_indexer_ui_state.dart';
import 'package:nordplayer/utils/logger.dart';

/// ViewModel managing state and operations for the Library Indexer settings screen.
class LibraryIndexerViewModel extends Notifier<LibraryIndexerUiState> with LoggerMixin {
  ConfigRepository get _configRepo => ref.read(configRepositoryProvider);
  IndexerRepository get _indexerRepo => ref.read(indexerRepositoryProvider);

  @override
  LibraryIndexerUiState build() {
    final configRepo = ref.watch(configRepositoryProvider);
    final initialConfig = configRepo.currentConfig;
    final initialTasks = ref.watch(backgroundTaskServiceProvider);

    final configSub = configRepo.watchConfig().listen((config) {
      state = state.copyWith(
        trackDirectories: config.trackDirectories,
        watchTrackDirectories: config.watchTrackDirectories,
        artistDelimiters: config.artistDelimiters,
        artistExclusions: config.artistExclusions,
        adaptiveBg: config.adaptiveBg,
      );
    });

    ref.listen(backgroundTaskServiceProvider, (_, nextTasks) {
      _updateTaskStatuses(nextTasks);
    });

    ref.onDispose(configSub.cancel);

    final isScanning = initialTasks.any(
      (t) => t.id == 'library-scan' && t.status == BackgroundTaskStatus.running,
    );
    final isReindexing = initialTasks.any(
      (t) => t.id == 'metadata-reindex' && t.status == BackgroundTaskStatus.running,
    );
    final isFingerprinting = initialTasks.any(
      (t) => t.id == 'fingerprint-generation' && t.status == BackgroundTaskStatus.running,
    );

    return LibraryIndexerUiState(
      trackDirectories: initialConfig.trackDirectories,
      watchTrackDirectories: initialConfig.watchTrackDirectories,
      artistDelimiters: initialConfig.artistDelimiters,
      artistExclusions: initialConfig.artistExclusions,
      isScanning: isScanning,
      isReindexing: isReindexing,
      isFingerprinting: isFingerprinting,
      adaptiveBg: initialConfig.adaptiveBg,
    );
  }

  void _updateTaskStatuses(List<BackgroundTask> tasks) {
    final isScanning = tasks.any(
      (t) => t.id == 'library-scan' && t.status == BackgroundTaskStatus.running,
    );
    final isReindexing = tasks.any(
      (t) => t.id == 'metadata-reindex' && t.status == BackgroundTaskStatus.running,
    );
    final isFingerprinting = tasks.any(
      (t) => t.id == 'fingerprint-generation' && t.status == BackgroundTaskStatus.running,
    );

    if (state.isScanning != isScanning ||
        state.isReindexing != isReindexing ||
        state.isFingerprinting != isFingerprinting) {
      state = state.copyWith(
        isScanning: isScanning,
        isReindexing: isReindexing,
        isFingerprinting: isFingerprinting,
      );
    }
  }

  /// Adds folders to the track directories list and triggers a library scan if new paths were added.
  Future<bool> addFolders(List<String> selectedPaths) async {
    if (selectedPaths.isEmpty) return false;

    final currentPaths = _configRepo.currentConfig.trackDirectories;
    final updatedPaths = List<String>.from(currentPaths);
    bool hasChanges = false;

    for (final path in selectedPaths) {
      if (path.isNotEmpty && !updatedPaths.contains(path)) {
        updatedPaths.add(path);
        hasChanges = true;
      }
    }

    if (hasChanges) {
      _configRepo.updateConfig(_configRepo.currentConfig.copyWith(trackDirectories: updatedPaths));
      triggerScan();
      return true;
    }
    return false;
  }

  /// Removes a folder from track directories, stops directory watching, and marks tracks in it as missing.
  Future<void> removeFolder(String path) async {
    final currentPaths = _configRepo.currentConfig.trackDirectories;
    final updatedPaths = List<String>.from(currentPaths)..remove(path);
    _configRepo.updateConfig(_configRepo.currentConfig.copyWith(trackDirectories: updatedPaths));

    _indexerRepo.stopWatchingDirectory(path);
    await _indexerRepo.markTracksInDirectoryAsMissing(path);
  }

  /// Adds a new artist delimiter if not already present.
  bool addDelimiter(String delimiter) {
    final normalized = delimiter.trim().toLowerCase();
    if (normalized.isEmpty) return false;

    final currentDelimiters = _configRepo.currentConfig.artistDelimiters;
    if (currentDelimiters.contains(normalized)) return false;

    final updated = List<String>.from(currentDelimiters)..add(normalized);
    _configRepo.updateConfig(_configRepo.currentConfig.copyWith(artistDelimiters: updated));
    return true;
  }

  /// Removes an artist delimiter.
  void removeDelimiter(String delimiter) {
    final updated = List<String>.from(_configRepo.currentConfig.artistDelimiters)..remove(delimiter);
    _configRepo.updateConfig(_configRepo.currentConfig.copyWith(artistDelimiters: updated));
  }

  /// Resets artist delimiters to defaults.
  void resetDelimitersToDefault() {
    _configRepo.updateConfig(
      _configRepo.currentConfig.copyWith(artistDelimiters: AppConfig.defaultArtistDelimiters),
    );
  }

  /// Adds an artist exclusion if not already present (case-insensitive).
  bool addExclusion(String exclusion) {
    final trimmed = exclusion.trim();
    if (trimmed.isEmpty) return false;

    final currentExclusions = _configRepo.currentConfig.artistExclusions;
    final alreadyExists = currentExclusions.any((e) => e.toLowerCase() == trimmed.toLowerCase());
    if (alreadyExists) return false;

    final updated = List<String>.from(currentExclusions)..add(trimmed);
    _configRepo.updateConfig(_configRepo.currentConfig.copyWith(artistExclusions: updated));
    return true;
  }

  /// Removes an artist exclusion.
  void removeExclusion(String exclusion) {
    final updated = List<String>.from(_configRepo.currentConfig.artistExclusions)..remove(exclusion);
    _configRepo.updateConfig(_configRepo.currentConfig.copyWith(artistExclusions: updated));
  }

  /// Resets artist exclusions to defaults.
  void resetExclusionsToDefault() {
    _configRepo.updateConfig(
      _configRepo.currentConfig.copyWith(artistExclusions: AppConfig.defaultArtistExclusions),
    );
  }

  /// Toggles directory watching on or off.
  void toggleWatchFolders(bool value) {
    _configRepo.updateConfig(_configRepo.currentConfig.copyWith(watchTrackDirectories: value));
  }

  /// Triggers a normal library scan if no task is running.
  bool triggerScan() {
    if (state.isAnyTaskRunning) {
      log.w("Cannot trigger scan: background task already running.");
      return false;
    }
    _indexerRepo.scanLibrary();
    return true;
  }

  /// Triggers a full library reindex if no task is running.
  bool triggerReindex() {
    if (state.isAnyTaskRunning) {
      log.w("Cannot trigger reindex: background task already running.");
      return false;
    }
    _indexerRepo.reindexTracks();
    return true;
  }

  /// Triggers missing fingerprint generation if no task is running.
  bool triggerFingerprint() {
    if (state.isAnyTaskRunning) {
      log.w("Cannot trigger fingerprint generation: background task already running.");
      return false;
    }
    _indexerRepo.generateMissingFingerprints();
    return true;
  }
}

/// Riverpod provider for [LibraryIndexerViewModel] and [LibraryIndexerUiState].
final libraryIndexerViewModelProvider =
    NotifierProvider<LibraryIndexerViewModel, LibraryIndexerUiState>(LibraryIndexerViewModel.new);
