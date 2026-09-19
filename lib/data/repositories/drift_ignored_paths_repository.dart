import 'package:drift/drift.dart';
import 'package:nordplayer/core/database/app_database.dart';
import 'package:nordplayer/core/utils/string_extension.dart';
import 'package:nordplayer/data/repositories/ignored_paths_repository.dart';

/// Drift/SQLite implementation of [IgnoredPathsRepository].
class const DriftIgnoredPathsRepository(final AppDatabase _db) implements IgnoredPathsRepository {

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
        await _db.into(_db.tracks).insertOnConflictUpdate(track);
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
