import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nordplayer/core/database/app_database.dart';
import 'package:nordplayer/data/repositories/drift_ignored_paths_repository.dart';

/// Repository interface abstracting ignored track paths and restoration operations.
abstract interface class IgnoredPathsRepository {
  /// Fetches all ignored file paths ordered alphabetically.
  Future<List<IgnoredPath>> getIgnoredPaths();

  /// Restores a single file path by removing it from the ignored paths table.
  Future<void> restorePath(String filePath);

  /// Restores multiple file paths by removing them from the ignored paths table.
  Future<void> restoreAll(List<String> filePaths);

  /// Re-adds file paths to the ignored paths table.
  Future<void> reignorePaths(List<String> filePaths);

  /// Restores tracks previously ignored back into the library database atomically.
  Future<void> restoreTracks(List<Track> tracks);
}

/// Riverpod provider exposing the default [IgnoredPathsRepository] implementation.
final ignoredPathsRepositoryProvider = Provider<IgnoredPathsRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return DriftIgnoredPathsRepository(db);
});

/// Provider for loading the list of ignored file paths.
final ignoredPathsProvider = FutureProvider.autoDispose<List<IgnoredPath>>((ref) async {
  return await ref.watch(ignoredPathsRepositoryProvider).getIgnoredPaths();
});
