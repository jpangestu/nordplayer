import 'dart:async';

import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nordplayer/domain/models/time_label_type.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider for the pre-initialized [SharedPreferencesWithCache] instance.
///
/// Overridden in `main.dart` at app startup via `ProviderScope(overrides: [...])`.
final sharedPrefsProvider = Provider<SharedPreferencesWithCache>((ref) {
  throw UnimplementedError('sharedPrefsProvider must be initialized in main.dart');
});

/// Preference key constants and default values for UI layout and shell toggles.
abstract final class UiPrefConstants {
  static const String cachedCurrentAlbumArtPath = 'cachedAlbumArtPath';
  static const String showQueue = 'showQueue';
  static const String sidebarExtended = 'sidebarExtended';
  static const String timeLabelType = 'timeLabelType';

  static const bool defaultShowQueue = false;
  static const bool defaultSidebarExtended = true;
  static const TimeLabelType defaultTimeLabelType = .totalTime;

  static const Set<String> performanceKeys = {
    'perf_vis_potentialFps',
    'perf_vis_avgPotentialFps',
    'perf_vis_minPotentialFps',
    'perf_vis_maxPotentialFps',
    'perf_vis_frameLatency',
    'perf_vis_averageFrameTime',
    'perf_vis_minFrameTime',
    'perf_vis_maxFrameTime',
    'perf_vis_actualFrameRate',
    'perf_vis_cpuUsage',
    'perf_vis_ramUsage',
  };

  static const Set<String> allowList = {
    cachedCurrentAlbumArtPath,
    showQueue,
    sidebarExtended,
    timeLabelType,
    ...performanceKeys,
  };
}

const _uiPrefSentinel = Object();

/// Immutable state model representing UI shell, panel visibility, and layout preferences.
@immutable
class const UiPreferencesState({
  final String? cachedAlbumArtPath,
  final bool showQueue = UiPrefConstants.defaultShowQueue,
  final bool sidebarExtended = UiPrefConstants.defaultSidebarExtended,
  final TimeLabelType timeLabelType = UiPrefConstants.defaultTimeLabelType,
}) {
  UiPreferencesState copyWith({
    Object? cachedAlbumArtPath = _uiPrefSentinel,
    bool? showQueue,
    bool? sidebarExtended,
    TimeLabelType? timeLabelType,
  }) {
    final String? resolvedArt;
    if (identical(cachedAlbumArtPath, _uiPrefSentinel)) {
      resolvedArt = this.cachedAlbumArtPath;
    } else if (cachedAlbumArtPath is String? Function()) {
      resolvedArt = cachedAlbumArtPath();
    } else {
      resolvedArt = cachedAlbumArtPath as String?;
    }

    return UiPreferencesState(
      cachedAlbumArtPath: resolvedArt,
      showQueue: showQueue ?? this.showQueue,
      sidebarExtended: sidebarExtended ?? this.sidebarExtended,
      timeLabelType: timeLabelType ?? this.timeLabelType,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UiPreferencesState &&
          runtimeType == other.runtimeType &&
          cachedAlbumArtPath == other.cachedAlbumArtPath &&
          showQueue == other.showQueue &&
          sidebarExtended == other.sidebarExtended &&
          timeLabelType == other.timeLabelType;

  @override
  int get hashCode => Object.hash(cachedAlbumArtPath, showQueue, sidebarExtended, timeLabelType);

  @override
  String toString() =>
      'UiPreferencesState('
      'showQueue: $showQueue, '
      'sidebarExtended: $sidebarExtended, '
      'timeLabelType: $timeLabelType, '
      'cachedAlbumArtPath: $cachedAlbumArtPath)';
}

/// Repository interface abstracting UI shell layout and viewport preferences.
abstract interface class UiPreferencesRepository {
  UiPreferencesState get currentPreferences;
  Stream<UiPreferencesState> watchPreferences();
  Future<void> setSidebarExtended(bool value);
  Future<void> setShowQueue(bool value);
  Future<void> setTimeLabelType(TimeLabelType value);
  Future<void> setCachedAlbumArtPath(String? path);
  Future<void> resetToDefaults();
}

/// Default implementation of [UiPreferencesRepository] backed directly by [SharedPreferencesWithCache].
class DefaultUiPreferencesRepository(final SharedPreferencesWithCache _prefs) implements UiPreferencesRepository {
  late UiPreferencesState _state = UiPreferencesState(
    cachedAlbumArtPath: _prefs.getString(UiPrefConstants.cachedCurrentAlbumArtPath),
    showQueue: _prefs.getBool(UiPrefConstants.showQueue) ?? UiPrefConstants.defaultShowQueue,
    sidebarExtended: _prefs.getBool(UiPrefConstants.sidebarExtended) ?? UiPrefConstants.defaultSidebarExtended,
    timeLabelType: _getTimeLabelTypeOrDefault(),
  );

  final StreamController<UiPreferencesState> _controller = StreamController<UiPreferencesState>.broadcast();

  @override
  UiPreferencesState get currentPreferences => _state;

  @override
  Stream<UiPreferencesState> watchPreferences() => _controller.stream;

  void _emit(UiPreferencesState newState) {
    _state = newState;
    _controller.add(_state);
  }

  TimeLabelType _getTimeLabelTypeOrDefault() {
    final raw = _prefs.getString(UiPrefConstants.timeLabelType);
    if (raw != null && raw.isNotEmpty) {
      if (raw == TimeLabelType.totalTime.toString()) {
        return TimeLabelType.totalTime;
      } else {
        return TimeLabelType.remainingTime;
      }
    }
    return UiPrefConstants.defaultTimeLabelType;
  }

  @override
  Future<void> setCachedAlbumArtPath(String? path) async {
    if (_state.cachedAlbumArtPath == path) return;
    _emit(_state.copyWith(cachedAlbumArtPath: path));
    if (path != null) {
      await _prefs.setString(UiPrefConstants.cachedCurrentAlbumArtPath, path);
    } else {
      await _prefs.remove(UiPrefConstants.cachedCurrentAlbumArtPath);
    }
  }

  @override
  Future<void> setShowQueue(bool value) async {
    if (_state.showQueue == value) return;
    _emit(_state.copyWith(showQueue: value));
    await _prefs.setBool(UiPrefConstants.showQueue, value);
  }

  @override
  Future<void> setSidebarExtended(bool value) async {
    if (_state.sidebarExtended == value) return;
    _emit(_state.copyWith(sidebarExtended: value));
    await _prefs.setBool(UiPrefConstants.sidebarExtended, value);
  }

  @override
  Future<void> setTimeLabelType(TimeLabelType value) async {
    if (_state.timeLabelType == value) return;
    _emit(_state.copyWith(timeLabelType: value));
    await _prefs.setString(UiPrefConstants.timeLabelType, value.toString());
  }

  @override
  Future<void> resetToDefaults() async {
    const defaultState = UiPreferencesState();
    if (_state == defaultState) return;
    _emit(defaultState);
    await Future.wait([
      _prefs.remove(UiPrefConstants.cachedCurrentAlbumArtPath),
      _prefs.remove(UiPrefConstants.showQueue),
      _prefs.remove(UiPrefConstants.sidebarExtended),
      _prefs.remove(UiPrefConstants.timeLabelType),
    ]);
  }

  void dispose() {
    _controller.close();
  }
}

/// Riverpod provider for [UiPreferencesRepository].
final uiPreferencesRepositoryProvider = Provider<UiPreferencesRepository>((ref) {
  final prefs = ref.watch(sharedPrefsProvider);
  final repo = DefaultUiPreferencesRepository(prefs);
  ref.onDispose(repo.dispose);
  return repo;
});

/// Riverpod provider exposing reactive [UiPreferencesState] with synchronous access and `.select()` support.
final uiPreferencesStateProvider = NotifierProvider<UiPreferencesStateNotifier, UiPreferencesState>(
  UiPreferencesStateNotifier.new,
);

class UiPreferencesStateNotifier extends Notifier<UiPreferencesState> {
  @override
  UiPreferencesState build() {
    final repo = ref.watch(uiPreferencesRepositoryProvider);
    final sub = repo.watchPreferences().listen((preferences) {
      state = preferences;
    });
    ref.onDispose(sub.cancel);
    return repo.currentPreferences;
  }
}
