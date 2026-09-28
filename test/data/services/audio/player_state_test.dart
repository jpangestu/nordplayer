import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nordplayer/data/services/audio/playback_controller.dart';
import 'package:nordplayer/data/services/audio/player_state.dart';
import 'package:nordplayer/domain/models/album.dart';
import 'package:nordplayer/domain/models/composite_models.dart';
import 'package:nordplayer/domain/models/track.dart';

import '../../../../testing/fakes/fake_playback_controller.dart';

void main() {
  group('current5TracksAlbumArtInQueueProvider Tests', () {
    TrackWithArtists createTrack(int id, String? artPath) {
      return TrackWithArtists(
        track: Track(
          id: id,
          title: 'Track $id',
          trackNumber: 1,
          trackTotal: 10,
          discNumber: 1,
          discTotal: 1,
          durationMs: 180000,
          fileHash: 'hash_$id',
          isMissing: false,
          filePath: '/path/track_$id.mp3',
          fileSize: 1024,
          artistId: 1,
          albumId: 1,
          dateAdded: DateTime.now(),
        ),
        album: Album(id: 1, title: 'Album 1', albumArtPath: artPath, year: 2024),
        artists: const [],
      );
    }

    test('initializes with controller currentQueueCoverArt', () {
      final tracks = [
        createTrack(1, '/art1.jpg'),
        createTrack(2, '/art2.jpg'),
      ];
      final controller = FakePlaybackController(initialQueue: tracks);
      final container = ProviderContainer(
        overrides: [
          playbackControllerProvider.overrideWithValue(controller),
        ],
      );
      addTearDown(container.dispose);

      final covers = container.read(current5TracksAlbumArtInQueueProvider);
      expect(covers, equals(['/art1.jpg', '/art2.jpg']));
    });

    test('updates reactively when controller emits new cover art', () async {
      final controller = FakePlaybackController();
      final container = ProviderContainer(
        overrides: [
          playbackControllerProvider.overrideWithValue(controller),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(current5TracksAlbumArtInQueueProvider), isEmpty);

      final tracks = [
        createTrack(1, '/cover_a.jpg'),
        createTrack(2, '/cover_b.jpg'),
      ];
      controller.emitQueue(tracks);
      await pumpEventQueue();

      expect(container.read(current5TracksAlbumArtInQueueProvider), equals(['/cover_a.jpg', '/cover_b.jpg']));
    });
  });
}
