import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nordplayer/core/database/app_database.dart' hide Track;
import 'package:nordplayer/core/utils/string_extension.dart';
import 'package:nordplayer/data/mappers/db_mappers.dart';
import 'package:nordplayer/domain/models/models.dart';

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

/// Drift/SQLite implementation of [IgnoredPathsRepository].
class DriftIgnoredPathsRepository implements IgnoredPathsRepository {
  final AppDatabase _db;

  const DriftIgnoredPathsRepository(this._db);

  @override
  Future<List<IgnoredPath>> getIgnoredPaths() async {
    final paths = await _db.select(_db.ignoredPaths).get();
    return paths.toList()..sort((a, b) => a.filePath.compareTo(b.filePath));
  }

  @override
  Future<void> restorePath(String filePath) async {
    await (_db.delete(_db.ignoredPaths)..where((t) => t.filePath.equals(filePath))).go();
  }

  @override
  Future<void> restoreAll(List<String> filePaths) async {
    if (filePaths.isEmpty) return;
    await (_db.delete(_db.ignoredPaths)..where((t) => t.filePath.isIn(filePaths))).go();
  }

  @override
  Future<void> reignorePaths(List<String> filePaths) async {
    if (filePaths.isEmpty) return;
    await _db.transaction(() async {
      for (final path in filePaths) {
        await _db.into(_db.ignoredPaths).insertOnConflictUpdate(
              IgnoredPathsCompanion(filePath: Value(path)),
            );
      }
    });
  }

  @override
  Future<void> restoreTracks(List<Track> tracks) async {
    if (tracks.isEmpty) return;
    await _db.transaction(() async {
      final filePaths = tracks
          .expand((t) => [t.filePath, t.filePath.normalizePath().toLowerCase()])
          .toSet()
          .toList();
      await (_db.delete(_db.ignoredPaths)..where((t) => t.filePath.isIn(filePaths))).go();

      for (final track in tracks) {
        await _db.into(_db.tracks).insertOnConflictUpdate(track.toCompanion());
        await _db.into(_db.trackArtist).insertOnConflictUpdate(
              TrackArtistCompanion(
                trackId: Value(track.id),
                artistId: Value(track.artistId),
              ),
            );
      }
    });
  }
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
