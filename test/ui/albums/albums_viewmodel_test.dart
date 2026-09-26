import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nordplayer/config/app_config.dart';
import 'package:nordplayer/data/repositories/album_repository.dart';
import 'package:nordplayer/data/repositories/config_repository.dart';
import 'package:nordplayer/domain/models/album.dart';
import 'package:nordplayer/domain/models/artist.dart';
import 'package:nordplayer/ui/albums/albums_ui_state.dart';
import 'package:nordplayer/ui/albums/albums_viewmodel.dart';

import '../../../testing/fakes/fake_album_repository.dart';
import '../../../testing/fakes/fake_config_repository.dart';

void main() {
  group('AlbumsViewModel & AlbumsUiState', () {
    late FakeAlbumRepository fakeAlbumRepo;
    late FakeConfigRepository fakeConfigRepo;
    late ProviderContainer container;

    setUp(() {
      fakeAlbumRepo = FakeAlbumRepository();
      fakeConfigRepo = FakeConfigRepository();
      container = ProviderContainer(
        overrides: [
          albumRepositoryProvider.overrideWithValue(fakeAlbumRepo),
          configRepositoryProvider.overrideWithValue(fakeConfigRepo),
        ],
      );
    });

    tearDown(() {
      container.dispose();
      fakeAlbumRepo.dispose();
      fakeConfigRepo.dispose();
    });

    test('initial state has isLoading true and receives stream updates', () async {
      final sub = container.listen(albumsViewModelProvider, (_, _) {});
      addTearDown(sub.close);

      final initialState = container.read(albumsViewModelProvider);
      expect(initialState.isLoading, isTrue);
      expect(initialState.albums, isEmpty);
      expect(initialState.errorMessage, isNull);

      final testAlbums = [
        const Album(id: 1, title: 'Album One', albumArtist: 'Artist A'),
        const Album(id: 2, title: 'Album Two', albumArtist: 'Artist B'),
      ];

      fakeAlbumRepo.emitAlbums(testAlbums);
      await pumpEventQueue();

      final updatedState = container.read(albumsViewModelProvider);
      expect(updatedState.isLoading, isFalse);
      expect(updatedState.albums, equals(testAlbums));
      expect(updatedState.isEmpty, isFalse);
      expect(updatedState.errorMessage, isNull);
    });

    test('handles stream error properly', () async {
      final sub = container.listen(albumsViewModelProvider, (_, _) {});
      addTearDown(sub.close);

      fakeAlbumRepo.emitError('Database failure');
      await pumpEventQueue();

      final state = container.read(albumsViewModelProvider);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, contains('Database failure'));
    });

    test('updates adaptive background tokens when config changes', () async {
      final sub = container.listen(albumsViewModelProvider, (_, _) {});
      addTearDown(sub.close);

      expect(container.read(albumsViewModelProvider).isAdaptiveBg, isFalse);

      fakeConfigRepo.updateConfig(AppConfig(adaptiveBg: true, adaptiveBgPanelBlur: 15.0, adaptiveBgThemeOverlay: 0.8));
      await pumpEventQueue();

      final state = container.read(albumsViewModelProvider);
      expect(state.isAdaptiveBg, isTrue);
      expect(state.adaptiveBgPanelBlur, equals(15.0));
      expect(state.adaptiveBgThemeOverlay, equals(0.8));
    });

    test('getAlbumArtists delegates to AlbumRepository', () async {
      const albumId = 42;
      final expectedArtists = [const Artist(id: 1, name: 'Guest Artist')];
      fakeAlbumRepo.trackArtistsToReturn = expectedArtists;

      final vm = container.read(albumsViewModelProvider.notifier);
      final artists = await vm.getAlbumArtists(albumId);

      expect(artists, equals(expectedArtists));
    });

    test('AlbumsUiState copyWith and equality work correctly', () {
      const state1 = AlbumsUiState(albums: [Album(id: 1, title: 'A')], isLoading: false, isAdaptiveBg: true);
      final state2 = state1.copyWith(isAdaptiveBg: false);

      expect(state1 == state2, isFalse);
      expect(state2.isAdaptiveBg, isFalse);
      expect(state2.albums.length, equals(1));
      expect(state1.hashCode != state2.hashCode, isTrue);
    });
  });
}
