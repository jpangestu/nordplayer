import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nordplayer/core/database/app_database.dart';
import 'package:nordplayer/features/settings/duplicates_viewmodel.dart';
import 'package:nordplayer/services/duplicate_detector.dart';

class FakeDuplicateDetector extends Fake implements DuplicateDetector {
  List<Track> lastIgnoredTracks = [];
  Track? lastSingleIgnoredTrack;
  List<DuplicateGroup> duplicateGroupsToReturn = [];

  @override
  Future<List<DuplicateGroup>> findDuplicates() async => duplicateGroupsToReturn;

  @override
  Future<void> ignorePaths(List<Track> tracks) async {
    lastIgnoredTracks = List.from(tracks);
  }

  @override
  Future<void> ignorePath(Track track) async {
    lastSingleIgnoredTrack = track;
  }
}

Track _createDummyTrack(int id, String title, String path) {
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
    fileSize: 5000000,
    artistId: 1,
    albumId: 1,
    dateAdded: DateTime.now(),
  );
}

void main() {
  group('DuplicatesViewModel', () {
    late AppDatabase db;
    late FakeDuplicateDetector fakeDetector;
    late ProviderContainer container;

    setUp(() async {
      db = AppDatabase(
        NativeDatabase.memory(
          setup: (database) {
            database.execute('PRAGMA foreign_keys = ON;');
          },
        ),
      );
      fakeDetector = FakeDuplicateDetector();
      container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          duplicateDetectorProvider.overrideWithValue(fakeDetector),
        ],
      );

      // Seed parent artist and album for foreign keys
      await db.into(db.artists).insert(
            ArtistsCompanion.insert(id: const Value(1), name: 'Artist 1'),
          );
      await db.into(db.albums).insert(
            AlbumsCompanion.insert(id: const Value(1), title: 'Album 1'),
          );
    });

    tearDown(() async {
      await db.close();
      container.dispose();
    });

    test('keepBestCopy ignores non-preferred tracks', () async {
      final t1 = _createDummyTrack(1, 'Song A', '/music/a.flac');
      final t2 = _createDummyTrack(2, 'Song A', '/music/a.mp3');
      final group = DuplicateGroup(
        title: 'Song A',
        artist: 'Artist A',
        album: 'Album A',
        tracks: [t1, t2],
        preferredTrack: t1,
      );

      final vm = container.read(duplicatesViewModelProvider);
      final ignored = await vm.keepBestCopy(group);

      expect(ignored, equals([t2]));
      expect(fakeDetector.lastIgnoredTracks, equals([t2]));
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

      final vm = container.read(duplicatesViewModelProvider);
      final ignored = await vm.keepAllBestCopies([g1, g2]);

      expect(ignored, equals([t2, t4]));
      expect(fakeDetector.lastIgnoredTracks, equals([t2, t4]));
    });

    test('ignoreTrack ignores a single track', () async {
      final t1 = _createDummyTrack(1, 'Song A', '/music/a.flac');
      final vm = container.read(duplicatesViewModelProvider);

      await vm.ignoreTrack(t1);

      expect(fakeDetector.lastSingleIgnoredTrack, equals(t1));
    });

    test('restoreTracks removes from ignoredPaths and re-inserts track', () async {
      // Setup ignored path in DB
      await db.into(db.ignoredPaths).insert(
            IgnoredPathsCompanion.insert(filePath: '/music/a.mp3'),
          );

      final t = _createDummyTrack(10, 'Song X', '/music/a.mp3');
      final vm = container.read(duplicatesViewModelProvider);

      await vm.restoreTracks([t]);

      final remainingIgnored = await db.select(db.ignoredPaths).get();
      expect(remainingIgnored, isEmpty);

      final restoredTracks = await db.select(db.tracks).get();
      expect(restoredTracks.length, equals(1));
      expect(restoredTracks.first.id, equals(10));
    });
  });
}
