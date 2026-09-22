import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nordplayer/core/database/app_database.dart' hide Album, Artist, Track;
import 'package:nordplayer/data/mappers/db_mappers.dart';
import 'package:nordplayer/domain/models/models.dart';

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

  /// Marks tracks as missing by their database IDs.
  Future<void> markTracksMissingByIds(List<int> trackIds);

  /// Updates a track's file path when moved or renamed.
  Future<void> updateTrackFilePath(int trackId, String newFilePath);

  /// Updates a track's file hash.
  Future<void> updateTrackHash(int trackId, String newHash);

  /// Deletes a track by ID.
  Future<void> deleteTrack(int trackId);
}

/// Drift/SQLite implementation of [TrackRepository].
class const DriftTrackRepository(final AppDatabase _db) implements TrackRepository {

  @override
  Stream<List<TrackWithArtists>> watchAllTracks() {
    final query = (_db.select(_db.tracks)..where((t) => t.isMissing.equals(false))).join([
      leftOuterJoin(_db.albums, _db.albums.id.equalsExp(_db.tracks.albumId)),
      leftOuterJoin(_db.trackArtist, _db.trackArtist.trackId.equalsExp(_db.tracks.id)),
      leftOuterJoin(_db.artists, _db.artists.id.equalsExp(_db.trackArtist.artistId)),
    ])..orderBy([OrderingTerm.asc(_db.tracks.title.lower())]);

    return query.watch().map(_groupTrackRows);
  }

  @override
  Future<TrackWithArtists?> getTrackById(int id) async {
    final query = _db.select(_db.tracks).join([
      leftOuterJoin(_db.albums, _db.albums.id.equalsExp(_db.tracks.albumId)),
      leftOuterJoin(_db.trackArtist, _db.trackArtist.trackId.equalsExp(_db.tracks.id)),
      leftOuterJoin(_db.artists, _db.artists.id.equalsExp(_db.trackArtist.artistId)),
    ])..where(_db.tracks.id.equals(id));

    final rows = await query.get();
    final tracks = _groupTrackRows(rows);
    return tracks.isEmpty ? null : tracks.first;
  }

  @override
  Stream<List<TrackWithArtists>> watchRecentlyAddedTracks({int limitAmount = 10}) {
    final query = (_db.select(_db.tracks)..where((t) => t.isMissing.equals(false))).join([
      leftOuterJoin(_db.albums, _db.albums.id.equalsExp(_db.tracks.albumId)),
      leftOuterJoin(_db.trackArtist, _db.trackArtist.trackId.equalsExp(_db.tracks.id)),
      leftOuterJoin(_db.artists, _db.artists.id.equalsExp(_db.trackArtist.artistId)),
    ]);

    query.orderBy([OrderingTerm.desc(_db.tracks.dateAdded)]);
    query.limit(limitAmount * 4);

    return query.watch().map((rows) => _groupTrackRows(rows).take(limitAmount).toList());
  }

  @override
  Stream<LibraryStats> watchLibraryStats() {
    const query = '''
      SELECT
        (SELECT COUNT(*) FROM tracks WHERE is_missing = 0) AS trackCount,
        (SELECT COUNT(DISTINCT album_id) FROM tracks WHERE album_id IS NOT NULL AND is_missing = 0) AS albumCount,
        (SELECT COUNT(DISTINCT track_artist.artist_id) FROM track_artist INNER JOIN tracks ON tracks.id = track_artist.track_id WHERE tracks.is_missing = 0) AS artistCount,
        (SELECT COUNT(*) FROM playlists) AS playlistCount,
        (SELECT COUNT(DISTINCT genre) FROM tracks WHERE genre IS NOT NULL AND genre != '' AND is_missing = 0) AS genreCount,
        (SELECT SUM(file_size) FROM tracks WHERE is_missing = 0) AS totalSize,
        (SELECT SUM(duration_ms) FROM tracks WHERE is_missing = 0) AS totalDuration
    ''';

    return _db.customSelect(
      query,
      readsFrom: {_db.tracks, _db.albums, _db.artists, _db.playlists},
    ).watchSingle().map((row) {
      return LibraryStats(
        trackCount: row.read<int>('trackCount'),
        albumCount: row.read<int>('albumCount'),
        artistCount: row.read<int>('artistCount'),
        playlistCount: row.read<int>('playlistCount'),
        genreCount: row.read<int>('genreCount'),
        totalSizeBytes: row.read<int?>('totalSize') ?? 0,
        totalPlaytimeMs: row.read<int?>('totalDuration') ?? 0,
      );
    });
  }

  @override
  Stream<List<TrackWithArtists>> searchTracks(String queryStr) {
    final searchTerm = '%$queryStr%';

    final query = _db.select(_db.tracks).join([
      leftOuterJoin(_db.albums, _db.albums.id.equalsExp(_db.tracks.albumId)),
      leftOuterJoin(_db.trackArtist, _db.trackArtist.trackId.equalsExp(_db.tracks.id)),
      leftOuterJoin(_db.artists, _db.artists.id.equalsExp(_db.trackArtist.artistId)),
    ])..where(
      (_db.tracks.title.like(searchTerm) |
              _db.albums.title.like(searchTerm) |
              _db.artists.name.like(searchTerm)) &
          _db.tracks.isMissing.equals(false),
    );

    query.orderBy([OrderingTerm.asc(_db.tracks.title.lower())]);

    return query.watch().map(_groupTrackRows);
  }

  @override
  Future<void> deleteOrphanedMetadata() async {
    await _db.transaction(() async {
      await _db.customStatement('''
        DELETE FROM albums 
        WHERE id NOT IN (SELECT DISTINCT album_id FROM tracks WHERE album_id IS NOT NULL);
      ''');

      await _db.customStatement('''
        DELETE FROM artists 
        WHERE id NOT IN (SELECT DISTINCT artist_id FROM tracks WHERE artist_id IS NOT NULL)
          AND id NOT IN (SELECT DISTINCT album_artist_id FROM albums WHERE album_artist_id IS NOT NULL)
          AND id NOT IN (SELECT DISTINCT artist_id FROM track_artist);
      ''');
    });
  }

  @override
  Future<void> clearAllData() async {
    await _db.customStatement('PRAGMA foreign_keys = OFF;');

    try {
      await _db.transaction(() async {
        await _db.customStatement('DELETE FROM queue_entries;');
        await _db.customStatement('DELETE FROM playlist_track;');
        await _db.customStatement('DELETE FROM track_artist;');

        await _db.customStatement('DELETE FROM playlists;');
        await _db.customStatement('DELETE FROM tracks;');
        await _db.customStatement('DELETE FROM albums;');
        await _db.customStatement('DELETE FROM artists;');
        await _db.customStatement('DELETE FROM ignored_paths;');
      });
    } finally {
      await _db.customStatement('PRAGMA foreign_keys = ON;');
      await _db.customStatement('VACUUM;');
    }
  }

  @override
  Future<void> markTracksMissingByIds(List<int> trackIds) async {
    const int batchSize = 500;
    for (var i = 0; i < trackIds.length; i += batchSize) {
      final end = (i + batchSize < trackIds.length) ? i + batchSize : trackIds.length;
      final batch = trackIds.sublist(i, end);
      await (_db.update(_db.tracks)..where((t) => t.id.isIn(batch)))
          .write(const TracksCompanion(isMissing: Value(true)));
    }
  }

  @override
  Future<void> updateTrackFilePath(int trackId, String newFilePath) async {
    await (_db.update(_db.tracks)..where((t) => t.id.equals(trackId)))
        .write(TracksCompanion(filePath: Value(newFilePath), isMissing: const Value(false)));
  }

  @override
  Future<void> updateTrackHash(int trackId, String newHash) async {
    await (_db.update(_db.tracks)..where((t) => t.id.equals(trackId)))
        .write(TracksCompanion(fileHash: Value(newHash)));
  }

  @override
  Future<void> deleteTrack(int trackId) async {
    await (_db.delete(_db.tracks)..where((t) => t.id.equals(trackId))).go();
  }

  /// Groups flattened join rows into composite [TrackWithArtists] domain entities.
  List<TrackWithArtists> _groupTrackRows(List<TypedResult> rows) {
    final Map<int, TrackWithArtists> groupedTracks = {};

    for (final row in rows) {
      final track = row.readTable(_db.tracks);
      final album = row.readTable(_db.albums);
      final artist = row.readTableOrNull(_db.artists);

      if (!groupedTracks.containsKey(track.id)) {
        groupedTracks[track.id] = TrackWithArtists(
          track: track.toDomain(),
          album: album.toDomain(),
          artists: [],
        );
      }

      if (artist != null && artist.id != 0) {
        final currentArtists = groupedTracks[track.id]!.artists;
        if (!currentArtists.any((a) => a.id == artist.id)) {
          currentArtists.add(artist.toDomain());
        }
      }
    }

    return groupedTracks.values.toList();
  }
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
