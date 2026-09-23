import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nordplayer/core/system/background_task_service.dart';
import 'package:nordplayer/core/system/logger.dart';
import 'package:nordplayer/data/repositories/config_repository.dart';
import 'package:nordplayer/data/repositories/ignored_paths_repository.dart';
import 'package:nordplayer/domain/models/models.dart';
import 'package:nordplayer/features/settings/library_indexer/duplicates_ui_state.dart';
import 'package:nordplayer/services/indexer/duplicate_detector.dart';
import 'package:nordplayer/services/indexer/library_indexer.dart';

export 'package:nordplayer/services/indexer/duplicate_detector.dart' show DuplicateGroup;

/// ViewModel managing state and operations for Duplicate Tracks detection and resolution.
class DuplicatesViewModel extends Notifier<DuplicatesUiState> with LoggerMixin {
  DuplicateDetector get _detector => ref.read(duplicateDetectorProvider);
  IgnoredPathsRepository get _ignoredRepo => ref.read(ignoredPathsRepositoryProvider);
  LibraryIndexer get _libraryIndexer => ref.read(libraryIndexerProvider);

  @override
  DuplicatesUiState build() {
    final configRepo = ref.watch(configRepositoryProvider);

    final configSub = configRepo.watchConfig().listen((config) {
      state = state.copyWith(
        adaptiveBg: config.adaptiveBg,
        adaptiveBgPanelBlur: config.adaptiveBgPanelBlur,
        adaptiveBgThemeOverlay: config.adaptiveBgThemeOverlay,
      );
    });

    ref.listen<List<BackgroundTask>>(backgroundTaskServiceProvider, (previous, next) {
      final wasScanning = previous?.any(
            (t) =>
                (t.id == 'library-scan' || t.id == 'metadata-reindex' || t.id == 'fingerprint-generation') &&
                t.status == BackgroundTaskStatus.running,
          ) ??
          false;
      final isScanningNow = next.any(
        (t) =>
            (t.id == 'library-scan' || t.id == 'metadata-reindex' || t.id == 'fingerprint-generation') &&
            t.status == BackgroundTaskStatus.running,
      );

      state = state.copyWith(isScanning: isScanningNow);

      if (wasScanning && !isScanningNow) {
        state = state.copyWith(isScanningTriggered: true);
        loadDuplicates();
      }
    });

    ref.onDispose(configSub.cancel);

    // Initial load
    Future.microtask(loadDuplicates);

    return DuplicatesUiState(
      adaptiveBg: configRepo.currentConfig.adaptiveBg,
      adaptiveBgPanelBlur: configRepo.currentConfig.adaptiveBgPanelBlur,
      adaptiveBgThemeOverlay: configRepo.currentConfig.adaptiveBgThemeOverlay,
    );
  }

  /// Refreshes duplicate groups from the database.
  Future<void> loadDuplicates() async {
    state = state.copyWith(isLoading: true, errorMessage: () => null);
    try {
      final groups = await _detector.findDuplicates();
      // Clean up manuallyIgnoredTrackIds for IDs no longer in duplicate groups
      final allTrackIds = groups.expand((g) => g.tracks).map((t) => t.id).toSet();
      final retainedIgnoredIds = state.manuallyIgnoredTrackIds.intersection(allTrackIds);

      state = state.copyWith(
        duplicateGroups: groups,
        manuallyIgnoredTrackIds: retainedIgnoredIds,
        isLoading: false,
        isScanningTriggered: false,
      );
    } catch (e, s) {
      log.e("Failed to load duplicates", error: e, stackTrace: s);
      state = state.copyWith(
        isLoading: false,
        isScanningTriggered: false,
        errorMessage: () => e.toString(),
      );
    }
  }

  /// Triggers fingerprint generation in the background if no other task is running.
  void generateMissingFingerprintsIfNeeded() {
    final tasks = ref.read(backgroundTaskServiceProvider);
    final isAnyRunning = tasks.any((t) => t.status == BackgroundTaskStatus.running);
    if (!isAnyRunning) {
      _libraryIndexer.generateMissingFingerprints();
    }
  }

  /// Triggers a library scan to discover new duplicates.
  void triggerRescan() {
    state = state.copyWith(isScanningTriggered: true);
    _libraryIndexer.scanLibrary();
  }

  /// Keeps the best copy of a duplicate group and ignores the rest.
  Future<List<Track>> keepBestCopy(DuplicateGroup group) async {
    final tracksToIgnore = group.tracks.where((t) => t.id != group.preferredTrack.id).toList();
    if (tracksToIgnore.isEmpty) return const [];

    final optimisticIds = Set<int>.from(state.manuallyIgnoredTrackIds)
      ..addAll(tracksToIgnore.map((t) => t.id));

    state = state.copyWith(
      manuallyIgnoredTrackIds: optimisticIds,
      isProcessing: true,
    );

    try {
      await _detector.ignorePaths(tracksToIgnore);
      ref.invalidate(ignoredPathsProvider);
      return tracksToIgnore;
    } catch (e, s) {
      log.e("Failed to keep best copy for '${group.title}'", error: e, stackTrace: s);
      final revertedIds = Set<int>.from(state.manuallyIgnoredTrackIds)
        ..removeAll(tracksToIgnore.map((t) => t.id));
      state = state.copyWith(manuallyIgnoredTrackIds: revertedIds);
      rethrow;
    } finally {
      state = state.copyWith(isProcessing: false);
    }
  }

  /// Keeps all best copies across all duplicate groups and ignores all lower quality copies.
  Future<List<Track>> keepAllBestCopies(List<DuplicateGroup> groups) async {
    final tracksToIgnore = <Track>[];
    for (final group in groups) {
      for (final track in group.tracks) {
        if (track.id != group.preferredTrack.id) {
          tracksToIgnore.add(track);
        }
      }
    }

    if (tracksToIgnore.isEmpty) return const [];

    final optimisticIds = Set<int>.from(state.manuallyIgnoredTrackIds)
      ..addAll(tracksToIgnore.map((t) => t.id));

    state = state.copyWith(
      manuallyIgnoredTrackIds: optimisticIds,
      isProcessing: true,
    );

    try {
      await _detector.ignorePaths(tracksToIgnore);
      ref.invalidate(ignoredPathsProvider);
      return tracksToIgnore;
    } catch (e, s) {
      log.e("Failed to keep all best copies", error: e, stackTrace: s);
      final revertedIds = Set<int>.from(state.manuallyIgnoredTrackIds)
        ..removeAll(tracksToIgnore.map((t) => t.id));
      state = state.copyWith(manuallyIgnoredTrackIds: revertedIds);
      rethrow;
    } finally {
      state = state.copyWith(isProcessing: false);
    }
  }

  /// Ignores an individual duplicate track copy.
  Future<void> ignoreTrack(Track track) async {
    final optimisticIds = Set<int>.from(state.manuallyIgnoredTrackIds)..add(track.id);

    state = state.copyWith(
      manuallyIgnoredTrackIds: optimisticIds,
      isProcessing: true,
    );

    try {
      await _detector.ignorePath(track);
      ref.invalidate(ignoredPathsProvider);
    } catch (e, s) {
      log.e("Failed to ignore track '${track.title}'", error: e, stackTrace: s);
      final revertedIds = Set<int>.from(state.manuallyIgnoredTrackIds)..remove(track.id);
      state = state.copyWith(manuallyIgnoredTrackIds: revertedIds);
      rethrow;
    } finally {
      state = state.copyWith(isProcessing: false);
    }
  }

  /// Restores tracks previously ignored back into the library database.
  Future<void> restoreTracks(List<Track> tracks) async {
    if (tracks.isEmpty) return;

    final optimisticIds = Set<int>.from(state.manuallyIgnoredTrackIds)
      ..removeAll(tracks.map((t) => t.id));
    state = state.copyWith(manuallyIgnoredTrackIds: optimisticIds);

    try {
      await _ignoredRepo.restoreTracks(tracks);
      ref.invalidate(ignoredPathsProvider);
      await loadDuplicates();
    } catch (e, s) {
      log.e("Failed to restore tracks", error: e, stackTrace: s);
      rethrow;
    }
  }
}

/// Riverpod provider exposing [DuplicatesViewModel] and [DuplicatesUiState].
final duplicatesViewModelProvider =
    NotifierProvider.autoDispose<DuplicatesViewModel, DuplicatesUiState>(DuplicatesViewModel.new);
