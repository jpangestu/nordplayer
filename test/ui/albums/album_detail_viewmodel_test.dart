import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nordplayer/data/repositories/album_repository.dart';
import 'package:nordplayer/data/repositories/config_repository.dart';
import 'package:nordplayer/data/repositories/playback_repository.dart';
import 'package:nordplayer/data/repositories/settings_repository.dart';
import 'package:nordplayer/domain/models/album.dart';
import 'package:nordplayer/domain/models/composite_models.dart';
import 'package:nordplayer/domain/models/track.dart';
import 'package:nordplayer/ui/albums/album_detail_ui_state.dart';
import 'package:nordplayer/ui/albums/album_detail_viewmodel.dart';

import '../../../testing/fakes/fake_album_repository.dart';
import '../../../testing/fakes/fake_config_repository.dart';
import '../../../testing/fakes/fake_playback_repository.dart';
import '../../../testing/fakes/fake_settings_repository.dart';

void main() {
  group('AlbumDetailViewModel & AlbumDetailUiState', () {
    const albumId = 42;
    final album = const Album(id: albumId, title: 'Test Album', albumArtist: 'Test Artist', year: 2026);

    final trackA = TrackWithArtists(
      track: Track(
        id: 1,
        filePath: '/music/track_a.mp3',
        fileSize: 1000,
        fileHash: 'hash_1',
        dateAdded: DateTime.now(),
        title: 'Zebra',
        trackNumber: 2,
        trackTotal: 3,
        discNumber: 1,
        discTotal: 1,
        durationMs: 120000,
        isMissing: false,
        artistId: 1,
        albumId: albumId,
      ),
      album: album,
      artists: const [],
    );

    final trackB = TrackWithArtists(
      track: Track(
        id: 2,
        filePath: '/music/track_b.mp3',
        fileSize: 1000,
        fileHash: 'hash_2',
        dateAdded: DateTime.now(),
        title: 'Apple',
        trackNumber: 1,
        trackTotal: 3,
        discNumber: 1,
        discTotal: 1,
        durationMs: 240000,
        isMissing: false,
        artistId: 1,
        albumId: albumId,
      ),
      album: album,
      artists: const [],
    );

    final trackC = TrackWithArtists(
      track: Track(
        id: 3,
        filePath: '/music/track_c.mp3',
        fileSize: 1000,
        fileHash: 'hash_3',
        dateAdded: DateTime.now(),
        title: 'Mango',
        trackNumber: 3,
        trackTotal: 3,
        discNumber: 1,
        discTotal: 1,
        durationMs: 60000,
        isMissing: false,
        artistId: 1,
        albumId: albumId,
      ),
      album: album,
      artists: const [],
    );

    late FakeAlbumRepository fakeAlbumRepo;
    late FakePlaybackRepository fakePlaybackRepo;
    late FakeSettingsRepository fakeSettingsRepo;
    late FakeConfigRepository fakeConfigRepo;
    late ProviderContainer container;

    setUp(() {
      fakeAlbumRepo = FakeAlbumRepository();
      fakePlaybackRepo = FakePlaybackRepository();
      fakeSettingsRepo = FakeSettingsRepository();
      fakeConfigRepo = FakeConfigRepository();

      container = ProviderContainer(
        overrides: [
          albumRepositoryProvider.overrideWithValue(fakeAlbumRepo),
          playbackRepositoryProvider.overrideWithValue(fakePlaybackRepo),
          settingsRepositoryProvider.overrideWithValue(fakeSettingsRepo),
          configRepositoryProvider.overrideWithValue(fakeConfigRepo),
        ],
      );
    });

    tearDown(() {
      container.dispose();
      fakeAlbumRepo.dispose();
      fakePlaybackRepo.dispose();
      fakeSettingsRepo.dispose();
      fakeConfigRepo.dispose();
    });

    test('initial state and receiving album tracks from repository', () async {
      final sub = container.listen(albumDetailViewModelProvider(albumId), (_, _) {});
      addTearDown(sub.close);

      final initial = container.read(albumDetailViewModelProvider(albumId));
      expect(initial.isLoading, isTrue);
      expect(initial.albumWithTracks, isNull);

      final rawData = AlbumWithTracks(album: album, tracks: [trackA, trackB, trackC], tracksLengthMs: 420000);

      fakeAlbumRepo.emitAlbum(rawData);
      await pumpEventQueue();

      final updated = container.read(albumDetailViewModelProvider(albumId));
      expect(updated.isLoading, isFalse);
      expect(updated.albumWithTracks, isNotNull);
      // Default: sort by trackNumber ascending -> Apple (1), Zebra (2), Mango (3)
      expect(
        updated.albumWithTracks?.tracks.map((t) => t.track.title).toList(),
        equals(['Apple', 'Zebra', 'Mango']),
      );
      expect(updated.trackCount, equals(3));
      expect(updated.totalDurationMs, equals(420000));
      expect(updated.isEmpty, isFalse);
    });

    test('sorts by trackNumber, title, and duration in ascending and descending orders', () async {
      final sub = container.listen(albumDetailViewModelProvider(albumId), (_, _) {});
      addTearDown(sub.close);

      fakeAlbumRepo.emitAlbum(
        AlbumWithTracks(album: album, tracks: [trackA, trackB, trackC], tracksLengthMs: 420000),
      );
      await pumpEventQueue();

      final vm = container.read(albumDetailViewModelProvider(albumId).notifier);

      // Sort by trackNumber, descending -> Mango (3), Zebra (2), Apple (1)
      vm.setOrder(SortOrder.descending);
      var state = container.read(albumDetailViewModelProvider(albumId));
      expect(state.sortOrder, equals(SortOrder.descending));
      expect(
        state.albumWithTracks?.tracks.map((t) => t.track.title).toList(),
        equals(['Mango', 'Zebra', 'Apple']),
      );

      // Sort by title, ascending -> Apple, Mango, Zebra
      vm.setOrder(SortOrder.ascending);
      vm.setSort(AlbumTrackSort.title);
      state = container.read(albumDetailViewModelProvider(albumId));
      expect(state.sortCriteria, equals(AlbumTrackSort.title));
      expect(
        state.albumWithTracks?.tracks.map((t) => t.track.title).toList(),
        equals(['Apple', 'Mango', 'Zebra']),
      );

      // Sort by duration, ascending -> Mango (60s), Zebra (120s), Apple (240s)
      vm.setSort(AlbumTrackSort.duration);
      state = container.read(albumDetailViewModelProvider(albumId));
      expect(state.sortCriteria, equals(AlbumTrackSort.duration));
      expect(
        state.albumWithTracks?.tracks.map((t) => t.track.title).toList(),
        equals(['Mango', 'Zebra', 'Apple']),
      );
    });

    test('toggles favorites-only filter', () async {
      final sub = container.listen(albumDetailViewModelProvider(albumId), (_, _) {});
      addTearDown(sub.close);

      final vm = container.read(albumDetailViewModelProvider(albumId).notifier);
      expect(container.read(albumDetailViewModelProvider(albumId)).showFavoritesOnly, isFalse);

      vm.toggleFavoritesOnly();
      expect(container.read(albumDetailViewModelProvider(albumId)).showFavoritesOnly, isTrue);

      vm.toggleFavoritesOnly();
      expect(container.read(albumDetailViewModelProvider(albumId)).showFavoritesOnly, isFalse);
    });

    test('toggles column visibility', () async {
      final sub = container.listen(albumDetailViewModelProvider(albumId), (_, _) {});
      addTearDown(sub.close);

      final vm = container.read(albumDetailViewModelProvider(albumId).notifier);
      final initialCols = container.read(albumDetailViewModelProvider(albumId)).columns;
      final durationCol = initialCols.firstWhere((c) => c.id == 'duration');
      expect(durationCol.isVisible, isTrue);

      vm.toggleColumnVisibility('duration');
      final updatedCols = container.read(albumDetailViewModelProvider(albumId)).columns;
      expect(updatedCols.firstWhere((c) => c.id == 'duration').isVisible, isFalse);
    });

    test('toggles shuffle mode and synchronizes with SettingsRepository', () async {
      final sub = container.listen(albumDetailViewModelProvider(albumId), (_, _) {});
      addTearDown(sub.close);

      final vm = container.read(albumDetailViewModelProvider(albumId).notifier);
      expect(container.read(albumDetailViewModelProvider(albumId)).shouldShuffle, isFalse);

      vm.toggleShuffle();
      await pumpEventQueue();

      expect(container.read(albumDetailViewModelProvider(albumId)).shouldShuffle, isTrue);
      expect(fakeSettingsRepo.currentSettings.shuffleMode, isTrue);
    });

    test('playAlbum dispatches to PlaybackRepository', () async {
      final sub = container.listen(albumDetailViewModelProvider(albumId), (_, _) {});
      addTearDown(sub.close);

      fakeAlbumRepo.emitAlbum(
        AlbumWithTracks(album: album, tracks: [trackA, trackB, trackC], tracksLengthMs: 420000),
      );
      await pumpEventQueue();

      final vm = container.read(albumDetailViewModelProvider(albumId).notifier);
      vm.playAlbum(initialIndex: 1, shouldShuffle: false);

      expect(fakePlaybackRepo.setPlaylistContextType, equals('album'));
      expect(fakePlaybackRepo.setPlaylistContextId, equals(albumId));
      expect(fakePlaybackRepo.setPlaylistIndex, equals(1));
      expect(fakePlaybackRepo.setPlaylistTracks.length, equals(3));
    });

    test('backward-compatible sortedAlbumWithTracksProvider works as expected', () async {
      final sub = container.listen(sortedAlbumWithTracksProvider(albumId), (_, _) {});
      addTearDown(sub.close);

      expect(container.read(sortedAlbumWithTracksProvider(albumId)).isLoading, isTrue);

      fakeAlbumRepo.emitAlbum(
        AlbumWithTracks(album: album, tracks: [trackA, trackB], tracksLengthMs: 360000),
      );
      await pumpEventQueue();

      final result = container.read(sortedAlbumWithTracksProvider(albumId));
      expect(result.value?.tracks.length, equals(2));
    });
  });
}
