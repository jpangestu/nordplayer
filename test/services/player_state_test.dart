import 'package:flutter_test/flutter_test.dart';
import 'package:media_kit/media_kit.dart' hide Track;
import 'package:nordplayer/core/database/app_database.dart';
import 'package:nordplayer/services/player_state.dart';

void main() {
  group('Current5TracksAlbumArtNotifier.calculateCovers Tests', () {
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

    Media createMedia(int id, String? artPath) {
      final track = createTrack(id, artPath);
      return Media(
        track.track.filePath,
        extras: {'title': track.track.title, 'artists': track.artists, 'data': track},
      );
    }

    test('returns empty list for empty playlist', () {
      final covers = Current5TracksAlbumArtNotifier.calculateCovers(
        const Playlist([]),
        PlaylistMode.none,
      );
      expect(covers, isEmpty);
    });

    test('returns empty list for negative playlist index', () {
      final playlist = Playlist([createMedia(1, '/art1.jpg')], index: -1);
      final covers = Current5TracksAlbumArtNotifier.calculateCovers(
        playlist,
        PlaylistMode.none,
      );
      expect(covers, isEmpty);
    });

    test('returns up to 5 covers starting from current index when loop is none', () {
      final medias = List.generate(8, (i) => createMedia(i + 1, '/art${i + 1}.jpg'));
      final playlist = Playlist(medias, index: 2);

      final covers = Current5TracksAlbumArtNotifier.calculateCovers(
        playlist,
        PlaylistMode.none,
      );

      expect(covers, equals(['/art3.jpg', '/art4.jpg', '/art5.jpg', '/art6.jpg', '/art7.jpg']));
    });

    test('stops at end of playlist when loop is none', () {
      final medias = List.generate(3, (i) => createMedia(i + 1, '/art${i + 1}.jpg'));
      final playlist = Playlist(medias, index: 1);

      final covers = Current5TracksAlbumArtNotifier.calculateCovers(
        playlist,
        PlaylistMode.none,
      );

      expect(covers, equals(['/art2.jpg', '/art3.jpg']));
    });

    test('wraps around to start when loop is PlaylistMode.loop', () {
      final medias = List.generate(3, (i) => createMedia(i + 1, '/art${i + 1}.jpg'));
      final playlist = Playlist(medias, index: 1);

      final covers = Current5TracksAlbumArtNotifier.calculateCovers(
        playlist,
        PlaylistMode.loop,
      );

      // index 1, index 2, wrap to index 0
      expect(covers, equals(['/art2.jpg', '/art3.jpg', '/art1.jpg']));
    });

    test('handles null or empty albumArtPath gracefully by emitting empty string', () {
      final medias = [
        createMedia(1, null),
        createMedia(2, ''),
        createMedia(3, '/art3.jpg'),
      ];
      final playlist = Playlist(medias, index: 0);

      final covers = Current5TracksAlbumArtNotifier.calculateCovers(
        playlist,
        PlaylistMode.none,
      );

      expect(covers, equals(['', '', '/art3.jpg']));
    });
  });
}
