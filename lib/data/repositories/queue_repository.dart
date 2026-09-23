import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nordplayer/data/database/app_database.dart' hide Track, Album, Artist;
import 'package:nordplayer/utils/string_extension.dart';
import 'package:nordplayer/data/database/db_mappers.dart';
import 'package:nordplayer/domain/models/models.dart';

/// Repository interface abstracting player queue persistence, restoration,
/// and active playback position tracking.
abstract interface class QueueRepository {
  /// Persists the active queue state and playback position to SQLite.
  Future<void> saveQueue(
    List<TrackWithArtists> originalQueue,
    String? currentlyPlayedTrackPath,
    Duration resumePositionMs,
    String playbackContextType,
    int? playbackContextId,
  );

  /// Restores the last active queue state from SQLite.
  ///
  /// Returns:
  /// - `originalQueue`: list of tracks in original, unshuffled sequence
  /// - `lastPlayedIndex`: index of the track that was playing in the engine
  /// - `lastPosition`: elapsed playback timestamp
  /// - `playbackContextType`: navigation source type (e.g., 'album', 'playlist')
  /// - `playbackContextId`: associated collection ID
  Future<(List<TrackWithArtists>, int, Duration, String, int?)> loadQueue();

  /// Updates the playback position timestamp for the currently playing track.
  Future<void> updateCurrentPosition(int positionInMs);
}

/// Drift/SQLite implementation of [QueueRepository].
class DriftQueueRepository implements QueueRepository {
  final AppDatabase _db;

  const DriftQueueRepository(this._db);

  @override
  Future<void> saveQueue(
    List<TrackWithArtists> originalQueue,
    String? currentlyPlayedTrackPath,
    Duration resumePositionMs,
    String playbackContextType,
    int? playbackContextId,
  ) async {
    await _db.transaction(() async {
      await _db.delete(_db.queueEntries).go();
      final companions = <QueueEntriesCompanion>[];

      for (var i = 0; i < originalQueue.length; i++) {
        final isPlaying = currentlyPlayedTrackPath != null &&
            originalQueue[i].track.filePath.normalizePath().toLowerCase() ==
                currentlyPlayedTrackPath.normalizePath().toLowerCase();

        companions.add(
          QueueEntriesCompanion.insert(
            originalQueueIndex: Value(i),
            trackId: originalQueue[i].track.id,
            isCurrentlyPlaying: Value(isPlaying),
            resumePositionMs: Value(isPlaying ? resumePositionMs.inMilliseconds : 0),
            playbackContextType: playbackContextType,
            playbackContextId: Value(playbackContextId),
          ),
        );
      }

      await _db.batch((batch) {
        batch.insertAll(_db.queueEntries, companions);
      });
    });
  }

  @override
  Future<(List<TrackWithArtists>, int, Duration, String, int?)> loadQueue() async {
    final query = _db.select(_db.queueEntries).join([
      innerJoin(
        _db.tracks,
        _db.tracks.id.equalsExp(_db.queueEntries.trackId) & _db.tracks.isMissing.equals(false),
      ),
      leftOuterJoin(_db.albums, _db.albums.id.equalsExp(_db.tracks.albumId)),
      leftOuterJoin(_db.trackArtist, _db.trackArtist.trackId.equalsExp(_db.tracks.id)),
      leftOuterJoin(_db.artists, _db.artists.id.equalsExp(_db.trackArtist.artistId)),
    ])..orderBy([OrderingTerm.asc(_db.queueEntries.originalQueueIndex)]);

    final rows = await query.get();
    if (rows.isEmpty) {
      return (const <TrackWithArtists>[], 0, Duration.zero, '', null);
    }

    // Map keyed by originalQueueIndex to preserve original queue order
    final Map<int, (TrackWithArtists, bool, int)> groupedQueue = {};
    String playbackContextType = '';
    int? playbackContextId;

    for (final row in rows) {
      final entry = row.readTable(_db.queueEntries);
      final track = row.readTable(_db.tracks);
      final album = row.readTable(_db.albums);
      final artist = row.readTableOrNull(_db.artists);

      if (playbackContextType.isEmpty) {
        playbackContextType = entry.playbackContextType;
      }
      if (playbackContextId == null && entry.playbackContextId != null) {
        playbackContextId = entry.playbackContextId;
      }

      final key = entry.originalQueueIndex;
      if (!groupedQueue.containsKey(key)) {
        groupedQueue[key] = (
          TrackWithArtists(
            track: track.toDomain(),
            album: album.toDomain(),
            artists: [],
          ),
          entry.isCurrentlyPlaying,
          entry.resumePositionMs,
        );
      }

      if (artist != null && artist.id != 0) {
        final currentArtists = groupedQueue[key]!.$1.artists;
        if (!currentArtists.any((a) => a.id == artist.id)) {
          currentArtists.add(artist.toDomain());
        }
      }
    }

    final originalQueue = <TrackWithArtists>[];
    int lastPlayedIndex = 0;
    Duration lastPosition = Duration.zero;

    for (final record in groupedQueue.values) {
      final (trackWithArtists, isPlaying, resumeMs) = record;
      originalQueue.add(trackWithArtists);
      if (isPlaying) {
        lastPlayedIndex = originalQueue.length - 1;
        lastPosition = Duration(milliseconds: resumeMs);
      }
    }

    return (originalQueue, lastPlayedIndex, lastPosition, playbackContextType, playbackContextId);
  }

  @override
  Future<void> updateCurrentPosition(int positionInMs) async {
    await (_db.update(_db.queueEntries)..where((t) => t.isCurrentlyPlaying.equals(true))).write(
      QueueEntriesCompanion(resumePositionMs: Value(positionInMs)),
    );
  }
}

/// Riverpod provider exposing the default [QueueRepository] implementation.
final queueRepositoryProvider = Provider<QueueRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return DriftQueueRepository(db);
});
