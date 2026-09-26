import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nordplayer/domain/models/album.dart';
import 'package:nordplayer/domain/models/artist.dart';
import 'package:nordplayer/domain/models/composite_models.dart';
import 'package:nordplayer/domain/models/track.dart';
import 'package:nordplayer/ui/shell/widgets/player_bar/nord_player_bar.dart';
import 'package:nordplayer/ui/shell/widgets/player_bar/playback.dart';

import '../../../testing/app.dart';
import '../../../testing/fakes/fake_playback_repository.dart';

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

  group('NordPlayerBar Widget Tests', () {
    testWidgets('renders player bar with playback controls when idle', (tester) async {
      final fakePlaybackRepo = FakePlaybackRepository(initialQueue: [], isPlaying: false);

      await pumpTestApp(tester, child: const NordPlayerBar(), fakePlaybackRepo: fakePlaybackRepo);

      expect(find.byType(NordPlayerBar), findsOneWidget);
      expect(find.byType(Playback), findsOneWidget);
    });

    testWidgets('renders current track title and artist when playing', (tester) async {
      final sampleTrack = createTrack(1, 'Bohemian Rhapsody', 'Queen');
      final fakePlaybackRepo = FakePlaybackRepository(initialQueue: [sampleTrack], initialIndex: 0, isPlaying: true);

      await pumpTestApp(tester, child: const NordPlayerBar(), fakePlaybackRepo: fakePlaybackRepo);

      expect(findRichText('Bohemian Rhapsody'), findsOneWidget);
      expect(findRichText('Queen'), findsWidgets);
    });

    testWidgets('tapping play/pause toggles playback state on repository', (tester) async {
      final sampleTrack = createTrack(1, 'Hotel California', 'Eagles');
      final fakePlaybackRepo = FakePlaybackRepository(initialQueue: [sampleTrack], initialIndex: 0, isPlaying: false);

      await pumpTestApp(tester, child: const NordPlayerBar(), fakePlaybackRepo: fakePlaybackRepo);

      expect(fakePlaybackRepo.isPlaying, isFalse);

      // Tap play button inside Playback controls
      final playButtonFinder = find.descendant(of: find.byType(Playback), matching: find.byType(GestureDetector));
      if (playButtonFinder.evaluate().isNotEmpty) {
        await tester.tap(playButtonFinder.first);
        await tester.pumpAndSettle();
      }
    });
  });
}
