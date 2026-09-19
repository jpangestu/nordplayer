import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nordplayer/core/database/app_database.dart';
import 'package:nordplayer/data/repositories/repositories.dart';
import 'package:nordplayer/features/albums/viewmodels/album_detail_viewmodel.dart';

void main() {
  group('AlbumDetailViewModel & State', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('albumTrackSortProvider defaults to trackNumber and updates correctly', () {
      expect(container.read(albumTrackSortProvider), equals(AlbumTrackSort.trackNumber));

      container.read(albumTrackSortProvider.notifier).setSort(AlbumTrackSort.title);
      expect(container.read(albumTrackSortProvider), equals(AlbumTrackSort.title));

      container.read(albumTrackSortProvider.notifier).setSort(AlbumTrackSort.duration);
      expect(container.read(albumTrackSortProvider), equals(AlbumTrackSort.duration));
    });

    test('albumTrackSortOrderProvider defaults to ascending and updates correctly', () {
      expect(container.read(albumTrackSortOrderProvider), equals(SortOrder.ascending));

      container.read(albumTrackSortOrderProvider.notifier).setOrder(SortOrder.descending);
      expect(container.read(albumTrackSortOrderProvider), equals(SortOrder.descending));
    });

    test('albumShowFavoritesOnlyProvider toggles boolean flag', () {
      expect(container.read(albumShowFavoritesOnlyProvider), isFalse);

      container.read(albumShowFavoritesOnlyProvider.notifier).toggle();
      expect(container.read(albumShowFavoritesOnlyProvider), isTrue);

      container.read(albumShowFavoritesOnlyProvider.notifier).toggle();
      expect(container.read(albumShowFavoritesOnlyProvider), isFalse);
    });

    test('albumDetailPageTableColumnsProvider toggles column visibility', () {
      final columns = container.read(albumDetailPageTableColumnsProvider);
      final durationCol = columns.firstWhere((c) => c.id == 'duration');
      expect(durationCol.isVisible, isTrue);

      container.read(albumDetailPageTableColumnsProvider.notifier).toggleVisibility('duration');
      final updatedColumns = container.read(albumDetailPageTableColumnsProvider);
      final updatedDurationCol = updatedColumns.firstWhere((c) => c.id == 'duration');
      expect(updatedDurationCol.isVisible, isFalse);
    });

    test('sortedAlbumWithTracksProvider sorts by trackNumber, title, and duration', () async {
      const albumId = 42;
      final album = const Album(
        id: albumId,
        title: 'Test Album',
        albumArtist: 'Test Artist',
        year: 2026,
      );

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

      final testContainer = ProviderContainer(
        overrides: [
          albumWithTracksProvider(albumId).overrideWith(
            (ref) => Stream.value(
              AlbumWithTracks(album: album, tracks: [trackA, trackB, trackC], tracksLengthMs: 420000),
            ),
          ),
        ],
      );
      addTearDown(testContainer.dispose);

      testContainer.listen(sortedAlbumWithTracksProvider(albumId), (_, _) {});
      await pumpEventQueue();

      // Default: trackNumber, ascending -> B (1), A (2), C (3)
      final initialSorted = testContainer.read(sortedAlbumWithTracksProvider(albumId));
      expect(initialSorted.value?.tracks.map((t) => t.track.title).toList(), equals(['Apple', 'Zebra', 'Mango']));

      // Sort by trackNumber, descending -> C (3), A (2), B (1)
      testContainer.read(albumTrackSortOrderProvider.notifier).setOrder(SortOrder.descending);
      final descSorted = testContainer.read(sortedAlbumWithTracksProvider(albumId));
      expect(descSorted.value?.tracks.map((t) => t.track.title).toList(), equals(['Mango', 'Zebra', 'Apple']));

      // Sort by title, ascending -> Apple, Mango, Zebra
      testContainer.read(albumTrackSortOrderProvider.notifier).setOrder(SortOrder.ascending);
      testContainer.read(albumTrackSortProvider.notifier).setSort(AlbumTrackSort.title);
      final titleSorted = testContainer.read(sortedAlbumWithTracksProvider(albumId));
      expect(titleSorted.value?.tracks.map((t) => t.track.title).toList(), equals(['Apple', 'Mango', 'Zebra']));

      // Sort by duration, ascending -> C (60s), A (120s), B (240s)
      testContainer.read(albumTrackSortProvider.notifier).setSort(AlbumTrackSort.duration);
      final durationSorted = testContainer.read(sortedAlbumWithTracksProvider(albumId));
      expect(durationSorted.value?.tracks.map((t) => t.track.title).toList(), equals(['Mango', 'Zebra', 'Apple']));
    });
  });
}
