import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nordplayer/config/app_config.dart';
import 'package:nordplayer/data/repositories/album_repository.dart';
import 'package:nordplayer/data/repositories/config_repository.dart';
import 'package:nordplayer/data/repositories/track_repository.dart';
import 'package:nordplayer/data/services/audio/playback_controller.dart';
import 'package:nordplayer/domain/models/composite_models.dart';
import 'package:nordplayer/domain/models/library_stats.dart';
import 'package:nordplayer/ui/library/library_viewmodel.dart';

import '../../../testing/fakes/fake_album_repository.dart';
import '../../../testing/fakes/fake_playback_controller.dart';
import '../../../testing/fakes/fake_track_repository.dart';

void main() {
  group('LibraryViewModel', () {
    late ProviderContainer container;
    late FakePlaybackController fakePlaybackController;
    late FakeTrackRepository fakeTrackRepo;
    late FakeAlbumRepository fakeAlbumRepo;

    setUp(() {
      fakePlaybackController = FakePlaybackController();
      fakeTrackRepo = FakeTrackRepository(
        initialStats: const LibraryStats(
          trackCount: 42,
          albumCount: 10,
          artistCount: 8,
          playlistCount: 2,
          genreCount: 3,
          totalSizeBytes: 1000000,
          totalPlaytimeMs: 500000,
        ),
      );
      fakeAlbumRepo = FakeAlbumRepository();

      final initialSections = [
        const LibrarySectionConfig(id: 'recently_added', isVisible: true),
        const LibrarySectionConfig(id: 'albums', isVisible: true),
        const LibrarySectionConfig(id: 'tracks', isVisible: false),
      ];

      container = ProviderContainer(
        overrides: [
          initialAppConfigProvider.overrideWithValue(AppConfig(librarySections: initialSections)),
          playbackControllerProvider.overrideWithValue(fakePlaybackController),
          trackRepositoryProvider.overrideWithValue(fakeTrackRepo),
          albumRepositoryProvider.overrideWithValue(fakeAlbumRepo),
        ],
      );
    });

    tearDown(() {
      container.dispose();
      fakePlaybackController.dispose();
      fakeTrackRepo.dispose();
      fakeAlbumRepo.dispose();
    });

    test('reorderSections moves section to target index', () {
      final vm = container.read(libraryViewModelProvider.notifier);
      vm.reorderSections(0, 2);

      final sections = container.read(libraryViewModelProvider).sections;
      expect(sections.map((s) => s.id).toList(), equals(['albums', 'tracks', 'recently_added']));
    });

    test('toggleSectionVisibility flips boolean visibility', () {
      final vm = container.read(libraryViewModelProvider.notifier);

      // 'tracks' was false, now true
      vm.toggleSectionVisibility('tracks');
      var sections = container.read(libraryViewModelProvider).sections;
      expect(sections.firstWhere((s) => s.id == 'tracks').isVisible, isTrue);

      // Flip back to false
      vm.toggleSectionVisibility('tracks');
      sections = container.read(libraryViewModelProvider).sections;
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

    test('playTrack delegates to PlaybackController', () {
      final vm = container.read(libraryViewModelProvider.notifier);
      final tracks = <TrackWithArtists>[];

      vm.playTrack(tracksToPlay: tracks, index: 0, playbackContextType: 'recently_added');

      expect(fakePlaybackController.lastContextType, equals('recently_added'));
      expect(fakePlaybackController.lastInitialIndex, equals(0));
    });
  });
}
