import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:media_kit/media_kit.dart';
import 'package:nordplayer/core/system/preference_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PreferencesState Tests', () {
    test('initial state and copyWith', () {
      const state = PreferencesState(
        cachedAlbumArtPath: '/path/art.png',
        isMuted: false,
        loopMode: PlaylistMode.none,
        showQueue: false,
        shuffleMode: false,
        sidebarExtended: true,
        timeLabelType: TimeLabelType.totalTime,
        volume: 80.0,
      );

      expect(state.cachedAlbumArtPath, '/path/art.png');
      expect(state.isMuted, isFalse);
      expect(state.volume, 80.0);

      final updated = state.copyWith(
        isMuted: true,
        volume: 50.0,
        timeLabelType: TimeLabelType.remainingTime,
      );

      expect(updated.isMuted, isTrue);
      expect(updated.volume, 50.0);
      expect(updated.timeLabelType, TimeLabelType.remainingTime);
      expect(updated.cachedAlbumArtPath, '/path/art.png'); // unchanged
    });
  });

  group('PreferenceService Notifier Tests', () {
    late SharedPreferencesWithCache prefs;

    setUp(() async {
      SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.withData({
        PrefConstants.isMuted: true,
        PrefConstants.showQueue: true,
        PrefConstants.volume: 75.0,
        PrefConstants.loopMode: PlaylistMode.loop.toString(),
        PrefConstants.timeLabelType: TimeLabelType.remainingTime.toString(),
      });

      prefs = await SharedPreferencesWithCache.create(
        cacheOptions: const SharedPreferencesWithCacheOptions(
          allowList: PrefConstants.allowList,
        ),
      );
    });

    test('loads preferences synchronously from cache on build', () {
      final container = ProviderContainer(
        overrides: [
          sharedPrefsProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      final state = container.read(preferenceServiceProvider);

      expect(state.isMuted, isTrue);
      expect(state.showQueue, isTrue);
      expect(state.volume, 75.0);
      expect(state.loopMode, PlaylistMode.loop);
      expect(state.timeLabelType, TimeLabelType.remainingTime);
      expect(state.shuffleMode, PrefConstants.defaultShuffleMode);
      expect(state.sidebarExtended, PrefConstants.defaultSidebarExtended);
    });

    test('mutating preferences updates state and cache immediately', () {
      final container = ProviderContainer(
        overrides: [
          sharedPrefsProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(preferenceServiceProvider.notifier);

      notifier.setIsMuted(false);
      expect(container.read(preferenceServiceProvider).isMuted, isFalse);
      expect(prefs.getBool(PrefConstants.isMuted), isFalse);

      notifier.setShowQueue(false);
      expect(container.read(preferenceServiceProvider).showQueue, isFalse);
      expect(prefs.getBool(PrefConstants.showQueue), isFalse);

      notifier.setShuffleMode(true);
      expect(container.read(preferenceServiceProvider).shuffleMode, isTrue);
      expect(prefs.getBool(PrefConstants.shuffleMode), isTrue);

      notifier.setSidebarExtended(false);
      expect(container.read(preferenceServiceProvider).sidebarExtended, isFalse);
      expect(prefs.getBool(PrefConstants.sidebarExtended), isFalse);

      notifier.setLoopMode(PlaylistMode.single);
      expect(container.read(preferenceServiceProvider).loopMode, PlaylistMode.single);
      expect(prefs.getString(PrefConstants.loopMode), PlaylistMode.single.toString());

      notifier.setTimeLabelType(TimeLabelType.totalTime);
      expect(container.read(preferenceServiceProvider).timeLabelType, TimeLabelType.totalTime);
      expect(prefs.getString(PrefConstants.timeLabelType), TimeLabelType.totalTime.toString());

      notifier.setCachedAlbumArtPath('/custom/art.jpg');
      expect(container.read(preferenceServiceProvider).cachedAlbumArtPath, '/custom/art.jpg');
      expect(prefs.getString(PrefConstants.cachedCurrentAlbumArtPath), '/custom/art.jpg');

      notifier.setCachedAlbumArtPath(null);
      expect(container.read(preferenceServiceProvider).cachedAlbumArtPath, isNull);
      expect(prefs.getString(PrefConstants.cachedCurrentAlbumArtPath), isNull);
    });

    test('volume update updates state immediately and debounces disk persistence', () async {
      final container = ProviderContainer(
        overrides: [
          sharedPrefsProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(preferenceServiceProvider.notifier);

      notifier.setVolume(20.0);
      expect(container.read(preferenceServiceProvider).volume, 20.0);

      // Debounce timer is 500ms
      await Future.delayed(const Duration(milliseconds: 600));
      expect(prefs.getDouble(PrefConstants.volume), 20.0);
    });

    test('resetToDefaults clears all preferences and resets state', () async {
      final container = ProviderContainer(
        overrides: [
          sharedPrefsProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(preferenceServiceProvider.notifier);

      await notifier.resetToDefaults();

      final state = container.read(preferenceServiceProvider);
      expect(state.isMuted, PrefConstants.defaultIsMuted);
      expect(state.loopMode, PrefConstants.defaultLoopMode);
      expect(state.showQueue, PrefConstants.defaultShowQueue);
      expect(state.shuffleMode, PrefConstants.defaultShuffleMode);
      expect(state.sidebarExtended, PrefConstants.defaultSidebarExtended);
      expect(state.timeLabelType, PrefConstants.defaultTimeLabelType);
      expect(state.volume, PrefConstants.defaultVolume);
    });
  });
}
