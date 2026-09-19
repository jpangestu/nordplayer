import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nordplayer/core/database/app_database.dart' show IgnoredPath;
import 'package:nordplayer/core/services/logger.dart';
import 'package:nordplayer/data/repositories/ignored_paths_repository.dart';

export 'package:nordplayer/data/repositories/ignored_paths_repository.dart' show ignoredPathsProvider;

final ignoredPathsViewModelProvider = Provider<IgnoredPathsViewModel>(IgnoredPathsViewModel.new);

class IgnoredPathsViewModel(final Ref _ref) with LoggerMixin {
  IgnoredPathsRepository get _repository => _ref.read(ignoredPathsRepositoryProvider);

  /// Restores an individual ignored path by removing it from the ignoredPaths table.
  Future<void> restorePath(IgnoredPath path) async {
    try {
      await _repository.restorePath(path.filePath);
      _ref.invalidate(ignoredPathsProvider);
    } catch (e, s) {
      log.e("Failed to restore path '${path.filePath}'", error: e, stackTrace: s);
      rethrow;
    }
  }

  /// Restores all given paths by clearing them from the ignoredPaths table.
  Future<void> restoreAll(List<IgnoredPath> paths) async {
    if (paths.isEmpty) return;
    final filePathsToRestore = paths.map((p) => p.filePath).toList();
    try {
      await _repository.restoreAll(filePathsToRestore);
      _ref.invalidate(ignoredPathsProvider);
    } catch (e, s) {
      log.e("Failed to restore all paths", error: e, stackTrace: s);
      rethrow;
    }
  }

  /// Re-ignores file paths (e.g. on undo).
  Future<void> reignorePaths(List<String> filePaths) async {
    if (filePaths.isEmpty) return;
    try {
      await _repository.reignorePaths(filePaths);
      _ref.invalidate(ignoredPathsProvider);
    } catch (e, s) {
      log.e("Failed to re-ignore paths", error: e, stackTrace: s);
      rethrow;
    }
  }
}
