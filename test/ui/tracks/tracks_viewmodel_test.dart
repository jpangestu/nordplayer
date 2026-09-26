import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nordplayer/data/repositories/playback_repository.dart';
import 'package:nordplayer/data/repositories/track_repository.dart';
import 'package:nordplayer/domain/models/album.dart';
import 'package:nordplayer/domain/models/composite_models.dart';
import 'package:nordplayer/domain/models/track.dart';
import 'package:nordplayer/ui/tracks/tracks_viewmodel.dart';

import '../../../testing/fakes/fake_playback_repository.dart';
import '../../../testing/fakes/fake_track_repository.dart';

TrackWithArtists _createTrack(int id, String title, String path) {
  return TrackWithArtists(
    track: Track(
      id: id,
      title: title,
      filePath: path,
      trackNumber: id,
      trackTotal: 10,
      discNumber: 1,
      discTotal: 1,
      durationMs: 180000,
      fileHash: 'hash_$id',
      fileSize: 1000,
      isMissing: false,
      artistId: 1,
      albumId: 1,
      dateAdded: DateTime.now(),
    ),
    album: const Album(id: 1, title: 'Album 1', year: 2024),
    artists: const [],
  );
}

void main() {
  group('TracksViewModel', () {
    late FakePlaybackRepository fakePlaybackRepo;
    late FakeTrackRepository fakeTrackRepo;
    late ProviderContainer container;

    setUp(() {
      fakePlaybackRepo = FakePlaybackRepository();
      fakeTrackRepo = FakeTrackRepository();
      container = ProviderContainer(
        overrides: [
          playbackRepositoryProvider.overrideWithValue(fakePlaybackRepo),
          trackRepositoryProvider.overrideWithValue(fakeTrackRepo),
        ],
      );
    });

    tearDown(() {
      container.dispose();
      fakePlaybackRepo.dispose();
      fakeTrackRepo.dispose();
    });

    test('playTrack sets playlist with context all_tracks', () {
      final vm = container.read(tracksViewModelProvider.notifier);
      final tracks = [_createTrack(1, 'Track 1', '/music/1.mp3'), _createTrack(2, 'Track 2', '/music/2.mp3')];

      vm.playTrack(tracks, 1);

      expect(fakePlaybackRepo.lastTracks, equals(tracks));
      expect(fakePlaybackRepo.lastInitialIndex, equals(1));
      expect(fakePlaybackRepo.lastContextType, equals('all_tracks'));
      expect(fakePlaybackRepo.lastContextId, isNull);
    });

    test('playTrack ignores invalid indices and empty list', () {
      final vm = container.read(tracksViewModelProvider.notifier);
      final tracks = [_createTrack(1, 'Track 1', '/music/1.mp3')];

      vm.playTrack([], 0);
      expect(fakePlaybackRepo.lastInitialIndex, equals(-1));

      vm.playTrack(tracks, -1);
      expect(fakePlaybackRepo.lastInitialIndex, equals(-1));

      vm.playTrack(tracks, 5);
      expect(fakePlaybackRepo.lastInitialIndex, equals(-1));
    });

    test('playAsPlaylist delegates to playTrack when only one track selected', () {
      final vm = container.read(tracksViewModelProvider.notifier);
      final allTracks = [_createTrack(1, 'Track 1', '/music/1.mp3'), _createTrack(2, 'Track 2', '/music/2.mp3')];

      vm.playAsPlaylist([allTracks[0]], clickedIndex: 0, allTracks: allTracks);

      expect(fakePlaybackRepo.lastTracks, equals(allTracks));
      expect(fakePlaybackRepo.lastInitialIndex, equals(0));
      expect(fakePlaybackRepo.lastContextType, equals('all_tracks'));
    });

    test('playAsPlaylist plays subset of tracks with context play_as_playlist', () {
      final vm = container.read(tracksViewModelProvider.notifier);
      final allTracks = [
        _createTrack(1, 'Track 1', '/music/1.mp3'),
        _createTrack(2, 'Track 2', '/music/2.mp3'),
        _createTrack(3, 'Track 3', '/music/3.mp3'),
      ];
      final selected = [allTracks[0], allTracks[2]];

      vm.playAsPlaylist(selected, clickedIndex: 2, allTracks: allTracks);

      expect(fakePlaybackRepo.lastTracks, equals(selected));
      expect(fakePlaybackRepo.lastInitialIndex, equals(1));
      expect(fakePlaybackRepo.lastContextType, equals('play_as_playlist'));
    });

    test('toggleColumnVisibility updates column state correctly', () {
      final vm = container.read(tracksViewModelProvider.notifier);
      final initialColumns = container.read(tracksViewModelProvider).columns;
      final pathCol = initialColumns.firstWhere((c) => c.id == 'path');
      expect(pathCol.isVisible, isFalse);

      vm.toggleColumnVisibility('path');

      final updatedColumns = container.read(tracksViewModelProvider).columns;
      final updatedPathCol = updatedColumns.firstWhere((c) => c.id == 'path');
      expect(updatedPathCol.isVisible, isTrue);
    });

    test('selectTrack updates selected indices state', () {
      final vm = container.read(tracksViewModelProvider.notifier);
      expect(container.read(tracksViewModelProvider).selectedIndices, isEmpty);

      vm.selectTrack(2, isCtrlSelect: false, isShiftSelect: false);
      expect(container.read(tracksViewModelProvider).selectedIndices, equals({2}));
    });
  });
}
