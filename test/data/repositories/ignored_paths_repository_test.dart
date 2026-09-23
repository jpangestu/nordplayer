import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nordplayer/data/database/app_database.dart' hide Track;
import 'package:nordplayer/data/repositories/ignored_paths_repository.dart';
import 'package:nordplayer/domain/models/models.dart';

void main() {
  late AppDatabase db;
  late IgnoredPathsRepository repository;
  late ProviderContainer container;

  setUp(() async {
    db = AppDatabase(
      NativeDatabase.memory(
        setup: (database) {
          database.execute('PRAGMA foreign_keys = ON;');
        },
      ),
    );

    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
      ],
    );

    repository = container.read(ignoredPathsRepositoryProvider);
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  test('getIgnoredPaths returns empty list initially', () async {
    final paths = await repository.getIgnoredPaths();
    expect(paths, isEmpty);
  });

  test('reignorePaths inserts paths and getIgnoredPaths sorts them', () async {
    await repository.reignorePaths(['/b/track.mp3', '/a/track.mp3']);

    final paths = await repository.getIgnoredPaths();
    expect(paths.length, equals(2));
    expect(paths[0].filePath, equals('/a/track.mp3'));
    expect(paths[1].filePath, equals('/b/track.mp3'));
  });

  test('restorePath deletes single path', () async {
    await repository.reignorePaths(['/a/track.mp3', '/b/track.mp3']);

    await repository.restorePath('/a/track.mp3');

    final paths = await repository.getIgnoredPaths();
    expect(paths.length, equals(1));
    expect(paths.first.filePath, equals('/b/track.mp3'));
  });

  test('restoreAll deletes multiple paths', () async {
    await repository.reignorePaths(['/a/track.mp3', '/b/track.mp3', '/c/track.mp3']);

    await repository.restoreAll(['/a/track.mp3', '/c/track.mp3']);

    final paths = await repository.getIgnoredPaths();
    expect(paths.length, equals(1));
    expect(paths.first.filePath, equals('/b/track.mp3'));
  });

  test('restoreTracks deletes paths and re-inserts tracks into library', () async {
    await db.into(db.artists).insert(ArtistsCompanion.insert(id: const Value(1), name: 'Artist 1'));
    await db.into(db.albums).insert(AlbumsCompanion.insert(id: const Value(1), title: 'Album 1'));

    final track = Track(
      id: 1,
      title: 'Restored Song',
      filePath: '/music/restored.mp3',
      trackNumber: 1,
      trackTotal: 1,
      discNumber: 1,
      discTotal: 1,
      durationMs: 200000,
      fileHash: 'hash_restored',
      fileSize: 5000,
      isMissing: false,
      artistId: 1,
      albumId: 1,
      dateAdded: DateTime.now(),
    );

    await repository.reignorePaths(['/music/restored.mp3']);

    await repository.restoreTracks([track]);

    final ignored = await repository.getIgnoredPaths();
    expect(ignored, isEmpty);

    final dbTracks = await db.select(db.tracks).get();
    expect(dbTracks.length, equals(1));
    expect(dbTracks.first.title, equals('Restored Song'));
  });
}
