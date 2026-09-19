import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nordplayer/core/database/app_database.dart';
import 'package:nordplayer/core/services/logger.dart';

/// Provider for loading the list of ignored file paths.
final ignoredPathsProvider = FutureProvider.autoDispose<List<IgnoredPath>>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  final paths = await db.select(db.ignoredPaths).get();
  return paths.toList()..sort((a, b) => a.filePath.compareTo(b.filePath));
});

final ignoredPathsViewModelProvider = Provider<IgnoredPathsViewModel>(IgnoredPathsViewModel.new);

class IgnoredPathsViewModel(final Ref _ref) with LoggerMixin {
  AppDatabase get _db => _ref.read(appDatabaseProvider);

  /// Restores an individual ignored path by removing it from the ignoredPaths table.
  Future<void> restorePath(IgnoredPath path) async {
    try {
      await (_db.delete(_db.ignoredPaths)..where((t) => t.filePath.equals(path.filePath))).go();
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
      await (_db.delete(_db.ignoredPaths)..where((t) => t.filePath.isIn(filePathsToRestore))).go();
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
      await _db.transaction(() async {
        for (final path in filePaths) {
          await _db.into(_db.ignoredPaths).insertOnConflictUpdate(IgnoredPathsCompanion(filePath: Value(path)));
        }
      });
      _ref.invalidate(ignoredPathsProvider);
    } catch (e, s) {
      log.e("Failed to re-ignore paths", error: e, stackTrace: s);
      rethrow;
    }
  }
}
