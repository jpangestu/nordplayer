import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nordplayer/data/database/app_database.dart' hide Track, Album, Artist;
import 'package:nordplayer/data/database/db_mappers.dart';
import 'package:nordplayer/domain/models/album.dart';
import 'package:nordplayer/domain/models/composite_models.dart';
import 'package:nordplayer/domain/models/playback_context.dart';
import 'package:nordplayer/domain/queue/queue_models.dart';
import 'package:nordplayer/utils/string_extension.dart';

/// Model returned when restoring complete persisted player state.
class const RestoredQueueState({
  required final QueueState state,
  required final Duration resumePosition,
});

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

  /// Persists complete [QueueState] with items, shuffle indices, and session details.
  Future<void> saveQueueState(QueueState state, Duration resumePosition);

  /// Fast delta update: updates active track index and file path in PlaybackSessions without touching QueueEntries.
  Future<void> updateActiveTrack(int activeIndex, String? activeTrackPath, {int? activeTrackId});

  /// Fast delta update: updates playback position timestamp for the active session.
  Future<void> updateCurrentPosition(int positionInMs);

  /// Fast delta update: updates shuffle mode and shuffle indices permutation without touching QueueEntries.
  Future<void> updateShuffleMode({
    required bool isShuffle,
    required List<int> shuffleIndices,
    required int activeIndex,
    String? activeTrackPath,
    int? activeTrackId,
  });

  /// Fast delta update: updates loop mode in PlaybackSessions without touching QueueEntries.
  Future<void> updateLoopMode(String loopMode);

  /// Restores complete [QueueState] and playback position from SQLite.
  Future<RestoredQueueState?> restoreQueueState();

  /// Restores the legacy tuple for backward compatibility.
  Future<(List<TrackWithArtists>, int, Duration, String, int?)> loadQueue();
}

/// Drift/SQLite implementation of [QueueRepository].
class const DriftQueueRepository(final AppDatabase _db) implements QueueRepository {
  @override
  Future<void> saveQueue(
    List<TrackWithArtists> originalQueue,
    String? currentlyPlayedTrackPath,
    Duration resumePositionMs,
    String playbackContextType,
    int? playbackContextId,
  ) async {
    if (originalQueue.isEmpty) {
      await _db.transaction(() async {
        await _db.delete(_db.playbackSessions).go();
        await _db.delete(_db.queueEntries).go();
      });
      return;
    }

    int activeIndex = 0;
    if (currentlyPlayedTrackPath != null) {
      final normalizedCurrent = currentlyPlayedTrackPath.normalizePath().toLowerCase();
      for (var i = 0; i < originalQueue.length; i++) {
        if (originalQueue[i].track.filePath.normalizePath().toLowerCase() == normalizedCurrent) {
          activeIndex = i;
          break;
        }
      }
    }

    final items = [
      for (var i = 0; i < originalQueue.length; i++)
        QueueItem.create(
          track: originalQueue[i],
          originalOrder: i,
          source: QueueSource.context,
        ),
    ];

    final state = QueueState(
      items: items,
      shuffleIndices: List.generate(items.length, (i) => i),
      activeIndex: activeIndex,
      isShuffle: false,
      loopMode: LoopMode.off,
      context: PlaybackContext(type: playbackContextType, id: playbackContextId),
    );

    await saveQueueState(state, resumePositionMs);
  }

  @override
  Future<void> saveQueueState(QueueState state, Duration resumePosition) async {
    await _db.transaction(() async {
      if (state.items.isEmpty) {
        await _db.delete(_db.playbackSessions).go();
        await _db.delete(_db.queueEntries).go();
        return;
      }

      final current = state.currentItem;
      final activeTrack = current?.track.track;

      await _db.into(_db.playbackSessions).insertOnConflictUpdate(
        PlaybackSessionsCompanion.insert(
          id: const Value(1),
          activeTrackId: Value(activeTrack?.id),
          activeTrackPath: Value(activeTrack?.filePath),
          activeIndex: Value(state.activeIndex),
          positionMs: Value(resumePosition.inMilliseconds),
          playbackContextType: Value(state.context.type),
          playbackContextId: Value(state.context.id),
          playbackContextTitle: Value(state.context.title),
          isShuffle: Value(state.isShuffle),
          shuffleIndicesJson: Value(state.shuffleIndices.isEmpty ? null : jsonEncode(state.shuffleIndices)),
          loopMode: Value(state.loopMode.name),
          updatedAt: Value(DateTime.now()),
        ),
      );

      final companions = <QueueEntriesCompanion>[];
      for (var i = 0; i < state.items.length; i++) {
        final item = state.items[i];
        companions.add(
          QueueEntriesCompanion.insert(
            id: item.id,
            trackId: item.track.track.id,
            sortOrder: i,
            originalOrder: item.originalOrder,
            source: Value(item.source.name),
            addedAt: Value(item.addedAt),
          ),
        );
      }

      await _db.delete(_db.queueEntries).go();
      await _db.batch((batch) {
        batch.insertAll(_db.queueEntries, companions);
      });
    });
  }

  @override
  Future<void> updateActiveTrack(int activeIndex, String? activeTrackPath, {int? activeTrackId}) async {
    await (_db.update(_db.playbackSessions)..where((s) => s.id.equals(1))).write(
      PlaybackSessionsCompanion(
        activeIndex: Value(activeIndex),
        activeTrackPath: Value(activeTrackPath),
        activeTrackId: Value(activeTrackId),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<void> updateCurrentPosition(int positionInMs) async {
    await (_db.update(_db.playbackSessions)..where((s) => s.id.equals(1))).write(
      PlaybackSessionsCompanion(
        positionMs: Value(positionInMs),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<void> updateShuffleMode({
    required bool isShuffle,
    required List<int> shuffleIndices,
    required int activeIndex,
    String? activeTrackPath,
    int? activeTrackId,
  }) async {
    await (_db.update(_db.playbackSessions)..where((s) => s.id.equals(1))).write(
      PlaybackSessionsCompanion(
        isShuffle: Value(isShuffle),
        shuffleIndicesJson: Value(shuffleIndices.isEmpty ? null : jsonEncode(shuffleIndices)),
        activeIndex: Value(activeIndex),
        activeTrackPath: Value(activeTrackPath),
        activeTrackId: Value(activeTrackId),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<void> updateLoopMode(String loopMode) async {
    await (_db.update(_db.playbackSessions)..where((s) => s.id.equals(1))).write(
      PlaybackSessionsCompanion(
        loopMode: Value(loopMode),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<RestoredQueueState?> restoreQueueState() async {
    final session = await (_db.select(_db.playbackSessions)..where((s) => s.id.equals(1))).getSingleOrNull();
    if (session == null) return null;

    final query = _db.select(_db.queueEntries).join([
      innerJoin(_db.tracks, _db.tracks.id.equalsExp(_db.queueEntries.trackId) & _db.tracks.isMissing.equals(false)),
      leftOuterJoin(_db.albums, _db.albums.id.equalsExp(_db.tracks.albumId)),
      leftOuterJoin(_db.trackArtist, _db.trackArtist.trackId.equalsExp(_db.tracks.id)),
      leftOuterJoin(_db.artists, _db.artists.id.equalsExp(_db.trackArtist.artistId)),
    ])..orderBy([OrderingTerm.asc(_db.queueEntries.sortOrder)]);

    final rows = await query.get();
    if (rows.isEmpty) return null;

    final Map<String, (QueueEntry, TrackWithArtists)> groupedRows = {};
    for (final row in rows) {
      final entry = row.readTable(_db.queueEntries);
      final track = row.readTable(_db.tracks);
      final album = row.readTableOrNull(_db.albums);
      final artist = row.readTableOrNull(_db.artists);

      if (!groupedRows.containsKey(entry.id)) {
        groupedRows[entry.id] = (
          entry,
          TrackWithArtists(
            track: track.toDomain(),
            album: album?.toDomain() ?? const Album(id: 0, title: 'Unknown Album'),
            artists: [],
          ),
        );
      }

      if (artist != null && artist.id != 0) {
        final currentArtists = groupedRows[entry.id]!.$2.artists;
        if (!currentArtists.any((a) => a.id == artist.id)) {
          currentArtists.add(artist.toDomain());
        }
      }
    }

    final items = <QueueItem>[];
    for (final record in groupedRows.values) {
      final (entry, trackWithArtists) = record;
      final source = QueueSource.values.firstWhere(
        (s) => s.name == entry.source,
        orElse: () => QueueSource.context,
      );
      items.add(
        QueueItem(
          id: entry.id,
          track: trackWithArtists,
          source: source,
          originalOrder: entry.originalOrder,
          addedAt: entry.addedAt,
        ),
      );
    }

    if (items.isEmpty) return null;

    List<int> shuffleIndices = const [];
    if (session.shuffleIndicesJson != null && session.shuffleIndicesJson!.isNotEmpty) {
      try {
        final decoded = jsonDecode(session.shuffleIndicesJson!);
        if (decoded is List) {
          shuffleIndices = decoded.cast<int>();
        }
      } catch (_) {}
    }

    if (shuffleIndices.isNotEmpty) {
      final valid = shuffleIndices.where((idx) => idx >= 0 && idx < items.length).toList();
      if (valid.length == items.length && valid.toSet().length == items.length) {
        shuffleIndices = valid;
      } else {
        shuffleIndices = List.generate(items.length, (i) => i);
      }
    }

    final loopMode = LoopMode.values.firstWhere(
      (m) => m.name == session.loopMode,
      orElse: () => LoopMode.off,
    );

    PlaybackContext context;
    final type = session.playbackContextType.toLowerCase();
    if (type == 'album' && session.playbackContextId != null) {
      context = PlaybackContext.album(id: session.playbackContextId!, title: session.playbackContextTitle ?? '');
    } else if (type == 'playlist' && session.playbackContextId != null) {
      context = PlaybackContext.playlist(id: session.playbackContextId!, title: session.playbackContextTitle ?? '');
    } else if (type == 'search') {
      context = PlaybackContext.search(query: session.playbackContextTitle ?? '');
    } else if (type == 'all' || type == 'tracks' || type == 'library' || type == 'all_tracks') {
      context = const PlaybackContext.allTracks();
    } else {
      context = PlaybackContext(
        type: session.playbackContextType,
        id: session.playbackContextId,
        title: session.playbackContextTitle,
      );
    }

    int activeIndex = (session.activeIndex >= 0 && session.activeIndex < items.length)
        ? session.activeIndex
        : 0;

    int foundRawIndex = -1;
    if (session.activeTrackPath != null && session.activeTrackPath!.isNotEmpty) {
      final normalizedSaved = session.activeTrackPath!.normalizePath().toLowerCase();
      foundRawIndex = items.indexWhere(
        (item) => item.track.track.filePath.normalizePath().toLowerCase() == normalizedSaved,
      );
    }
    if (foundRawIndex == -1 && session.activeTrackId != null) {
      foundRawIndex = items.indexWhere(
        (item) => item.track.track.id == session.activeTrackId,
      );
    }
    if (foundRawIndex != -1) {
      if (session.isShuffle && shuffleIndices.isNotEmpty) {
        final posInShuffle = shuffleIndices.indexOf(foundRawIndex);
        if (posInShuffle != -1) {
          activeIndex = posInShuffle;
        }
      } else {
        activeIndex = foundRawIndex;
      }
    }

    final state = QueueState(
      items: items,
      shuffleIndices: shuffleIndices,
      activeIndex: activeIndex,
      isShuffle: session.isShuffle,
      loopMode: loopMode,
      context: context,
    );

    return RestoredQueueState(
      state: state,
      resumePosition: Duration(milliseconds: session.positionMs),
    );
  }

  @override
  Future<(List<TrackWithArtists>, int, Duration, String, int?)> loadQueue() async {
    final restored = await restoreQueueState();
    if (restored == null) {
      return (const <TrackWithArtists>[], 0, Duration.zero, '', null);
    }
    return (
      restored.state.tracks,
      restored.state.activeIndex,
      restored.resumePosition,
      restored.state.context.type,
      restored.state.context.id,
    );
  }
}

/// Riverpod provider exposing the default [QueueRepository] implementation.
final queueRepositoryProvider = Provider<QueueRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return DriftQueueRepository(db);
});
