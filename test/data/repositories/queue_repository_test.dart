import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nordplayer/data/database/app_database.dart' hide Track, Album, Artist;
import 'package:nordplayer/data/database/db_mappers.dart';
import 'package:nordplayer/data/repositories/queue_repository.dart';
import 'package:nordplayer/domain/models/composite_models.dart';
import 'package:nordplayer/domain/models/playback_context.dart';
import 'package:nordplayer/domain/queue/queue_models.dart';

void main() {
  late AppDatabase db;
  late QueueRepository queueRepository;
  late ProviderContainer container;

  late TrackWithArtists trackA;
  late TrackWithArtists trackB;

  setUp(() async {
    db = AppDatabase(
      NativeDatabase.memory(
        setup: (database) {
          database.execute('PRAGMA foreign_keys = ON;');
        },
      ),
    );

    container = ProviderContainer(overrides: [appDatabaseProvider.overrideWithValue(db)]);

    queueRepository = container.read(queueRepositoryProvider);

    // Seed test data
    await db.into(db.artists).insert(ArtistsCompanion.insert(id: const Value(1), name: 'Artist'));
    await db
        .into(db.albums)
        .insert(
          AlbumsCompanion.insert(id: const Value(1), title: 'Album', albumArtPath: const Value('/art/cover.jpg')),
        );

    final track1 = await db
        .into(db.tracks)
        .insertReturning(
          TracksCompanion.insert(
            id: const Value(1),
            title: 'Track A',
            filePath: '/music/track_a.mp3',
            fileHash: 'hash_a',
            artistId: 1,
            albumId: 1,
            durationMs: const Value(200000),
            fileSize: const Value(4000000),
          ),
        );
    final track2 = await db
        .into(db.tracks)
        .insertReturning(
          TracksCompanion.insert(
            id: const Value(2),
            title: 'Track B',
            filePath: '/music/track_b.mp3',
            fileHash: 'hash_b',
            artistId: 1,
            albumId: 1,
            durationMs: const Value(250000),
            fileSize: const Value(5000000),
          ),
        );

    final album = await (db.select(db.albums)..where((a) => a.id.equals(1))).getSingle();
    final artist = await (db.select(db.artists)..where((a) => a.id.equals(1))).getSingle();

    trackA = TrackWithArtists(track: track1.toDomain(), album: album.toDomain(), artists: [artist.toDomain()]);
    trackB = TrackWithArtists(track: track2.toDomain(), album: album.toDomain(), artists: [artist.toDomain()]);
  });

  tearDown(() async {
    await db.close();
    container.dispose();
  });

  group('QueueRepository Tests', () {
    test('saveQueue and loadQueue round-trip restores queue and position', () async {
      await queueRepository.saveQueue([trackA, trackB], '/music/track_b.mp3', const Duration(seconds: 45), 'album', 1);

      final (queue, lastIndex, position, contextType, contextId) = await queueRepository.loadQueue();

      expect(queue.length, 2);
      expect(queue[0].track.title, 'Track A');
      expect(queue[1].track.title, 'Track B');
      expect(lastIndex, 1);
      expect(position, const Duration(seconds: 45));
      expect(contextType, 'album');
      expect(contextId, 1);
    });

    test('updateCurrentPosition modifies resume timestamp in active entry', () async {
      await queueRepository.saveQueue(
        [trackA, trackB],
        '/music/track_a.mp3',
        const Duration(seconds: 10),
        'playlist',
        5,
      );

      await queueRepository.updateCurrentPosition(35000); // 35 seconds

      final (_, lastIndex, position, _, _) = await queueRepository.loadQueue();
      expect(lastIndex, 0);
      expect(position, const Duration(milliseconds: 35000));
    });

    test('saving empty queue clears saved state', () async {
      await queueRepository.saveQueue([trackA], '/music/track_a.mp3', Duration.zero, '', null);
      var (queue, _, _, _, _) = await queueRepository.loadQueue();
      expect(queue.length, 1);

      await queueRepository.saveQueue([], null, Duration.zero, '', null);
      (queue, _, _, _, _) = await queueRepository.loadQueue();
      expect(queue, isEmpty);
    });

    test('verifies PlaybackSessions and QueueEntries schema v3 structures', () async {
      expect(db.schemaVersion, 3);

      await queueRepository.saveQueue(
        [trackA, trackB],
        '/music/track_b.mp3',
        const Duration(seconds: 45),
        'album',
        1,
      );

      // Verify PlaybackSessions table record
      final sessions = await db.select(db.playbackSessions).get();
      expect(sessions.length, 1);
      final session = sessions.first;
      expect(session.id, 1);
      expect(session.activeTrackPath, '/music/track_b.mp3');
      expect(session.activeTrackId, 2);
      expect(session.activeIndex, 1);
      expect(session.positionMs, 45000);
      expect(session.playbackContextType, 'album');
      expect(session.playbackContextId, 1);

      // Verify QueueEntries table records
      final entries = await (db.select(db.queueEntries)..orderBy([(t) => OrderingTerm.asc(t.sortOrder)])).get();
      expect(entries.length, 2);
      expect(entries[0].trackId, 1);
      expect(entries[0].sortOrder, 0);
      expect(entries[0].originalOrder, 0);
      expect(entries[0].source, 'context');
      expect(entries[0].id, isNotEmpty);

      expect(entries[1].trackId, 2);
      expect(entries[1].sortOrder, 1);
      expect(entries[1].originalOrder, 1);
      expect(entries[1].source, 'context');
      expect(entries[1].id, isNotEmpty);
      expect(entries[0].id, isNot(equals(entries[1].id)));
    });

    test('clearAllData wipes playback_sessions and queue_entries', () async {
      await queueRepository.saveQueue([trackA, trackB], '/music/track_a.mp3', Duration.zero, 'manual', null);
      expect(await db.select(db.playbackSessions).get(), isNotEmpty);
      expect(await db.select(db.queueEntries).get(), isNotEmpty);

      await db.clearAllData();

      expect(await db.select(db.playbackSessions).get(), isEmpty);
      expect(await db.select(db.queueEntries).get(), isEmpty);
    });

    test('saveQueueState and restoreQueueState preserve full fidelity state and items', () async {
      final item1 = QueueItem(
        id: 'uuid-1',
        track: trackA,
        source: QueueSource.context,
        originalOrder: 0,
        addedAt: DateTime(2026, 1, 1),
      );
      final item2 = QueueItem(
        id: 'uuid-2',
        track: trackB,
        source: QueueSource.userNext,
        originalOrder: 1,
        addedAt: DateTime(2026, 1, 2),
      );

      final state = QueueState(
        items: [item1, item2],
        shuffleIndices: [1, 0],
        activeIndex: 1,
        isShuffle: true,
        loopMode: LoopMode.single,
        context: const PlaybackContext.playlist(id: 42, title: 'Favorites'),
      );

      await queueRepository.saveQueueState(state, const Duration(seconds: 88));

      final restored = await queueRepository.restoreQueueState();
      expect(restored, isNotNull);
      expect(restored!.resumePosition, const Duration(seconds: 88));

      final restoredState = restored.state;
      expect(restoredState.items.length, 2);
      expect(restoredState.items[0].id, 'uuid-1');
      expect(restoredState.items[0].source, QueueSource.context);
      expect(restoredState.items[0].originalOrder, 0);
      expect(restoredState.items[0].track.track.title, 'Track A');

      expect(restoredState.items[1].id, 'uuid-2');
      expect(restoredState.items[1].source, QueueSource.userNext);
      expect(restoredState.items[1].originalOrder, 1);
      expect(restoredState.items[1].track.track.title, 'Track B');

      expect(restoredState.isShuffle, isTrue);
      expect(restoredState.shuffleIndices, [1, 0]);
      expect(restoredState.activeIndex, 1);
      expect(restoredState.loopMode, LoopMode.single);
      expect(restoredState.context, isA<PlaylistPlaybackContext>());
      expect((restoredState.context as PlaylistPlaybackContext).id, 42);
      expect((restoredState.context as PlaylistPlaybackContext).title, 'Favorites');
    });

    test('updateActiveTrack performs high-speed single-row update on PlaybackSessions', () async {
      await queueRepository.saveQueue([trackA, trackB], '/music/track_a.mp3', Duration.zero, 'album', 1);

      // Verify initial session
      var session = await (db.select(db.playbackSessions)..where((s) => s.id.equals(1))).getSingle();
      expect(session.activeIndex, 0);
      expect(session.activeTrackPath, '/music/track_a.mp3');

      // Update active track via delta
      await queueRepository.updateActiveTrack(1, '/music/track_b.mp3', activeTrackId: 2);

      session = await (db.select(db.playbackSessions)..where((s) => s.id.equals(1))).getSingle();
      expect(session.activeIndex, 1);
      expect(session.activeTrackPath, '/music/track_b.mp3');
      expect(session.activeTrackId, 2);

      // Queue entries should remain untouched
      final entries = await db.select(db.queueEntries).get();
      expect(entries.length, 2);
    });

    test('restoreQueueState anchors activeIndex by activeTrackPath when entries are altered', () async {
      final item1 = QueueItem(
        id: 'uuid-1',
        track: trackA,
        source: QueueSource.context,
        originalOrder: 0,
        addedAt: DateTime(2026, 1, 1),
      );
      final item2 = QueueItem(
        id: 'uuid-2',
        track: trackB,
        source: QueueSource.context,
        originalOrder: 1,
        addedAt: DateTime(2026, 1, 1),
      );

      final state = QueueState(
        items: [item1, item2],
        shuffleIndices: [0, 1],
        activeIndex: 1,
        isShuffle: false,
        loopMode: LoopMode.off,
        context: const AlbumPlaybackContext(id: 1, title: 'Album 1'),
      );

      await queueRepository.saveQueueState(state, const Duration(seconds: 10));

      // Remove entry for trackA from queueEntries table directly (simulating stale or purged entry)
      await (db.delete(db.queueEntries)..where((e) => e.id.equals('uuid-1'))).go();

      final restored = await queueRepository.restoreQueueState();
      expect(restored, isNotNull);
      expect(restored!.state.items.length, 1);
      expect(restored.state.items[0].track.track.filePath, '/music/track_b.mp3');
      // activeIndex was 1 in PlaybackSessions, but since only trackB remains and matches activeTrackPath,
      // activeIndex is anchored to 0!
      expect(restored.state.activeIndex, 0);
    });

    test('updateShuffleMode updates shuffle state and indices without touching QueueEntries', () async {
      await queueRepository.saveQueue([trackA, trackB], '/music/track_a.mp3', Duration.zero, 'album', 1);

      await queueRepository.updateShuffleMode(
        isShuffle: true,
        shuffleIndices: [1, 0],
        activeIndex: 0,
        activeTrackPath: '/music/track_b.mp3',
        activeTrackId: 2,
      );

      final session = await (db.select(db.playbackSessions)..where((s) => s.id.equals(1))).getSingle();
      expect(session.isShuffle, isTrue);
      expect(session.shuffleIndicesJson, '[1,0]');
      expect(session.activeIndex, 0);
      expect(session.activeTrackPath, '/music/track_b.mp3');
      expect(session.activeTrackId, 2);

      final entries = await db.select(db.queueEntries).get();
      expect(entries.length, 2);
    });

    test('updateLoopMode updates loop mode without touching QueueEntries', () async {
      await queueRepository.saveQueue([trackA, trackB], '/music/track_a.mp3', Duration.zero, 'album', 1);

      await queueRepository.updateLoopMode('single');

      final session = await (db.select(db.playbackSessions)..where((s) => s.id.equals(1))).getSingle();
      expect(session.loopMode, 'single');

      final entries = await db.select(db.queueEntries).get();
      expect(entries.length, 2);
    });
  });
}
