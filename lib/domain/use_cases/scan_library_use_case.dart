import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nordplayer/data/repositories/track_repository.dart';
import 'package:nordplayer/data/services/indexer/library_indexer.dart';
import 'package:nordplayer/utils/logger.dart';
import 'package:nordplayer/utils/result.dart';

/// Use case that orchestrates a complete music library scan.
class ScanLibraryUseCase(final Ref _ref) with LoggerMixin {
  TrackRepository get _trackRepo => _ref.read(trackRepositoryProvider);
  LibraryIndexer get _indexer => _ref.read(libraryIndexerProvider);

  /// Executes the library scanning workflow and returns a [Result].
  Future<Result<void>> execute({void Function(int processed, int total)? onProgress}) async {
    try {
      log.i('Executing ScanLibraryUseCase...');
      await _indexer.scanLibrary(onProgress: onProgress);

      // Clean up orphaned metadata after scan
      await _trackRepo.deleteOrphanedMetadata();

      log.i('ScanLibraryUseCase completed successfully.');
      return const Ok(null);
    } catch (e, s) {
      log.e('ScanLibraryUseCase failed', error: e, stackTrace: s);
      return Error(e is Exception ? e : Exception(e.toString()));
    }
  }
}

/// Riverpod provider for [ScanLibraryUseCase].
final scanLibraryUseCaseProvider = Provider<ScanLibraryUseCase>((ref) {
  return ScanLibraryUseCase(ref);
});
