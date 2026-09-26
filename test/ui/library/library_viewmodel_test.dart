import 'package:nordplayer/config/app_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nordplayer/data/services/system/config_service.dart';
import 'package:nordplayer/data/repositories/album_repository.dart';
import 'package:nordplayer/data/repositories/playback_repository.dart';
import 'package:nordplayer/data/repositories/track_repository.dart';
import 'package:nordplayer/domain/models/composite_models.dart';
import 'package:nordplayer/domain/models/album.dart';
import 'package:nordplayer/domain/models/library_stats.dart';
import 'package:nordplayer/ui/library/library_viewmodel.dart';

class FakePlaybackRepositoryForLibrary extends Fake implements PlaybackRepository {
  List<TrackWithArtists> lastTracks = [];
  int lastInitialIndex = -1;
  String lastContextType = '';

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
  }
}

class FakeTrackRepositoryForLibrary extends Fake implements TrackRepository {
  @override
  Stream<LibraryStats> watchLibraryStats() => Stream.value(
        const LibraryStats(
          trackCount: 42,
          albumCount: 10,
          artistCount: 8,
          playlistCount: 2,
          genreCount: 3,
          totalSizeBytes: 1000000,
          totalPlaytimeMs: 500000,
        ),
      );

  @override
  Stream<List<TrackWithArtists>> watchRecentlyAddedTracks({int limitAmount = 10}) =>
      Stream.value(const []);

  @override
  Stream<List<TrackWithArtists>> watchAllTracks() => Stream.value(const []);
}

class FakeAlbumRepositoryForLibrary extends Fake implements AlbumRepository {
  @override
  Future<List<Album>> getRandomAlbums({int limitAmount = 10}) async => const [];
}

void main() {
  group('LibraryViewModel', () {
    late ProviderContainer container;
    late FakePlaybackRepositoryForLibrary fakePlaybackRepo;
    late FakeTrackRepositoryForLibrary fakeTrackRepo;
    late FakeAlbumRepositoryForLibrary fakeAlbumRepo;

    setUp(() {
      fakePlaybackRepo = FakePlaybackRepositoryForLibrary();
      fakeTrackRepo = FakeTrackRepositoryForLibrary();
      fakeAlbumRepo = FakeAlbumRepositoryForLibrary();

      final initialSections = [
        const LibrarySectionConfig(id: 'recently_added', isVisible: true),
        const LibrarySectionConfig(id: 'albums', isVisible: true),
        const LibrarySectionConfig(id: 'tracks', isVisible: false),
      ];

      container = ProviderContainer(
        overrides: [
          initialAppConfigProvider.overrideWithValue(
            AppConfig(librarySections: initialSections),
          ),
          playbackRepositoryProvider.overrideWithValue(fakePlaybackRepo),
          trackRepositoryProvider.overrideWithValue(fakeTrackRepo),
          albumRepositoryProvider.overrideWithValue(fakeAlbumRepo),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('reorderSections moves section to target index', () {
      final vm = container.read(libraryViewModelProvider.notifier);
      vm.reorderSections(0, 2);

      final sections = container.read(librarySectionsProvider);
      expect(sections.map((s) => s.id).toList(), equals(['albums', 'tracks', 'recently_added']));
    });

    test('toggleSectionVisibility flips boolean visibility', () {
      final vm = container.read(libraryViewModelProvider.notifier);

      // 'tracks' was false, now true
      vm.toggleSectionVisibility('tracks');
      var sections = container.read(librarySectionsProvider);
      expect(sections.firstWhere((s) => s.id == 'tracks').isVisible, isTrue);

      // Flip back to false
      vm.toggleSectionVisibility('tracks');
      sections = container.read(librarySectionsProvider);
      expect(sections.firstWhere((s) => s.id == 'tracks').isVisible, isFalse);
    });

    test('toggleRecentlyAddedExpanded toggles state', () {
      final vm = container.read(libraryViewModelProvider.notifier);
      expect(container.read(libraryViewModelProvider).isRecentlyAddedExpanded, isFalse);

      vm.toggleRecentlyAddedExpanded();
      expect(container.read(libraryViewModelProvider).isRecentlyAddedExpanded, isTrue);

      vm.toggleRecentlyAddedExpanded();
      expect(container.read(libraryViewModelProvider).isRecentlyAddedExpanded, isFalse);
    });

    test('playTrack delegates to PlaybackRepository', () {
      final vm = container.read(libraryViewModelProvider.notifier);
      final tracks = <TrackWithArtists>[];

      vm.playTrack(
        tracksToPlay: tracks,
        index: 0,
        playbackContextType: 'recently_added',
      );

      expect(fakePlaybackRepo.lastContextType, equals('recently_added'));
      expect(fakePlaybackRepo.lastInitialIndex, equals(0));
    });
  });
}
