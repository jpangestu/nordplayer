import 'package:nordplayer/config/app_config.dart';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nordplayer/data/database/app_database.dart';
import 'package:nordplayer/data/repositories/config_repository.dart';
import 'package:nordplayer/data/repositories/indexer_repository.dart';
import 'package:nordplayer/data/repositories/playback_repository.dart';
import 'package:nordplayer/data/repositories/settings_repository.dart';
import 'package:nordplayer/data/services/system/config_service.dart';
import 'package:nordplayer/data/services/system/preference_service.dart';
import 'package:nordplayer/ui/settings/advanced/advanced_settings_viewmodel.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

class FakePlaybackRepositoryForAdvancedSettings extends Fake implements PlaybackRepository {
  bool clearedQueue = false;

  @override
  Future<void> clearQueue() async {
    clearedQueue = true;
  }
}

class FakeIndexerRepositoryForAdvancedSettings extends Fake implements IndexerRepository {
  bool scanCalled = false;
  final List<String> missingDirectories = [];
  final List<String> stoppedDirectories = [];

  @override
  Future<void> scanLibrary({void Function(int processed, int total)? onProgress}) async {
    scanCalled = true;
  }

  @override
  Future<void> markTracksInDirectoryAsMissing(String path) async {
    missingDirectories.add(path);
  }

  @override
  void stopWatchingDirectory(String path) {
    stoppedDirectories.add(path);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AdvancedSettingsViewModel', () {
    late AppDatabase db;
    late FakePlaybackRepositoryForAdvancedSettings fakePlaybackRepo;
    late FakeIndexerRepositoryForAdvancedSettings fakeIndexerRepo;
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
      fakePlaybackRepo = FakePlaybackRepositoryForAdvancedSettings();
      fakeIndexerRepo = FakeIndexerRepositoryForAdvancedSettings();
      tempDir = await Directory.systemTemp.createTemp('nordplayer_test_cache_');

      container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          playbackRepositoryProvider.overrideWithValue(fakePlaybackRepo),
          indexerRepositoryProvider.overrideWithValue(fakeIndexerRepo),
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

      final vm = container.read(advancedSettingsViewModelProvider.notifier);
      expect(container.read(advancedSettingsViewModelProvider).isProcessing, isFalse);

      await vm.resetSettingsToDefault();

      expect(container.read(advancedSettingsViewModelProvider).isProcessing, isFalse);
      expect(fakePlaybackRepo.clearedQueue, isTrue);
      expect(fakeIndexerRepo.stoppedDirectories, containsAll(['/music/dir1', '/music/dir2']));
      expect(fakeIndexerRepo.missingDirectories, containsAll(['/music/dir1', '/music/dir2']));

      // Config should be reset to default
      final config = container.read(configRepositoryProvider).currentConfig;
      expect(config.trackDirectories, isEmpty);
      expect(config.theme, equals('nord'));

      // Preferences should be reset to default
      final settings = container.read(settingsRepositoryProvider).currentSettings;
      expect(settings.isMuted, isFalse);
      expect(settings.volume, equals(100.0));

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

      final vm = container.read(advancedSettingsViewModelProvider.notifier);
      await vm.wipeAllLibraryData(getCacheDir: () async => tempDir);

      expect(container.read(advancedSettingsViewModelProvider).isProcessing, isFalse);
      expect(fakePlaybackRepo.clearedQueue, isTrue);
      expect(await artDir.exists(), isFalse);
      expect(fakeIndexerRepo.scanCalled, isTrue);
    });
  });
}
