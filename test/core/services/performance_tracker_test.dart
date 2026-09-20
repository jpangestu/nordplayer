import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nordplayer/core/services/performance_tracker.dart';
import 'package:nordplayer/core/services/preference_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PerformanceState Tests', () {
    test('default values and visibility checks', () {
      const state = PerformanceState();

      expect(state.actualFrameRate, 0);
      expect(state.isIdle, isTrue);
      expect(state.currentFrameTime, 0.0);
      expect(state.isVisible('potentialFps'), isFalse);
      expect(state.isVisible('unknown_key'), isFalse);
    });

    test('FPS and metric calculations', () {
      const state = PerformanceState(
        isIdle: false,
        currentFrameTime: 16.67, // ~60 FPS
        minFrameTime: 8.33, // ~120 FPS
        maxFrameTime: 33.33, // ~30 FPS
        averageFrameTime: 16.67,
      );

      expect(state.potentialFps, 60);
      expect(state.maxPotentialFps, 120);
      expect(state.minPotentialFps, 30);
      expect(state.averagePotentialFps, 60);
    });

    test('idle state returns 0 for calculated FPS', () {
      const state = PerformanceState(
        isIdle: true,
        currentFrameTime: 16.67,
        averageFrameTime: 16.67,
      );

      expect(state.potentialFps, 0);
      expect(state.averagePotentialFps, 0);
    });

    test('formatLatency handles ms and seconds', () {
      const state = PerformanceState();

      expect(state.formatLatency(16.5), '16.5 ms');
      expect(state.formatLatency(1500.0), '1.5 s');
    });

    test('formatRam handles MB and GB', () {
      const state = PerformanceState();

      expect(state.formatRam(50 * 1024 * 1024), '50.0 MB');
      expect(state.formatRam(1536 * 1024 * 1024), '1.5 GB');
    });
  });

  group('PerformanceTracker Notifier Tests', () {
    late SharedPreferencesWithCache prefs;

    setUp(() async {
      SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.withData({
        'perf_vis_potentialFps': true,
        'perf_vis_cpuUsage': false,
      });

      prefs = await SharedPreferencesWithCache.create(
        cacheOptions: const SharedPreferencesWithCacheOptions(
          allowList: PerformanceTracker.prefKeys,
        ),
      );
    });

    test('loads visibility preferences synchronously on initialization', () {
      final container = ProviderContainer(
        overrides: [
          sharedPrefsProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      final state = container.read(performanceTrackerProvider);

      expect(state.isVisible('potentialFps'), isTrue);
      expect(state.isVisible('cpuUsage'), isFalse);
    });

    test('toggleVisibility flips setting, updates state, and persists to cache', () {
      final container = ProviderContainer(
        overrides: [
          sharedPrefsProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(performanceTrackerProvider.notifier);

      expect(container.read(performanceTrackerProvider).isVisible('potentialFps'), isTrue);

      // Toggle off
      notifier.toggleVisibility('potentialFps');
      expect(container.read(performanceTrackerProvider).isVisible('potentialFps'), isFalse);
      expect(prefs.getBool('perf_vis_potentialFps'), isFalse);

      // Toggle back on
      notifier.toggleVisibility('potentialFps');
      expect(container.read(performanceTrackerProvider).isVisible('potentialFps'), isTrue);
      expect(prefs.getBool('perf_vis_potentialFps'), isTrue);
    });

    test('resetStats clears min, max, and average frame times', () {
      final container = ProviderContainer(
        overrides: [
          sharedPrefsProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(performanceTrackerProvider.notifier);

      notifier.resetStats();
      final state = container.read(performanceTrackerProvider);

      expect(state.minFrameTime, 0.0);
      expect(state.maxFrameTime, 0.0);
      expect(state.averageFrameTime, 0.0);
    });
  });
}
