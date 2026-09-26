import 'package:flutter_test/flutter_test.dart';
import 'package:nordplayer/domain/models/models.dart';
import 'package:nordplayer/ui/playlists/playlists_view.dart';

import '../../../testing/app.dart';
import '../../../testing/fakes/fake_playlist_repository.dart';

void main() {
  group('PlaylistsView Widget Tests', () {
    testWidgets('renders empty state when no playlists exist', (tester) async {
      final fakePlaylistRepo = FakePlaylistRepository(initialPlaylists: []);

      await pumpTestApp(
        tester,
        child: const PlaylistsView(),
        fakePlaylistRepo: fakePlaylistRepo,
      );

      expect(find.text('Playlists'), findsOneWidget);
      expect(find.text('No playlists yet. Create one to get started!'), findsOneWidget);
      expect(find.byTooltip('Add New Playlist'), findsOneWidget);
    });

    testWidgets('renders playlist cards with titles when populated', (tester) async {
      final samplePlaylists = [
        const PlaylistWithDetails(
          playlist: Playlist(id: 1, name: 'Rock Anthems'),
          trackCount: 15,
          imageUrls: [],
        ),
        const PlaylistWithDetails(
          playlist: Playlist(id: 2, name: 'Chill Vibes'),
          trackCount: 8,
          imageUrls: [],
        ),
      ];

      final fakePlaylistRepo = FakePlaylistRepository(initialPlaylists: samplePlaylists);

      await pumpTestApp(
        tester,
        child: const PlaylistsView(),
        fakePlaylistRepo: fakePlaylistRepo,
      );

      expect(find.text('Playlists'), findsOneWidget);
      expect(find.text('Rock Anthems'), findsOneWidget);
      expect(find.text('Chill Vibes'), findsOneWidget);
      expect(find.byType(PlaylistCard), findsNWidgets(2));
    });
  });
}
