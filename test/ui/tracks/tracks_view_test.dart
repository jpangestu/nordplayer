import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nordplayer/domain/models/album.dart';
import 'package:nordplayer/domain/models/artist.dart';
import 'package:nordplayer/domain/models/composite_models.dart';
import 'package:nordplayer/domain/models/track.dart';
import 'package:nordplayer/ui/tracks/tracks_view.dart';

import '../../../testing/app.dart';
import '../../../testing/fakes/fake_track_repository.dart';

void main() {
  Finder findRichText(String text) {
    return find.byWidgetPredicate((widget) => widget is RichText && widget.text.toPlainText().contains(text));
  }

  TrackWithArtists createSampleTrack({
    required int id,
    required String title,
    required String artistName,
    required String albumTitle,
  }) {
    final track = Track(
      id: id,
      title: title,
      trackNumber: 1,
      trackTotal: 10,
      discNumber: 1,
      discTotal: 1,
      durationMs: 180000,
      fileHash: 'hash_$id',
      isMissing: false,
      filePath: '/music/$title.mp3',
      fileSize: 4000000,
      artistId: 1,
      albumId: 1,
      dateAdded: DateTime.now(),
    );
    final artist = Artist(id: 1, name: artistName);
    final album = Album(id: 1, title: albumTitle, albumArtistId: 1);
    return TrackWithArtists(track: track, album: album, artists: [artist]);
  }

  group('TracksView Widget Tests', () {
    testWidgets('renders empty state message when library has no tracks', (tester) async {
      final fakeTrackRepo = FakeTrackRepository(initialTracks: []);

      await pumpTestApp(tester, child: const TracksView(), fakeTrackRepo: fakeTrackRepo);

      expect(find.text('Your library is empty'), findsOneWidget);
      expect(find.text('Scan your local folders to set up your music library.'), findsOneWidget);
    });

    testWidgets('renders track details in table when tracks are populated', (tester) async {
      final sampleTracks = [
        createSampleTrack(id: 1, title: 'Comfortably Numb', artistName: 'Pink Floyd', albumTitle: 'The Wall'),
        createSampleTrack(id: 2, title: 'Time', artistName: 'Pink Floyd', albumTitle: 'The Dark Side of the Moon'),
      ];

      final fakeTrackRepo = FakeTrackRepository(initialTracks: sampleTracks);

      await pumpTestApp(tester, child: const TracksView(), fakeTrackRepo: fakeTrackRepo);

      expect(findRichText('Comfortably Numb'), findsOneWidget);
      expect(findRichText('Time'), findsOneWidget);
      expect(findRichText('Pink Floyd'), findsWidgets);
      expect(find.text('The Wall'), findsOneWidget);
      expect(find.text('The Dark Side of the Moon'), findsOneWidget);
    });

    testWidgets('tracks page header reflects total track count', (tester) async {
      final sampleTracks = [createSampleTrack(id: 1, title: 'Track A', artistName: 'Artist A', albumTitle: 'Album A')];

      final fakeTrackRepo = FakeTrackRepository(initialTracks: sampleTracks);

      await pumpTestApp(tester, child: const TracksView(), fakeTrackRepo: fakeTrackRepo);

      expect(find.text('Tracks'), findsOneWidget);
      expect(find.textContaining('1 Tracks'), findsOneWidget);
      expect(findRichText('Track A'), findsOneWidget);
    });
  });
}
