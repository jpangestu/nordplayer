import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nordplayer/core/database/app_database.dart';
import 'package:nordplayer/core/services/config_service.dart';
import 'package:nordplayer/core/services/preference_service.dart';
import 'package:nordplayer/features/settings/advanced_settings_viewmodel.dart';
import 'package:nordplayer/services/library_indexer/library_indexer.dart';
import 'package:nordplayer/services/library_watcher.dart';
import 'package:nordplayer/services/player_service.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

class FakePlayerService extends Fake implements PlayerService {
  bool clearedQueue = false;

  @override
  Future<void> clearQueue() async {
    clearedQueue = true;
  }
}

class FakeLibraryIndexer extends Fake implements LibraryIndexer {
  bool scanCalled = false;
  final List<String> missingDirectories = [];

  @override
  Future<void> scanLibrary({void Function(int processed, int total)? onProgress}) async {
    scanCalled = true;
  }

  @override
  Future<void> markTracksInDirectoryAsMissing(String path) async {
    missingDirectories.add(path);
  }
}

class FakeLibraryWatcher extends Fake implements LibraryWatcher {
  final List<String> stoppedDirectories = [];

  @override
  void stopWatchingTrackDirectory(String path) {
    stoppedDirectories.add(path);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AdvancedSettingsViewModel', () {
    late AppDatabase db;
    late FakePlayerService fakePlayer;
    late FakeLibraryIndexer fakeIndexer;
    late FakeLibraryWatcher fakeWatcher;
    late Directory tempDir;
    late ProviderContainer container;

    setUp(() async {
      SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.withData({
        PrefConstants.isMuted: true,
        PrefConstants.volume: 40.0,
      });

      final prefs = await SharedPreferencesWithCache.create(
        cacheOptions: const SharedPreferencesWithCacheOptions(
          allowList: PrefConstants.allowList,
        ),
      );

      db = AppDatabase(NativeDatabase.memory());
      fakePlayer = FakePlayerService();
      fakeIndexer = FakeLibraryIndexer();
      fakeWatcher = FakeLibraryWatcher();
      tempDir = await Directory.systemTemp.createTemp('nordplayer_test_cache_');

      container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          playerServiceProvider.overrideWithValue(fakePlayer),
          libraryIndexerProvider.overrideWithValue(fakeIndexer),
          libraryWatcherProvider.overrideWithValue(fakeWatcher),
          sharedPrefsProvider.overrideWithValue(prefs),
          initialAppConfigProvider.overrideWithValue(
            AppConfig(
              trackDirectories: ['/music/dir1', '/music/dir2'],
              theme: 'adaptive',
            ),
          ),
          configDirectoryProvider.overrideWithValue(tempDir),
        ],
      );
    });

    tearDown(() async {
      await db.close();
      container.dispose();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('resetSettingsToDefault clears queue, resets config/prefs, and un-watches directories', () async {
      // Seed some database rows
      await db.into(db.artists).insert(
            ArtistsCompanion.insert(name: 'Orphan Artist'),
          );

      final vm = container.read(advancedSettingsViewModelProvider);
      await vm.resetSettingsToDefault();

      expect(fakePlayer.clearedQueue, isTrue);
      expect(fakeWatcher.stoppedDirectories, containsAll(['/music/dir1', '/music/dir2']));
      expect(fakeIndexer.missingDirectories, containsAll(['/music/dir1', '/music/dir2']));

      // Config should be reset to default
      final config = container.read(configServiceProvider);
      expect(config.trackDirectories, isEmpty);
      expect(config.theme, equals('nord'));

      // Preferences should be reset to default
      final prefs = container.read(preferenceServiceProvider);
      expect(prefs.isMuted, isFalse);
      expect(prefs.volume, equals(100.0));

      // Orphaned artists should be cleaned up
      final remainingArtists = await db.select(db.artists).get();
      expect(remainingArtists, isEmpty);
    });

    test('wipeAllLibraryData clears queue, deletes tables, and deletes album art directory', () async {
      // Create fake album_art directory in temp cache
      final artDir = Directory(p.join(tempDir.path, 'album_art'));
      await artDir.create(recursive: true);
      final sampleArt = File(p.join(artDir.path, 'cover.jpg'));
      await sampleArt.writeAsString('sample bytes');
      expect(await sampleArt.exists(), isTrue);

      final vm = container.read(advancedSettingsViewModelProvider);
      await vm.wipeAllLibraryData(getCacheDir: () async => tempDir);

      expect(fakePlayer.clearedQueue, isTrue);
      expect(await artDir.exists(), isFalse);
      expect(fakeIndexer.scanCalled, isTrue);
    });
  });
}
