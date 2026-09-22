import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nordplayer/core/system/config_service.dart';
import 'package:nordplayer/data/repositories/album_repository.dart';
import 'package:nordplayer/data/repositories/config_repository.dart';
import 'package:nordplayer/domain/models/models.dart';
import 'package:nordplayer/features/albums/albums_ui_state.dart';
import 'package:nordplayer/features/albums/albums_viewmodel.dart';

class FakeAlbumRepository implements AlbumRepository {
  final StreamController<List<Album>> _albumsController = StreamController<List<Album>>.broadcast();
  List<Artist> trackArtistsToReturn = const [];

  void emitAlbums(List<Album> albums) {
    _albumsController.add(albums);
  }

  void emitError(Object error) {
    _albumsController.addError(error);
  }

  @override
  Stream<List<Album>> watchAlbums() => _albumsController.stream;

  @override
  Stream<AlbumWithTracks?> watchAlbumWithTracks(int albumId) => Stream.value(null);

  @override
  Future<List<Artist>> getTrackArtists({required int albumId}) async => trackArtistsToReturn;

  @override
  Future<List<Album>> getRandomAlbums({int limitAmount = 10}) async => const [];

  void dispose() {
    _albumsController.close();
  }
}

class FakeConfigRepository implements ConfigRepository {
  final StreamController<AppConfig> _configController = StreamController<AppConfig>.broadcast();
  AppConfig _config = AppConfig(adaptiveBg: false);

  @override
  AppConfig get currentConfig => _config;

  @override
  Stream<AppConfig> watchConfig() => _configController.stream;

  @override
  void updateConfig(AppConfig newConfig) {
    _config = newConfig;
    _configController.add(newConfig);
  }

  @override
  Future<void> flush() async {}

  void dispose() {
    _configController.close();
  }
}

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
