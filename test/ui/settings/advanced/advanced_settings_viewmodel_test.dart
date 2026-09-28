import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nordplayer/config/app_config.dart';
import 'package:nordplayer/data/database/app_database.dart';
import 'package:nordplayer/data/repositories/config_repository.dart';
import 'package:nordplayer/data/repositories/indexer_repository.dart';
import 'package:nordplayer/data/repositories/ui_preferences_repository.dart';
import 'package:nordplayer/data/services/audio/playback_controller.dart';
import 'package:nordplayer/data/services/system/config_service.dart';
import 'package:nordplayer/ui/settings/advanced/advanced_settings_viewmodel.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../../../../testing/fakes/fake_indexer_repository.dart';
import '../../../../testing/fakes/fake_playback_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AdvancedSettingsViewModel', () {
    late AppDatabase db;
    late FakePlaybackController fakePlaybackController;
    late FakeIndexerRepository fakeIndexerRepo;
    late Directory tempDir;
    late ProviderContainer container;

    setUp(() async {
      SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.withData({
        UiPrefConstants.showQueue: true,
        UiPrefConstants.sidebarExtended: false,
      });

      final prefs = await SharedPreferencesWithCache.create(
        cacheOptions: const SharedPreferencesWithCacheOptions(allowList: UiPrefConstants.allowList),
      );

      db = AppDatabase(NativeDatabase.memory());
      fakePlaybackController = FakePlaybackController();
      fakeIndexerRepo = FakeIndexerRepository();
      tempDir = await Directory.systemTemp.createTemp('nordplayer_test_cache_');

      container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          playbackControllerProvider.overrideWithValue(fakePlaybackController),
          indexerRepositoryProvider.overrideWithValue(fakeIndexerRepo),
          sharedPrefsProvider.overrideWithValue(prefs),
          initialAppConfigProvider.overrideWithValue(
            AppConfig(trackDirectories: ['/music/dir1', '/music/dir2'], theme: 'adaptive'),
          ),
          configDirectoryProvider.overrideWithValue(tempDir),
        ],
      );
    });

    tearDown(() async {
      await db.close();
      container.dispose();
      fakePlaybackController.dispose();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('resetSettingsToDefault clears queue, resets config/prefs, and un-watches directories', () async {
      // Seed some database rows
      await db.into(db.artists).insert(ArtistsCompanion.insert(name: 'Orphan Artist'));

      final vm = container.read(advancedSettingsViewModelProvider.notifier);
      expect(container.read(advancedSettingsViewModelProvider).isProcessing, isFalse);

      await vm.resetSettingsToDefault();

      expect(container.read(advancedSettingsViewModelProvider).isProcessing, isFalse);
      expect(fakePlaybackController.clearedQueue, isTrue);
      expect(fakeIndexerRepo.stoppedDirectories, containsAll(['/music/dir1', '/music/dir2']));
      expect(fakeIndexerRepo.missingDirectories, containsAll(['/music/dir1', '/music/dir2']));

      // Config should be reset to default
      final config = container.read(configRepositoryProvider).currentConfig;
      expect(config.trackDirectories, isEmpty);
      expect(config.theme, equals('nord'));

      // Preferences should be reset to default
      final uiPrefs = container.read(uiPreferencesRepositoryProvider).currentPreferences;
      expect(uiPrefs.showQueue, isFalse);
      expect(uiPrefs.sidebarExtended, isTrue);

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
      expect(fakePlaybackController.clearedQueue, isTrue);
      expect(await artDir.exists(), isFalse);
      expect(fakeIndexerRepo.scanCalled, isTrue);
    });
  });
}
