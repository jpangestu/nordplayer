import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nordplayer/core/database/app_database.dart';
import 'package:nordplayer/data/repositories/drift_queue_repository.dart';

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

/// Riverpod provider exposing the default [QueueRepository] implementation.
final queueRepositoryProvider = Provider<QueueRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return DriftQueueRepository(db);
});
