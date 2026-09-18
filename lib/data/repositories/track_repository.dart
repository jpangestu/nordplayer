import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nordplayer/core/database/app_database.dart';
import 'package:nordplayer/data/repositories/drift_track_repository.dart';

/// Repository interface abstracting audio track queries, library statistics,
/// search, and maintenance operations.
abstract interface class TrackRepository {
  /// Watches all non-missing tracks in the library, sorted alphabetically by title.
  Stream<List<TrackWithArtists>> watchAllTracks();

  /// Retrieves a specific track with its album and artists by track ID.
  Future<TrackWithArtists?> getTrackById(int id);

  /// Watches recently added non-missing tracks, ordered newest first.
  Stream<List<TrackWithArtists>> watchRecentlyAddedTracks({int limitAmount = 10});

  /// Watches aggregate counts, storage size, and playtime across the library.
  Stream<LibraryStats> watchLibraryStats();

  /// Searches tracks by title, album title, or artist name.
  Stream<List<TrackWithArtists>> searchTracks(String queryStr);

  /// Removes albums and artists that no longer have tracks associated with them.
  Future<void> deleteOrphanedMetadata();

  /// Wipes all library tables and vacuums the database.
  Future<void> clearAllData();
}

/// Riverpod provider exposing the default [TrackRepository] implementation.
final trackRepositoryProvider = Provider<TrackRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return DriftTrackRepository(db);
});

final libraryStatsProvider = StreamProvider<LibraryStats>((ref) {
  return ref.watch(trackRepositoryProvider).watchLibraryStats();
});

final libraryStreamProvider = StreamProvider<List<TrackWithArtists>>((ref) {
  return ref.watch(trackRepositoryProvider).watchAllTracks();
});

final recentlyAddedTracksProvider = StreamProvider<List<TrackWithArtists>>((ref) {
  return ref.watch(trackRepositoryProvider).watchRecentlyAddedTracks(limitAmount: 12);
});

final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(SearchQueryNotifier.new);

class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void updateQuery(String query) {
    state = query;
  }

  void clear() {
    state = '';
  }
}

final searchResultsProvider = StreamProvider.autoDispose<List<TrackWithArtists>>((ref) {
  final query = ref.watch(searchQueryProvider);
  if (query.trim().isEmpty) {
    return Stream.value([]);
  }

  return ref.watch(trackRepositoryProvider).searchTracks(query);
});
