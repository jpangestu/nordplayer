import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nordplayer/data/services/indexer/duplicate_detector.dart';
import 'package:nordplayer/data/services/indexer/library_indexer.dart';
import 'package:nordplayer/data/services/indexer/library_watcher.dart';
import 'package:nordplayer/domain/models/duplicate_group.dart';
import 'package:nordplayer/domain/models/track.dart';

/// Repository interface abstracting library indexing operations, directory watching,
/// and duplicate track detection.
abstract interface class IndexerRepository {
  /// Triggers a scan of configured library directories for new or modified tracks.
  void scanLibrary();

  /// Forces full re-reading of all audio metadata across existing tracks.
  void reindexTracks();

  /// Generates Chromaprint audio fingerprints for tracks lacking them.
  void generateMissingFingerprints();

  /// Marks all tracks residing within [directoryPath] as missing in the database.
  Future<void> markTracksInDirectoryAsMissing(String directoryPath);

  /// Stops filesystem watching for [directoryPath].
  void stopWatchingDirectory(String directoryPath);

  /// Scans the library database to detect groups of duplicate tracks.
  Future<List<DuplicateGroup>> findDuplicates();

  /// Removes [track] from database and records its path in ignored paths.
  Future<void> ignoreTrack(Track track);

  /// Removes [tracks] from database and records their paths in ignored paths.
  Future<void> ignoreTracks(List<Track> tracks);
}

/// Default implementation of [IndexerRepository] coordinating [LibraryIndexer],
/// [LibraryWatcher], and [DuplicateDetector].
class const DefaultIndexerRepository(
  final LibraryIndexer _indexer,
  final LibraryWatcher _watcher,
  final DuplicateDetector _duplicateDetector,
) implements IndexerRepository {
  @override
  void scanLibrary() => _indexer.scanLibrary();

  @override
  void reindexTracks() => _indexer.reindexTracks();

  @override
  void generateMissingFingerprints() => _indexer.generateMissingFingerprints();

  @override
  Future<void> markTracksInDirectoryAsMissing(String directoryPath) {
    return _indexer.markTracksInDirectoryAsMissing(directoryPath);
  }

  @override
  void stopWatchingDirectory(String directoryPath) {
    _watcher.stopWatchingTrackDirectory(directoryPath);
  }

  @override
  Future<List<DuplicateGroup>> findDuplicates() {
    return _duplicateDetector.findDuplicates();
  }

  @override
  Future<void> ignoreTrack(Track track) {
    return _duplicateDetector.ignorePath(track);
  }

  @override
  Future<void> ignoreTracks(List<Track> tracks) {
    return _duplicateDetector.ignorePaths(tracks);
  }
}

/// Riverpod provider exposing [IndexerRepository].
final indexerRepositoryProvider = Provider<IndexerRepository>((ref) {
  final indexer = ref.watch(libraryIndexerProvider);
  final watcher = ref.watch(libraryWatcherProvider);
  final duplicateDetector = ref.watch(duplicateDetectorProvider);

  return DefaultIndexerRepository(indexer, watcher, duplicateDetector);
});
