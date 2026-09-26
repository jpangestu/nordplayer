import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nordplayer/data/database/app_database.dart' hide Track, Album, Artist;
import 'package:nordplayer/data/database/db_mappers.dart';
import 'package:nordplayer/data/repositories/queue_repository.dart';
import 'package:nordplayer/domain/models/composite_models.dart';

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
  });
}
