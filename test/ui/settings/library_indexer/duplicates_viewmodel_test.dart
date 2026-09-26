import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nordplayer/data/database/app_database.dart' hide Track;
import 'package:nordplayer/data/repositories/indexer_repository.dart';
import 'package:nordplayer/domain/models/duplicate_group.dart';
import 'package:nordplayer/domain/models/track.dart';
import 'package:nordplayer/ui/settings/library_indexer/duplicates_viewmodel.dart';

import '../../../../testing/fakes/fake_indexer_repository.dart';

Track _createDummyTrack(int id, String title, String path, {int fileSize = 5000000}) {
  return Track(
    id: id,
    title: title,
    trackNumber: 1,
    trackTotal: 10,
    discNumber: 1,
    discTotal: 1,
    durationMs: 180000,
    fileHash: 'hash_$id',
    isMissing: false,
    filePath: path,
    fileSize: fileSize,
    artistId: 1,
    albumId: 1,
    dateAdded: DateTime.now(),
  );
}

void main() {
  group('DuplicatesViewModel', () {
    late AppDatabase db;
    late FakeIndexerRepository fakeIndexerRepo;
    late ProviderContainer container;

    setUp(() async {
      db = AppDatabase(
        NativeDatabase.memory(
          setup: (database) {
            database.execute('PRAGMA foreign_keys = ON;');
          },
        ),
      );
      fakeIndexerRepo = FakeIndexerRepository();
      container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          indexerRepositoryProvider.overrideWithValue(fakeIndexerRepo),
        ],
      );

      // Seed parent artist and album for foreign keys
      await db.into(db.artists).insert(ArtistsCompanion.insert(id: const Value(1), name: 'Artist 1'));
      await db.into(db.albums).insert(AlbumsCompanion.insert(id: const Value(1), title: 'Album 1'));
    });

    tearDown(() async {
      await db.close();
      container.dispose();
    });

    test('initial load populates duplicate groups and sets isLoading false', () async {
      final t1 = _createDummyTrack(1, 'Song A', '/music/a.flac');
      final t2 = _createDummyTrack(2, 'Song A', '/music/a.mp3');
      fakeIndexerRepo.duplicateGroupsToReturn = [
        DuplicateGroup(title: 'Song A', artist: 'Artist A', album: 'Album A', tracks: [t1, t2], preferredTrack: t1),
      ];

      final vm = container.read(duplicatesViewModelProvider.notifier);
      await vm.loadDuplicates();

      final state = container.read(duplicatesViewModelProvider);
      expect(state.isLoading, isFalse);
      expect(state.duplicateGroups.length, equals(1));
      expect(state.filteredGroups.length, equals(1));
      expect(state.showStats, isTrue);
    });

    test('keepBestCopy ignores non-preferred tracks and updates state', () async {
      final t1 = _createDummyTrack(1, 'Song A', '/music/a.flac');
      final t2 = _createDummyTrack(2, 'Song A', '/music/a.mp3');
      final group = DuplicateGroup(
        title: 'Song A',
        artist: 'Artist A',
        album: 'Album A',
        tracks: [t1, t2],
        preferredTrack: t1,
      );
      fakeIndexerRepo.duplicateGroupsToReturn = [group];

      final vm = container.read(duplicatesViewModelProvider.notifier);
      await vm.loadDuplicates();

      final ignored = await vm.keepBestCopy(group);

      expect(ignored, equals([t2]));
      expect(fakeIndexerRepo.lastIgnoredTracks, equals([t2]));

      final state = container.read(duplicatesViewModelProvider);
      expect(state.manuallyIgnoredTrackIds, contains(t2.id));
      // After ignoring t2, only 1 track remains in group, so filteredGroups becomes empty
      expect(state.filteredGroups, isEmpty);
    });

    test('keepAllBestCopies ignores all non-preferred tracks across groups', () async {
      final t1 = _createDummyTrack(1, 'Song A', '/music/a.flac');
      final t2 = _createDummyTrack(2, 'Song A', '/music/a.mp3');
      final g1 = DuplicateGroup(
        title: 'Song A',
        artist: 'Artist A',
        album: 'Album A',
        tracks: [t1, t2],
        preferredTrack: t1,
      );

      final t3 = _createDummyTrack(3, 'Song B', '/music/b.flac');
      final t4 = _createDummyTrack(4, 'Song B', '/music/b.mp3');
      final g2 = DuplicateGroup(
        title: 'Song B',
        artist: 'Artist B',
        album: 'Album B',
        tracks: [t3, t4],
        preferredTrack: t3,
      );
      fakeIndexerRepo.duplicateGroupsToReturn = [g1, g2];

      final vm = container.read(duplicatesViewModelProvider.notifier);
      await vm.loadDuplicates();

      final ignored = await vm.keepAllBestCopies([g1, g2]);

      expect(ignored, equals([t2, t4]));
      expect(fakeIndexerRepo.lastIgnoredTracks, equals([t2, t4]));

      final state = container.read(duplicatesViewModelProvider);
      expect(state.manuallyIgnoredTrackIds, containsAll([t2.id, t4.id]));
      expect(state.filteredGroups, isEmpty);
    });

    test('ignoreTrack ignores a single track and updates state', () async {
      final t1 = _createDummyTrack(1, 'Song A', '/music/a.flac');
      final t2 = _createDummyTrack(2, 'Song A', '/music/a.mp3');
      final group = DuplicateGroup(
        title: 'Song A',
        artist: 'Artist A',
        album: 'Album A',
        tracks: [t1, t2],
        preferredTrack: t1,
      );
      fakeIndexerRepo.duplicateGroupsToReturn = [group];

      final vm = container.read(duplicatesViewModelProvider.notifier);
      await vm.loadDuplicates();

      await vm.ignoreTrack(t2);

      expect(fakeIndexerRepo.lastSingleIgnoredTrack, equals(t2));
      final state = container.read(duplicatesViewModelProvider);
      expect(state.manuallyIgnoredTrackIds, contains(t2.id));
    });

    test('restoreTracks removes from ignoredPaths and re-inserts track', () async {
      // Setup ignored path in DB
      await db.into(db.ignoredPaths).insert(IgnoredPathsCompanion.insert(filePath: '/music/a.mp3'));

      final t = _createDummyTrack(10, 'Song X', '/music/a.mp3');
      final vm = container.read(duplicatesViewModelProvider.notifier);

      await vm.restoreTracks([t]);

      final remainingIgnored = await db.select(db.ignoredPaths).get();
      expect(remainingIgnored, isEmpty);

      final restoredTracks = await db.select(db.tracks).get();
      expect(restoredTracks.length, equals(1));
      expect(restoredTracks.first.id, equals(10));
    });

    test('triggerRescan sets scanningTriggered and invokes library indexer', () {
      final vm = container.read(duplicatesViewModelProvider.notifier);
      vm.triggerRescan();

      expect(fakeIndexerRepo.scanCalled, isTrue);
      expect(container.read(duplicatesViewModelProvider).isScanningTriggered, isTrue);
    });
  });
}
