import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nordplayer/data/repositories/album_repository.dart';
import 'package:nordplayer/data/repositories/artist_repository.dart';
import 'package:nordplayer/data/repositories/config_repository.dart';
import 'package:nordplayer/data/repositories/indexer_repository.dart';
import 'package:nordplayer/data/repositories/playback_repository.dart';
import 'package:nordplayer/data/repositories/playlist_repository.dart';
import 'package:nordplayer/data/repositories/settings_repository.dart';
import 'package:nordplayer/data/repositories/track_repository.dart';
import 'package:nordplayer/ui/shared/themes/app_theme.dart';

import 'fakes/fake_album_repository.dart';
import 'fakes/fake_artist_repository.dart';
import 'fakes/fake_config_repository.dart';
import 'fakes/fake_indexer_repository.dart';
import 'fakes/fake_playback_repository.dart';
import 'fakes/fake_playlist_repository.dart';
import 'fakes/fake_settings_repository.dart';
import 'fakes/fake_track_repository.dart';

/// Test helper providing standard repository overrides and theme scaffolding for widget tests.
Widget createTestApp({
  required Widget child,
  List<dynamic> overrides = const [],
  ThemeData? theme,
  FakeTrackRepository? fakeTrackRepo,
  FakePlaybackRepository? fakePlaybackRepo,
  FakeAlbumRepository? fakeAlbumRepo,
  FakeArtistRepository? fakeArtistRepo,
  FakePlaylistRepository? fakePlaylistRepo,
  FakeSettingsRepository? fakeSettingsRepo,
  FakeConfigRepository? fakeConfigRepo,
  FakeIndexerRepository? fakeIndexerRepo,
}) {
  final defaultOverrides = [
    trackRepositoryProvider.overrideWithValue(fakeTrackRepo ?? FakeTrackRepository()),
    playbackRepositoryProvider.overrideWithValue(fakePlaybackRepo ?? FakePlaybackRepository()),
    albumRepositoryProvider.overrideWithValue(fakeAlbumRepo ?? FakeAlbumRepository()),
    artistRepositoryProvider.overrideWithValue(fakeArtistRepo ?? FakeArtistRepository()),
    playlistRepositoryProvider.overrideWithValue(fakePlaylistRepo ?? FakePlaylistRepository()),
    settingsRepositoryProvider.overrideWithValue(fakeSettingsRepo ?? FakeSettingsRepository()),
    configRepositoryProvider.overrideWithValue(fakeConfigRepo ?? FakeConfigRepository()),
    indexerRepositoryProvider.overrideWithValue(fakeIndexerRepo ?? FakeIndexerRepository()),
    ...overrides,
  ];

  return ProviderScope(
    overrides: defaultOverrides.cast(),
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: theme ?? AppTheme.getTheme('nord', null),
      home: Scaffold(body: child),
    ),
  );
}

/// Convenience helper to pump a test app with standard desktop sizing and settled frames.
Future<void> pumpTestApp(
  WidgetTester tester, {
  required Widget child,
  List<dynamic> overrides = const [],
  ThemeData? theme,
  Size surfaceSize = const Size(1280, 800),
  FakeTrackRepository? fakeTrackRepo,
  FakePlaybackRepository? fakePlaybackRepo,
  FakeAlbumRepository? fakeAlbumRepo,
  FakeArtistRepository? fakeArtistRepo,
  FakePlaylistRepository? fakePlaylistRepo,
  FakeSettingsRepository? fakeSettingsRepo,
  FakeConfigRepository? fakeConfigRepo,
  FakeIndexerRepository? fakeIndexerRepo,
}) async {
  tester.view.physicalSize = surfaceSize;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(
    createTestApp(
      child: child,
      overrides: overrides,
      theme: theme,
      fakeTrackRepo: fakeTrackRepo,
      fakePlaybackRepo: fakePlaybackRepo,
      fakeAlbumRepo: fakeAlbumRepo,
      fakeArtistRepo: fakeArtistRepo,
      fakePlaylistRepo: fakePlaylistRepo,
      fakeSettingsRepo: fakeSettingsRepo,
      fakeConfigRepo: fakeConfigRepo,
      fakeIndexerRepo: fakeIndexerRepo,
    ),
  );
  await tester.pumpAndSettle();
}
