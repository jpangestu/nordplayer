import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nordplayer/domain/models/album.dart';
import 'package:nordplayer/domain/models/artist.dart';
import 'package:nordplayer/domain/models/composite_models.dart';
import 'package:nordplayer/domain/models/library_stats.dart';
import 'package:nordplayer/domain/models/track.dart';
import 'package:nordplayer/ui/library/library_view.dart';

import '../../../testing/app.dart';
import '../../../testing/fakes/fake_track_repository.dart';

void main() {
  Finder findRichText(String text) {
    return find.byWidgetPredicate((widget) => widget is RichText && widget.text.toPlainText().contains(text));
  }

  TrackWithArtists createTrack(int id, String title, String artistName) {
    final track = Track(
      id: id,
      title: title,
      trackNumber: 1,
      trackTotal: 1,
      discNumber: 1,
      discTotal: 1,
      durationMs: 200000,
      fileHash: 'hash_$id',
      isMissing: false,
      filePath: '/music/$title.mp3',
      fileSize: 3000000,
      artistId: 1,
      albumId: 1,
      dateAdded: DateTime.now(),
    );
    final artist = Artist(id: 1, name: artistName);
    final album = Album(id: 1, title: 'Album $id', albumArtistId: 1);
    return TrackWithArtists(track: track, album: album, artists: [artist]);
  }

  group('LibraryView Widget Tests', () {
    testWidgets('renders empty state when library has 0 tracks', (tester) async {
      final fakeTrackRepo = FakeTrackRepository(initialTracks: [], initialStats: const LibraryStats.empty());

      await pumpTestApp(tester, child: const LibraryView(), fakeTrackRepo: fakeTrackRepo);

      expect(find.text('Your library is empty'), findsOneWidget);
      expect(find.text('Scan your local folders to set up your music library.'), findsOneWidget);
    });

    testWidgets('renders library header and recently added tracks when data exists', (tester) async {
      final tracks = [createTrack(1, 'Recent Song 1', 'Artist One'), createTrack(2, 'Recent Song 2', 'Artist Two')];
      const stats = LibraryStats(
        trackCount: 2,
        artistCount: 2,
        albumCount: 2,
        playlistCount: 0,
        genreCount: 1,
        totalSizeBytes: 6000000,
        totalPlaytimeMs: 400000,
      );

      final fakeTrackRepo = FakeTrackRepository(initialTracks: tracks, initialStats: stats);

      await pumpTestApp(tester, child: const LibraryView(), fakeTrackRepo: fakeTrackRepo);

      // Header should display stats
      expect(find.text('2'), findsWidgets);
      expect(find.text('Tracks'), findsWidgets);
      expect(find.text('Recently Added'), findsOneWidget);
      expect(findRichText('Recent Song 1'), findsWidgets);
      expect(findRichText('Recent Song 2'), findsWidgets);
    });
  });
}
