import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nordplayer/core/system/config_service.dart';
import 'package:nordplayer/data/repositories/artist_repository.dart';
import 'package:nordplayer/data/repositories/config_repository.dart';
import 'package:nordplayer/domain/models/models.dart';
import 'package:nordplayer/features/artists/artists_ui_state.dart';
import 'package:nordplayer/features/artists/artists_viewmodel.dart';

class FakeArtistRepository implements ArtistRepository {
  final StreamController<List<Artist>> _artistsController = StreamController<List<Artist>>.broadcast();

  void emitArtists(List<Artist> artists) {
    _artistsController.add(artists);
  }

  void emitError(Object error) {
    _artistsController.addError(error);
  }

  @override
  Stream<List<Artist>> watchArtists() => _artistsController.stream;

  void dispose() {
    _artistsController.close();
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
  group('ArtistsViewModel & ArtistsUiState', () {
    late FakeArtistRepository fakeArtistRepo;
    late FakeConfigRepository fakeConfigRepo;
    late ProviderContainer container;

    setUp(() {
      fakeArtistRepo = FakeArtistRepository();
      fakeConfigRepo = FakeConfigRepository();
      container = ProviderContainer(
        overrides: [
          artistRepositoryProvider.overrideWithValue(fakeArtistRepo),
          configRepositoryProvider.overrideWithValue(fakeConfigRepo),
        ],
      );
    });

    tearDown(() {
      container.dispose();
      fakeArtistRepo.dispose();
      fakeConfigRepo.dispose();
    });

    test('initial state has isLoading true and receives stream updates', () async {
      final sub = container.listen(artistsViewModelProvider, (_, _) {});
      addTearDown(sub.close);

      final initialState = container.read(artistsViewModelProvider);
      expect(initialState.isLoading, isTrue);
      expect(initialState.artists, isEmpty);
      expect(initialState.errorMessage, isNull);

      final testArtists = [const Artist(id: 1, name: 'Artist One'), const Artist(id: 2, name: 'Artist Two')];

      fakeArtistRepo.emitArtists(testArtists);
      await pumpEventQueue();

      final updatedState = container.read(artistsViewModelProvider);
      expect(updatedState.isLoading, isFalse);
      expect(updatedState.artists, equals(testArtists));
      expect(updatedState.isEmpty, isFalse);
      expect(updatedState.errorMessage, isNull);
    });

    test('handles stream error properly', () async {
      final sub = container.listen(artistsViewModelProvider, (_, _) {});
      addTearDown(sub.close);

      fakeArtistRepo.emitError('Artist load failed');
      await pumpEventQueue();

      final state = container.read(artistsViewModelProvider);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, contains('Artist load failed'));
    });

    test('updates adaptive background tokens when config changes', () async {
      final sub = container.listen(artistsViewModelProvider, (_, _) {});
      addTearDown(sub.close);

      expect(container.read(artistsViewModelProvider).isAdaptiveBg, isFalse);

      fakeConfigRepo.updateConfig(AppConfig(adaptiveBg: true, adaptiveBgPanelBlur: 15.0, adaptiveBgThemeOverlay: 0.8));
      await pumpEventQueue();

      final state = container.read(artistsViewModelProvider);
      expect(state.isAdaptiveBg, isTrue);
      expect(state.adaptiveBgPanelBlur, equals(15.0));
      expect(state.adaptiveBgThemeOverlay, equals(0.8));
    });

    test('ArtistsUiState copyWith and equality work correctly', () {
      const state1 = ArtistsUiState(artists: [Artist(id: 1, name: 'A')], isLoading: false, isAdaptiveBg: true);
      final state2 = state1.copyWith(isAdaptiveBg: false);

      expect(state1 == state2, isFalse);
      expect(state2.isAdaptiveBg, isFalse);
      expect(state2.artists.length, equals(1));
      expect(state1.hashCode != state2.hashCode, isTrue);
    });
  });
}
