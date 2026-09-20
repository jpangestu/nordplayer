import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nordplayer/core/database/app_database.dart';
import 'package:nordplayer/data/repositories/playlist_repository.dart';
import 'package:nordplayer/features/playlists/playlists_viewmodel.dart';
import 'package:nordplayer/services/audio/player_service.dart';

class FakePlaylistRepository implements PlaylistRepository {
  final List<String> createdNames = [];
  final List<List<int>?> createdTrackIds = [];
  final Map<int, String> renamedPlaylists = {};
  final List<int> deletedPlaylists = [];
  final Map<int, List<int>> addedTracks = {};
  final List<(int, int)> removedTracks = [];

  @override
  Future<int> createPlaylist(String name, {List<int>? trackIds}) async {
    createdNames.add(name);
    createdTrackIds.add(trackIds);
    return 101;
  }

  @override
  Future<void> renamePlaylist(int playlistId, String newName) async {
    renamedPlaylists[playlistId] = newName;
  }

  @override
  Future<void> deletePlaylist(int playlistId) async {
    deletedPlaylists.add(playlistId);
  }

  @override
  Future<void> addTracksToPlaylist(int playlistId, List<int> trackIds) async {
    addedTracks[playlistId] = trackIds;
  }

  @override
  Future<void> removeTrackFromPlaylist(int playlistId, int trackId) async {
    removedTracks.add((playlistId, trackId));
  }

  List<TrackWithArtists> playlistTracks = const [];

  @override
  Future<List<TrackWithArtists>> getPlaylistTracks(int playlistId) async => playlistTracks;

  @override
  Stream<List<PlaylistWithDetails>> watchAllPlaylists() => Stream.value(const []);

  @override
  Stream<PlaylistData> watchPlaylist(int playlistId) => const Stream.empty();

  @override
  Stream<List<TrackWithArtists>> watchPlaylistTracks(int playlistId) => Stream.value(const []);
}

class FakePlayerServiceForPlaylist extends Fake implements PlayerService {
  List<TrackWithArtists> setPlaylistTracks = [];
  int setPlaylistIndex = -1;
  String setPlaylistContextType = '';
  int? setPlaylistContextId;
  List<TrackWithArtists> addedToQueueTracks = [];

  @override
  Future<void> setPlaylist({
    required List<TrackWithArtists> tracksToPlay,
    required int initialIndex,
    required String playbackContextType,
    int? playbackContextId,
    bool forceReload = false,
    bool autoplay = true,
  }) async {
    setPlaylistTracks = tracksToPlay;
    setPlaylistIndex = initialIndex;
    setPlaylistContextType = playbackContextType;
    setPlaylistContextId = playbackContextId;
  }

  @override
  Future<void> addToQueue(
    List<TrackWithArtists> tracks,
    String playbackContextType,
    int? playbackContextId,
  ) async {
    addedToQueueTracks = tracks;
  }
}

void main() {
  group('PlaylistsViewModel', () {
    late FakePlaylistRepository fakeRepo;
    late FakePlayerServiceForPlaylist fakePlayer;
    late ProviderContainer container;

    setUp(() {
      fakeRepo = FakePlaylistRepository();
      fakePlayer = FakePlayerServiceForPlaylist();
      container = ProviderContainer(
        overrides: [
          playlistRepositoryProvider.overrideWithValue(fakeRepo),
          playerServiceProvider.overrideWithValue(fakePlayer),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('createPlaylist creates playlist with trimmed name and track IDs', () async {
      final vm = container.read(playlistsViewModelProvider);
      final id = await vm.createPlaylist('  My Favorites  ', trackIds: [10, 20]);

      expect(id, equals(101));
      expect(fakeRepo.createdNames, equals(['My Favorites']));
      expect(fakeRepo.createdTrackIds, equals([[10, 20]]));
    });

    test('createPlaylist throws ArgumentError for empty name', () async {
      final vm = container.read(playlistsViewModelProvider);
      expect(() => vm.createPlaylist('   '), throwsArgumentError);
      expect(fakeRepo.createdNames, isEmpty);
    });

    test('renamePlaylist trims name and updates repository', () async {
      final vm = container.read(playlistsViewModelProvider);
      await vm.renamePlaylist(5, '  Updated Name  ');

      expect(fakeRepo.renamedPlaylists[5], equals('Updated Name'));
    });

    test('renamePlaylist throws ArgumentError for empty name', () async {
      final vm = container.read(playlistsViewModelProvider);
      expect(() => vm.renamePlaylist(5, '   '), throwsArgumentError);
      expect(fakeRepo.renamedPlaylists, isEmpty);
    });

    test('deletePlaylist delegates to repository', () async {
      final vm = container.read(playlistsViewModelProvider);
      await vm.deletePlaylist(7);

      expect(fakeRepo.deletedPlaylists, equals([7]));
    });

    test('addTracksToPlaylist delegates to repository', () async {
      final vm = container.read(playlistsViewModelProvider);
      await vm.addTracksToPlaylist(12, [1, 2, 3]);

      expect(fakeRepo.addedTracks[12], equals([1, 2, 3]));
    });

    test('removeTrackFromPlaylist delegates to repository', () async {
      final vm = container.read(playlistsViewModelProvider);
      await vm.removeTrackFromPlaylist(15, 99);

      expect(fakeRepo.removedTracks, equals([(15, 99)]));
    });

    test('playPlaylistById returns false on empty playlist', () async {
      final vm = container.read(playlistsViewModelProvider);
      final result = await vm.playPlaylistById(42);

      expect(result, isFalse);
      expect(fakePlayer.setPlaylistTracks, isEmpty);
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
      final vm = container.read(playlistsViewModelProvider);
      final result = await vm.playPlaylistById(42);

      expect(result, isTrue);
      expect(fakePlayer.setPlaylistTracks.length, equals(1));
      expect(fakePlayer.setPlaylistContextType, equals('playlist'));
      expect(fakePlayer.setPlaylistContextId, equals(42));
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
      final vm = container.read(playlistsViewModelProvider);
      final count = await vm.addPlaylistToQueue(42);

      expect(count, equals(1));
      expect(fakePlayer.addedToQueueTracks.length, equals(1));
    });
  });
}
