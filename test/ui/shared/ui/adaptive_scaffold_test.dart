import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nordplayer/config/app_config.dart';
import 'package:nordplayer/data/repositories/config_repository.dart';
import 'package:nordplayer/data/repositories/ui_preferences_repository.dart';
import 'package:nordplayer/data/services/audio/playback_controller.dart';
import 'package:nordplayer/domain/models/album.dart';
import 'package:nordplayer/domain/models/artist.dart';
import 'package:nordplayer/domain/models/composite_models.dart';
import 'package:nordplayer/domain/models/track.dart';
import 'package:nordplayer/ui/shared/ui/adaptive_scaffold.dart';

import '../../../../testing/fakes/fake_config_repository.dart';
import '../../../../testing/fakes/fake_playback_controller.dart';
import '../../../../testing/fakes/fake_ui_preferences_repository.dart';

TrackWithArtists _createTrack(int id, String title, String? artPath) {
  return TrackWithArtists(
    track: Track(
      id: id,
      title: title,
      albumId: id,
      durationMs: 180000,
      fileHash: 'hash_$id',
      isMissing: false,
      filePath: '/music/$title.mp3',
      fileSize: 4000000,
      artistId: id,
      dateAdded: DateTime(2025, 1, 1),
    ),
    album: Album(id: id, title: 'Album $id', albumArtPath: artPath, albumArtistId: id),
    artists: [Artist(id: id, name: 'Artist $id')],
  );
}

void main() {
  group('AdaptiveScaffold & AdaptiveBackground Tests', () {
    late FakeConfigRepository fakeConfigRepo;
    late FakePlaybackController fakePlaybackController;
    late FakeUiPreferencesRepository fakeUiPrefRepo;

    setUp(() {
      fakeConfigRepo = FakeConfigRepository(
        AppConfig(
          adaptiveBg: false,
          adaptiveBgAlbumFit: BoxFit.cover,
          adaptiveBgAlbumBlur: 20.0,
          adaptiveBgThemeOverlay: 0.5,
        ),
      );
      fakePlaybackController = FakePlaybackController();
      fakeUiPrefRepo = FakeUiPreferencesRepository();
    });

    tearDown(() {
      fakeConfigRepo.dispose();
      fakePlaybackController.dispose();
      fakeUiPrefRepo.dispose();
    });

    Widget buildTestApp() {
      return ProviderScope(
        overrides: [
          configRepositoryProvider.overrideWithValue(fakeConfigRepo),
          playbackControllerProvider.overrideWithValue(fakePlaybackController),
          uiPreferencesRepositoryProvider.overrideWithValue(fakeUiPrefRepo),
        ],
        child: const MaterialApp(
          home: AdaptiveScaffold(
            body: Center(child: Text('App Content')),
          ),
        ),
      );
    }

    testWidgets('AdaptiveScaffold renders body text', (tester) async {
      await tester.pumpWidget(buildTestApp());
      expect(find.text('App Content'), findsOneWidget);
    });

    testWidgets('AdaptiveBackground is empty when adaptiveBg is false', (tester) async {
      await tester.pumpWidget(buildTestApp());
      expect(find.byType(AdaptiveBackground), findsOneWidget);
      // Because adaptiveBg is false, FadeTransition should not be present in background
      expect(find.descendant(of: find.byType(AdaptiveBackground), matching: find.byType(FadeTransition)), findsNothing);
    });

    testWidgets('AdaptiveBackground renders when adaptiveBg is true', (tester) async {
      fakeConfigRepo.updateConfig(
        fakeConfigRepo.currentConfig.copyWith(adaptiveBg: true),
      );

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.byType(AdaptiveBackground), findsOneWidget);
      expect(find.descendant(of: find.byType(AdaptiveBackground), matching: find.byType(FadeTransition)), findsOneWidget);
    });

    testWidgets('Rapid track skips are debounced and only transition to the final track', (tester) async {
      fakeConfigRepo.updateConfig(
        fakeConfigRepo.currentConfig.copyWith(adaptiveBg: true),
      );

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Rapidly skip 5 tracks in under 120ms total
      for (int i = 1; i <= 5; i++) {
        fakePlaybackController.emitCurrentTrack(_createTrack(i, 'Song $i', '/art/song_$i.jpg'));
        await tester.pump(const Duration(milliseconds: 20));
      }

      // During rapid skips, bounded layer count (at most 2 layers)
      final layersDuringDebounce = tester.widgetList(
        find.descendant(of: find.byType(AdaptiveBackground), matching: find.byType(RepaintBoundary)),
      );
      expect(layersDuringDebounce.length, lessThanOrEqualTo(2));

      // Advance clock past the 120ms debounce
      await tester.pump(const Duration(milliseconds: 150));

      // Advance through crossfade animation
      await tester.pump(const Duration(milliseconds: 200));

      // At most 2 layers exist during the active crossfade
      final layersDuringCrossfade = tester.widgetList(
        find.descendant(of: find.byType(AdaptiveBackground), matching: find.byType(RepaintBoundary)),
      );
      expect(layersDuringCrossfade.length, lessThanOrEqualTo(2));

      // Settle the animation
      await tester.pumpAndSettle();

      // After settling, old layer is unmounted and only 1 active layer remains
      final layersAfterSettled = tester.widgetList(
        find.descendant(of: find.byType(AdaptiveBackground), matching: find.byType(RepaintBoundary)),
      );
      expect(layersAfterSettled.length, equals(1));
    });

    testWidgets('Toggling adaptiveBg from true to false clears the cache and unmounts layers', (tester) async {
      fakeConfigRepo.updateConfig(
        fakeConfigRepo.currentConfig.copyWith(adaptiveBg: true),
      );

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();
      expect(find.descendant(of: find.byType(AdaptiveBackground), matching: find.byType(FadeTransition)), findsOneWidget);

      // Toggle off
      fakeConfigRepo.updateConfig(
        fakeConfigRepo.currentConfig.copyWith(adaptiveBg: false),
      );
      await tester.pumpAndSettle();

      expect(find.descendant(of: find.byType(AdaptiveBackground), matching: find.byType(FadeTransition)), findsNothing);
    });
  });
}
