import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nordplayer/data/repositories/playback_repository.dart';
import 'package:nordplayer/data/repositories/playlist_repository.dart';
import 'package:nordplayer/domain/models/album.dart';
import 'package:nordplayer/domain/models/composite_models.dart';
import 'package:nordplayer/domain/models/track.dart';
import 'package:nordplayer/ui/playlists/playlist_detail_viewmodel.dart';
import 'package:nordplayer/ui/playlists/playlists_viewmodel.dart';

import '../../../testing/fakes/fake_playback_repository.dart';
import '../../../testing/fakes/fake_playlist_repository.dart';

void main() {
  group('PlaylistsViewModel', () {
    late FakePlaylistRepository fakeRepo;
    late FakePlaybackRepository fakePlayback;
    late ProviderContainer container;

    setUp(() {
      fakeRepo = FakePlaylistRepository();
      fakePlayback = FakePlaybackRepository();
      container = ProviderContainer(
        overrides: [
          playlistRepositoryProvider.overrideWithValue(fakeRepo),
          playbackRepositoryProvider.overrideWithValue(fakePlayback),
        ],
      );
    });

    tearDown(() {
      container.dispose();
      fakeRepo.dispose();
      fakePlayback.dispose();
    });

    test('createPlaylist creates playlist with trimmed name and track IDs', () async {
      final vm = container.read(playlistsViewModelProvider.notifier);
      final id = await vm.createPlaylist('  My Favorites  ', trackIds: [10, 20]);

      expect(id, equals(101));
      expect(fakeRepo.createdNames, equals(['My Favorites']));
      expect(
        fakeRepo.createdTrackIds,
        equals([
          [10, 20],
        ]),
      );
    });

    test('createPlaylist throws ArgumentError for empty name', () async {
      final vm = container.read(playlistsViewModelProvider.notifier);
      expect(() => vm.createPlaylist('   '), throwsArgumentError);
      expect(fakeRepo.createdNames, isEmpty);
    });

    test('renamePlaylist trims name and updates repository', () async {
      final vm = container.read(playlistsViewModelProvider.notifier);
      await vm.renamePlaylist(5, '  Updated Name  ');

      expect(fakeRepo.renamedPlaylists[5], equals('Updated Name'));
    });

    test('renamePlaylist throws ArgumentError for empty name', () async {
      final vm = container.read(playlistsViewModelProvider.notifier);
      expect(() => vm.renamePlaylist(5, '   '), throwsArgumentError);
      expect(fakeRepo.renamedPlaylists, isEmpty);
    });

    test('deletePlaylist delegates to repository', () async {
      final vm = container.read(playlistsViewModelProvider.notifier);
      await vm.deletePlaylist(7);

      expect(fakeRepo.deletedPlaylists, equals([7]));
    });

    test('addTracksToPlaylist delegates to repository', () async {
      final vm = container.read(playlistsViewModelProvider.notifier);
      await vm.addTracksToPlaylist(12, [1, 2, 3]);

      expect(fakeRepo.addedTracks[12], equals([1, 2, 3]));
    });

    test('removeTrackFromPlaylist delegates to repository', () async {
      final vm = container.read(playlistsViewModelProvider.notifier);
      await vm.removeTrackFromPlaylist(15, 99);

      expect(fakeRepo.removedTracks, equals([(15, 99)]));
    });

    test('playPlaylistById returns false on empty playlist', () async {
      final vm = container.read(playlistsViewModelProvider.notifier);
      final result = await vm.playPlaylistById(42);

      expect(result, isFalse);
      expect(fakePlayback.setPlaylistTracks, isEmpty);
    });

    test('playPlaylistById starts playback on non-empty playlist', () async {
      final track = TrackWithArtists(
        track: Track(
          id: 1,
          filePath: '/music/t1.mp3',
          fileSize: 100,
          fileHash: 'h1',
          dateAdded: DateTime.now(),
          title: 'Track 1',
          trackNumber: 1,
          trackTotal: 1,
          discNumber: 1,
          discTotal: 1,
          durationMs: 1000,
          isMissing: false,
          artistId: 1,
          albumId: 1,
        ),
        album: const Album(id: 1, title: 'Alb 1', year: 2026),
        artists: const [],
      );

      fakeRepo.playlistTracks = [track];
      final vm = container.read(playlistsViewModelProvider.notifier);
      final result = await vm.playPlaylistById(42);

      expect(result, isTrue);
      expect(fakePlayback.setPlaylistTracks.length, equals(1));
      expect(fakePlayback.setPlaylistContextType, equals('playlist'));
      expect(fakePlayback.setPlaylistContextId, equals(42));
    });

    test('addPlaylistToQueue returns count and adds tracks to queue', () async {
      final track = TrackWithArtists(
        track: Track(
          id: 2,
          filePath: '/music/t2.mp3',
          fileSize: 100,
          fileHash: 'h2',
          dateAdded: DateTime.now(),
          title: 'Track 2',
          trackNumber: 1,
          trackTotal: 1,
          discNumber: 1,
          discTotal: 1,
          durationMs: 2000,
          isMissing: false,
          artistId: 1,
          albumId: 1,
        ),
        album: const Album(id: 1, title: 'Alb 2', year: 2026),
        artists: const [],
      );

      fakeRepo.playlistTracks = [track];
      final vm = container.read(playlistsViewModelProvider.notifier);
      final count = await vm.addPlaylistToQueue(42);

      expect(count, equals(1));
      expect(fakePlayback.addedToQueueTracks.length, equals(1));
    });
  });

  group('PlaylistDetailViewModel', () {
    late FakePlaylistRepository fakeRepo;
    late FakePlaybackRepository fakePlayback;
    late ProviderContainer container;

    setUp(() {
      fakeRepo = FakePlaylistRepository();
      fakePlayback = FakePlaybackRepository();
      container = ProviderContainer(
        overrides: [
          playlistRepositoryProvider.overrideWithValue(fakeRepo),
          playbackRepositoryProvider.overrideWithValue(fakePlayback),
        ],
      );
    });

    tearDown(() {
      container.dispose();
      fakeRepo.dispose();
      fakePlayback.dispose();
    });

    test('loads playlist metadata and tracks into PlaylistDetailUiState', () async {
      final track = TrackWithArtists(
        track: Track(
          id: 1,
          filePath: '/music/detail.mp3',
          fileSize: 100,
          fileHash: 'h1',
          dateAdded: DateTime.now(),
          title: 'Detail Track',
          trackNumber: 1,
          trackTotal: 1,
          discNumber: 1,
          discTotal: 1,
          durationMs: 3000,
          isMissing: false,
          artistId: 1,
          albumId: 1,
        ),
        album: const Album(id: 1, title: 'Detail Alb', year: 2026, albumArtPath: '/art/1.jpg'),
        artists: const [],
      );

      fakeRepo.playlistTracks = [track];

      final vm = container.read(playlistDetailViewModelProvider(7).notifier);
      // Allow stream subscriptions to deliver events
      await Future<void>.delayed(Duration.zero);

      final state = container.read(playlistDetailViewModelProvider(7));
      expect(state.playlist?.name, equals('Test Playlist'));
      expect(state.tracks.length, equals(1));
      expect(state.albumArtCovers, equals(['/art/1.jpg']));
      expect(state.isLoading, isFalse);

      vm.playTrack(0);
      expect(fakePlayback.setPlaylistTracks.length, equals(1));
      expect(fakePlayback.setPlaylistContextType, equals('playlist'));
      expect(fakePlayback.setPlaylistContextId, equals(7));
    });

    test('toggleColumnVisibility updates column visibility in state', () {
      final vm = container.read(playlistDetailViewModelProvider(7).notifier);
      final initialCols = container.read(playlistDetailViewModelProvider(7)).columns;
      final albumCol = initialCols.firstWhere((c) => c.id == 'album');
      expect(albumCol.isVisible, isTrue);

      vm.toggleColumnVisibility('album');

      final updatedCols = container.read(playlistDetailViewModelProvider(7)).columns;
      final updatedAlbumCol = updatedCols.firstWhere((c) => c.id == 'album');
      expect(updatedAlbumCol.isVisible, isFalse);
    });
  });
}
