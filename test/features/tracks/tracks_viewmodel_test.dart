import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nordplayer/core/database/app_database.dart';
import 'package:nordplayer/features/tracks/tracks_viewmodel.dart';
import 'package:nordplayer/services/audio/player_service.dart';

class FakePlayerServiceForTracks extends Fake implements PlayerService {
  List<TrackWithArtists> lastTracks = [];
  int lastInitialIndex = -1;
  String lastContextType = '';
  int? lastContextId;

  @override
  Future<void> setPlaylist({
    required List<TrackWithArtists> tracksToPlay,
    required int initialIndex,
    required String playbackContextType,
    int? playbackContextId,
    bool forceReload = false,
    bool autoplay = true,
  }) async {
    lastTracks = List.from(tracksToPlay);
    lastInitialIndex = initialIndex;
    lastContextType = playbackContextType;
    lastContextId = playbackContextId;
  }
}

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
    late FakePlayerServiceForTracks fakePlayer;
    late ProviderContainer container;

    setUp(() {
      fakePlayer = FakePlayerServiceForTracks();
      container = ProviderContainer(overrides: [playerServiceProvider.overrideWithValue(fakePlayer)]);
    });

    tearDown(() {
      container.dispose();
    });

    test('playTrack sets playlist with context all_tracks', () {
      final vm = container.read(tracksViewModelProvider);
      final tracks = [_createTrack(1, 'Track 1', '/music/1.mp3'), _createTrack(2, 'Track 2', '/music/2.mp3')];

      vm.playTrack(tracks, 1);

      expect(fakePlayer.lastTracks, equals(tracks));
      expect(fakePlayer.lastInitialIndex, equals(1));
      expect(fakePlayer.lastContextType, equals('all_tracks'));
      expect(fakePlayer.lastContextId, isNull);
    });

    test('playTrack ignores invalid indices and empty list', () {
      final vm = container.read(tracksViewModelProvider);
      final tracks = [_createTrack(1, 'Track 1', '/music/1.mp3')];

      vm.playTrack([], 0);
      expect(fakePlayer.lastInitialIndex, equals(-1));

      vm.playTrack(tracks, -1);
      expect(fakePlayer.lastInitialIndex, equals(-1));

      vm.playTrack(tracks, 5);
      expect(fakePlayer.lastInitialIndex, equals(-1));
    });

    test('playAsPlaylist delegates to playTrack when only one track selected', () {
      final vm = container.read(tracksViewModelProvider);
      final allTracks = [_createTrack(1, 'Track 1', '/music/1.mp3'), _createTrack(2, 'Track 2', '/music/2.mp3')];

      vm.playAsPlaylist([allTracks[0]], clickedIndex: 0, allTracks: allTracks);

      expect(fakePlayer.lastTracks, equals(allTracks));
      expect(fakePlayer.lastInitialIndex, equals(0));
      expect(fakePlayer.lastContextType, equals('all_tracks'));
    });

    test('playAsPlaylist plays subset of tracks with context play_as_playlist', () {
      final vm = container.read(tracksViewModelProvider);
      final allTracks = [
        _createTrack(1, 'Track 1', '/music/1.mp3'),
        _createTrack(2, 'Track 2', '/music/2.mp3'),
        _createTrack(3, 'Track 3', '/music/3.mp3'),
      ];
      final selected = [allTracks[0], allTracks[2]];

      vm.playAsPlaylist(selected, clickedIndex: 2, allTracks: allTracks);

      expect(fakePlayer.lastTracks, equals(selected));
      expect(fakePlayer.lastInitialIndex, equals(1)); // index of Track 3 within selected
      expect(fakePlayer.lastContextType, equals('play_as_playlist'));
    });
  });
}
