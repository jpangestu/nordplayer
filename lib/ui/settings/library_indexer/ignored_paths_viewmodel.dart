import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nordplayer/data/database/app_database.dart' show IgnoredPath;
import 'package:nordplayer/utils/logger.dart';
import 'package:nordplayer/data/repositories/config_repository.dart';
import 'package:nordplayer/data/repositories/ignored_paths_repository.dart';
import 'package:nordplayer/ui/settings/library_indexer/ignored_paths_ui_state.dart';

export 'package:nordplayer/data/repositories/ignored_paths_repository.dart' show ignoredPathsProvider;

/// ViewModel managing state and operations for Ignored File Paths.
class IgnoredPathsViewModel extends Notifier<IgnoredPathsUiState> with LoggerMixin {
  IgnoredPathsRepository get _repository => ref.read(ignoredPathsRepositoryProvider);

  @override
  IgnoredPathsUiState build() {
    final configRepo = ref.watch(configRepositoryProvider);

    final configSub = configRepo.watchConfig().listen((config) {
      state = state.copyWith(
        adaptiveBg: config.adaptiveBg,
        adaptiveBgPanelBlur: config.adaptiveBgPanelBlur,
        adaptiveBgThemeOverlay: config.adaptiveBgThemeOverlay,
      );
    });

    ref.onDispose(configSub.cancel);

    Future.microtask(loadIgnoredPaths);

    return IgnoredPathsUiState(
      adaptiveBg: configRepo.currentConfig.adaptiveBg,
      adaptiveBgPanelBlur: configRepo.currentConfig.adaptiveBgPanelBlur,
      adaptiveBgThemeOverlay: configRepo.currentConfig.adaptiveBgThemeOverlay,
    );
  }

  /// Loads ignored paths from the repository.
  Future<void> loadIgnoredPaths() async {
    state = state.copyWith(isLoading: true, errorMessage: () => null);
    try {
      final paths = await _repository.getIgnoredPaths();
      final allPathSet = paths.map((p) => p.filePath).toSet();
      final retainedRestored = state.manuallyRestoredPaths.intersection(allPathSet);

      state = state.copyWith(
        paths: paths,
        manuallyRestoredPaths: retainedRestored,
        isLoading: false,
      );
    } catch (e, s) {
      log.e("Failed to load ignored paths", error: e, stackTrace: s);
      state = state.copyWith(isLoading: false, errorMessage: () => e.toString());
    }
  }

  /// Restores an individual ignored path by removing it from the ignoredPaths table.
  Future<void> restorePath(IgnoredPath path) async {
    final updatedRestored = Set<String>.from(state.manuallyRestoredPaths)..add(path.filePath);
    state = state.copyWith(manuallyRestoredPaths: updatedRestored);

    try {
      await _repository.restorePath(path.filePath);
      ref.invalidate(ignoredPathsProvider);
    } catch (e, s) {
      log.e("Failed to restore path '${path.filePath}'", error: e, stackTrace: s);
      final reverted = Set<String>.from(state.manuallyRestoredPaths)..remove(path.filePath);
      state = state.copyWith(manuallyRestoredPaths: reverted);
      rethrow;
    }
  }

  /// Restores all given paths by clearing them from the ignoredPaths table.
  Future<void> restoreAll(List<IgnoredPath> paths) async {
    if (paths.isEmpty) return;
    final filePathsToRestore = paths.map((p) => p.filePath).toList();
    final updatedRestored = Set<String>.from(state.manuallyRestoredPaths)..addAll(filePathsToRestore);
    state = state.copyWith(manuallyRestoredPaths: updatedRestored, isProcessing: true);

    try {
      await _repository.restoreAll(filePathsToRestore);
      ref.invalidate(ignoredPathsProvider);
    } catch (e, s) {
      log.e("Failed to restore all paths", error: e, stackTrace: s);
      final reverted = Set<String>.from(state.manuallyRestoredPaths)..removeAll(filePathsToRestore);
      state = state.copyWith(manuallyRestoredPaths: reverted);
      rethrow;
    } finally {
      state = state.copyWith(isProcessing: false);
    }
  }

  /// Re-ignores file paths (e.g. on undo).
  Future<void> reignorePaths(List<String> filePaths) async {
    if (filePaths.isEmpty) return;
    final updatedRestored = Set<String>.from(state.manuallyRestoredPaths)..removeAll(filePaths);
    state = state.copyWith(manuallyRestoredPaths: updatedRestored);

    try {
      await _repository.reignorePaths(filePaths);
      ref.invalidate(ignoredPathsProvider);
      await loadIgnoredPaths();
    } catch (e, s) {
      log.e("Failed to re-ignore paths", error: e, stackTrace: s);
      rethrow;
    }
  }
}

/// Riverpod provider exposing [IgnoredPathsViewModel] and [IgnoredPathsUiState].
final ignoredPathsViewModelProvider =
    NotifierProvider.autoDispose<IgnoredPathsViewModel, IgnoredPathsUiState>(IgnoredPathsViewModel.new);
