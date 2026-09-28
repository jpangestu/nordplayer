import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nordplayer/data/repositories/ui_preferences_repository.dart';
import 'package:nordplayer/domain/models/time_label_type.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UiPreferencesState Tests', () {
    test('initial state and copyWith', () {
      const state = UiPreferencesState(
        cachedAlbumArtPath: '/path/art.png',
        showQueue: false,
        sidebarExtended: true,
        timeLabelType: TimeLabelType.totalTime,
      );

      expect(state.cachedAlbumArtPath, '/path/art.png');
      expect(state.showQueue, isFalse);
      expect(state.sidebarExtended, isTrue);
      expect(state.timeLabelType, TimeLabelType.totalTime);

      final updated = state.copyWith(
        showQueue: true,
        sidebarExtended: false,
        timeLabelType: TimeLabelType.remainingTime,
      );

      expect(updated.showQueue, isTrue);
      expect(updated.sidebarExtended, isFalse);
      expect(updated.timeLabelType, TimeLabelType.remainingTime);
      expect(updated.cachedAlbumArtPath, '/path/art.png'); // unchanged

      final nullArt = updated.copyWith(cachedAlbumArtPath: () => null);
      expect(nullArt.cachedAlbumArtPath, isNull);
    });

    test('default constructor matches UiPrefConstants defaults', () {
      const state = UiPreferencesState();

      expect(state.cachedAlbumArtPath, isNull);
      expect(state.showQueue, UiPrefConstants.defaultShowQueue);
      expect(state.sidebarExtended, UiPrefConstants.defaultSidebarExtended);
      expect(state.timeLabelType, UiPrefConstants.defaultTimeLabelType);
    });

    test('equality and hashCode', () {
      const state1 = UiPreferencesState(
        cachedAlbumArtPath: '/path/art.png',
        showQueue: false,
        sidebarExtended: true,
        timeLabelType: TimeLabelType.totalTime,
      );

      const state2 = UiPreferencesState(
        cachedAlbumArtPath: '/path/art.png',
        showQueue: false,
        sidebarExtended: true,
        timeLabelType: TimeLabelType.totalTime,
      );

      expect(state1, equals(state2));
      expect(state1.hashCode, equals(state2.hashCode));
      expect(state1.toString(), contains('showQueue: false'));
    });
  });

  group('DefaultUiPreferencesRepository Tests', () {
    late SharedPreferencesWithCache prefs;

    setUp(() async {
      SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.withData({
        UiPrefConstants.showQueue: true,
        UiPrefConstants.sidebarExtended: false,
        UiPrefConstants.timeLabelType: TimeLabelType.remainingTime.toString(),
      });

      prefs = await SharedPreferencesWithCache.create(
        cacheOptions: const SharedPreferencesWithCacheOptions(allowList: UiPrefConstants.allowList),
      );
    });

    test('loads preferences synchronously from cache on construction', () {
      final repo = DefaultUiPreferencesRepository(prefs);
      addTearDown(repo.dispose);

      final state = repo.currentPreferences;

      expect(state.showQueue, isTrue);
      expect(state.sidebarExtended, isFalse);
      expect(state.timeLabelType, TimeLabelType.remainingTime);
      expect(state.cachedAlbumArtPath, isNull);
    });

    test('mutating preferences updates state, emits to stream, and updates cache', () async {
      final repo = DefaultUiPreferencesRepository(prefs);
      addTearDown(repo.dispose);

      final emissions = <UiPreferencesState>[];
      final sub = repo.watchPreferences().listen(emissions.add);
      addTearDown(sub.cancel);

      await repo.setShowQueue(false);
      expect(repo.currentPreferences.showQueue, isFalse);
      expect(prefs.getBool(UiPrefConstants.showQueue), isFalse);

      await repo.setSidebarExtended(true);
      expect(repo.currentPreferences.sidebarExtended, isTrue);
      expect(prefs.getBool(UiPrefConstants.sidebarExtended), isTrue);

      await repo.setTimeLabelType(TimeLabelType.totalTime);
      expect(repo.currentPreferences.timeLabelType, TimeLabelType.totalTime);
      expect(prefs.getString(UiPrefConstants.timeLabelType), TimeLabelType.totalTime.toString());

      await repo.setCachedAlbumArtPath('/custom/art.jpg');
      expect(repo.currentPreferences.cachedAlbumArtPath, '/custom/art.jpg');
      expect(prefs.getString(UiPrefConstants.cachedCurrentAlbumArtPath), '/custom/art.jpg');

      await repo.setCachedAlbumArtPath(null);
      expect(repo.currentPreferences.cachedAlbumArtPath, isNull);
      expect(prefs.getString(UiPrefConstants.cachedCurrentAlbumArtPath), isNull);

      expect(emissions.length, 5);
    });

    test('setting unchanged value is a no-op and does not emit to stream', () async {
      final repo = DefaultUiPreferencesRepository(prefs);
      addTearDown(repo.dispose);

      final emissions = <UiPreferencesState>[];
      final sub = repo.watchPreferences().listen(emissions.add);
      addTearDown(sub.cancel);

      // Initial values: showQueue=true, sidebarExtended=false, timeLabelType=remainingTime
      await repo.setShowQueue(true);
      await repo.setSidebarExtended(false);
      await repo.setTimeLabelType(TimeLabelType.remainingTime);

      await pumpEventQueue();
      expect(emissions, isEmpty);
    });

    test('resetToDefaults clears preferences and resets state', () async {
      final repo = DefaultUiPreferencesRepository(prefs);
      addTearDown(repo.dispose);

      await repo.resetToDefaults();

      final state = repo.currentPreferences;
      expect(state.showQueue, UiPrefConstants.defaultShowQueue);
      expect(state.sidebarExtended, UiPrefConstants.defaultSidebarExtended);
      expect(state.timeLabelType, UiPrefConstants.defaultTimeLabelType);
      expect(state.cachedAlbumArtPath, isNull);
    });
  });

  group('uiPreferencesStateProvider Riverpod Tests', () {
    late SharedPreferencesWithCache prefs;

    setUp(() async {
      SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.withData({
        UiPrefConstants.showQueue: true,
        UiPrefConstants.sidebarExtended: false,
      });

      prefs = await SharedPreferencesWithCache.create(
        cacheOptions: const SharedPreferencesWithCacheOptions(allowList: UiPrefConstants.allowList),
      );
    });

    test('synchronously exposes current preferences and updates reactively', () async {
      final container = ProviderContainer(overrides: [sharedPrefsProvider.overrideWithValue(prefs)]);
      addTearDown(container.dispose);

      final state = container.read(uiPreferencesStateProvider);
      expect(state.showQueue, isTrue);
      expect(state.sidebarExtended, isFalse);

      final repo = container.read(uiPreferencesRepositoryProvider);
      await repo.setShowQueue(false);

      await pumpEventQueue();

      expect(container.read(uiPreferencesStateProvider).showQueue, isFalse);
    });
  });
}
