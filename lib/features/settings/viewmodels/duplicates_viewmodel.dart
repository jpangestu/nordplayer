import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nordplayer/core/database/app_database.dart';
import 'package:nordplayer/core/services/background_task_service.dart';
import 'package:nordplayer/core/services/logger.dart';
import 'package:nordplayer/data/repositories/ignored_paths_repository.dart';
import 'package:nordplayer/services/duplicate_detector.dart';
import 'package:nordplayer/services/library_indexer/library_indexer.dart';

/// Provider for loading duplicate groups from the database.
final duplicateGroupsProvider = FutureProvider.autoDispose<List<DuplicateGroup>>((ref) async {
  final detector = ref.watch(duplicateDetectorProvider);
  return await detector.findDuplicates();
});

final duplicatesViewModelProvider =
    Provider<DuplicatesViewModel>(DuplicatesViewModel.new);

class DuplicatesViewModel(final Ref _ref) with LoggerMixin {
  DuplicateDetector get _detector => _ref.read(duplicateDetectorProvider);
  IgnoredPathsRepository get _ignoredRepo => _ref.read(ignoredPathsRepositoryProvider);

  /// Triggers fingerprint generation in the background if no other task is running.
  void generateMissingFingerprintsIfNeeded() {
    final tasks = _ref.read(backgroundTaskServiceProvider);
    final isAnyRunning = tasks.any((t) => t.status == BackgroundTaskStatus.running);
    if (!isAnyRunning) {
      _ref.read(libraryIndexerProvider).generateMissingFingerprints();
    }
  }

  /// Keeps the best copy of a duplicate group and ignores the rest.
  Future<List<Track>> keepBestCopy(DuplicateGroup group) async {
    final tracksToIgnore = group.tracks.where((t) => t.id != group.preferredTrack.id).toList();
    if (tracksToIgnore.isEmpty) return const [];

    try {
      await _detector.ignorePaths(tracksToIgnore);
      _ref.invalidate(duplicateGroupsProvider);
      _ref.invalidate(ignoredPathsProvider);
      return tracksToIgnore;
    } catch (e, s) {
      log.e("Failed to keep best copy for '${group.title}'", error: e, stackTrace: s);
      rethrow;
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

    try {
      await _detector.ignorePaths(tracksToIgnore);
      _ref.invalidate(duplicateGroupsProvider);
      _ref.invalidate(ignoredPathsProvider);
      return tracksToIgnore;
    } catch (e, s) {
      log.e("Failed to keep all best copies", error: e, stackTrace: s);
      rethrow;
    }
  }

  /// Ignores an individual duplicate track copy.
  Future<void> ignoreTrack(Track track) async {
    try {
      await _detector.ignorePath(track);
      _ref.invalidate(duplicateGroupsProvider);
      _ref.invalidate(ignoredPathsProvider);
    } catch (e, s) {
      log.e("Failed to ignore track '${track.title}'", error: e, stackTrace: s);
      rethrow;
    }
  }

  /// Restores tracks previously ignored back into the library database.
  Future<void> restoreTracks(List<Track> tracks) async {
    if (tracks.isEmpty) return;
    try {
      await _ignoredRepo.restoreTracks(tracks);
      _ref.invalidate(duplicateGroupsProvider);
      _ref.invalidate(ignoredPathsProvider);
    } catch (e, s) {
      log.e("Failed to restore tracks", error: e, stackTrace: s);
      rethrow;
    }
  }
}
