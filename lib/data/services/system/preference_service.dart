import 'dart:async';

import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:nordplayer/domain/models/time_label_type.dart';
import 'package:nordplayer/utils/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider for the pre-initialized [SharedPreferencesWithCache] instance.
///
/// Must be overridden in `main.dart` at app startup via `ProviderScope(overrides: [...])`.
final sharedPrefsProvider = Provider<SharedPreferencesWithCache>((ref) {
  throw UnimplementedError('sharedPrefsProvider must be initialized in main.dart');
});

class PrefConstants {
  static const String cachedCurrentAlbumArtPath = 'cachedAlbumArtPath';
  static const String isMuted = 'isMuted';
  static const String loopMode = 'loopMode';
  static const String showQueue = 'showQueue';
  static const String shuffleMode = 'shuffleMode';
  static const String sidebarExtended = 'sidebarExtended';
  static const String timeLabelType = 'timeLabelType';
  static const String volume = 'volume';

  static const bool defaultIsMuted = false;
  static const PlaylistMode defaultLoopMode = PlaylistMode.none;
  static const bool defaultShowQueue = false;
  static const bool defaultShuffleMode = false;
  static const bool defaultSidebarExtended = true;
  static const TimeLabelType defaultTimeLabelType = .totalTime;
  static const double defaultVolume = 100;

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
    isMuted,
    loopMode,
    showQueue,
    shuffleMode,
    sidebarExtended,
    timeLabelType,
    volume,
    ...performanceKeys,
  };
}

const _prefSentinel = Object();

@immutable
class PreferencesState {
  final String? cachedAlbumArtPath;
  final bool isMuted;
  final PlaylistMode loopMode;
  final bool showQueue;
  final bool shuffleMode;
  final bool sidebarExtended;
  final TimeLabelType timeLabelType;
  final double volume;

  const PreferencesState({
    this.cachedAlbumArtPath,
    required this.isMuted,
    required this.loopMode,
    required this.showQueue,
    required this.shuffleMode,
    required this.sidebarExtended,
    required this.timeLabelType,
    required this.volume,
  });

  PreferencesState copyWith({
    Object? cachedAlbumArtPath = _prefSentinel,
    bool? isMuted,
    PlaylistMode? loopMode,
    bool? showQueue,
    bool? shuffleMode,
    bool? sidebarExtended,
    TimeLabelType? timeLabelType,
    double? volume,
  }) {
    return PreferencesState(
      cachedAlbumArtPath: identical(cachedAlbumArtPath, _prefSentinel)
          ? this.cachedAlbumArtPath
          : cachedAlbumArtPath as String?,
      isMuted: isMuted ?? this.isMuted,
      loopMode: loopMode ?? this.loopMode,
      showQueue: showQueue ?? this.showQueue,
      shuffleMode: shuffleMode ?? this.shuffleMode,
      sidebarExtended: sidebarExtended ?? this.sidebarExtended,
      timeLabelType: timeLabelType ?? this.timeLabelType,
      volume: volume ?? this.volume,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PreferencesState &&
          runtimeType == other.runtimeType &&
          cachedAlbumArtPath == other.cachedAlbumArtPath &&
          isMuted == other.isMuted &&
          loopMode == other.loopMode &&
          showQueue == other.showQueue &&
          shuffleMode == other.shuffleMode &&
          sidebarExtended == other.sidebarExtended &&
          timeLabelType == other.timeLabelType &&
          volume == other.volume;

  @override
  int get hashCode => Object.hash(
    cachedAlbumArtPath,
    isMuted,
    loopMode,
    showQueue,
    shuffleMode,
    sidebarExtended,
    timeLabelType,
    volume,
  );

  @override
  String toString() =>
      'PreferencesState('
      'isMuted: $isMuted, '
      'volume: $volume, '
      'loopMode: $loopMode, '
      'shuffleMode: $shuffleMode, '
      'showQueue: $showQueue, '
      'sidebarExtended: $sidebarExtended, '
      'timeLabelType: $timeLabelType, '
      'cachedAlbumArtPath: $cachedAlbumArtPath)';
}

final preferenceServiceProvider = NotifierProvider<PreferenceService, PreferencesState>(() {
  return PreferenceService();
});

class PreferenceService extends Notifier<PreferencesState> with LoggerMixin {
  late SharedPreferencesWithCache _prefs;
  Timer? _debounce;

  @override
  PreferencesState build() {
    _prefs = ref.watch(sharedPrefsProvider);

    ref.onDispose(() => _debounce?.cancel());

    log.i("Preference Service Initialized.");

    // Load everything synchronously from the cache
    return PreferencesState(
      cachedAlbumArtPath: _prefs.getString(PrefConstants.cachedCurrentAlbumArtPath),
      isMuted: _prefs.getBool(PrefConstants.isMuted) ?? PrefConstants.defaultIsMuted,
      loopMode: _getLoopModeOrDefault(),
      showQueue: _prefs.getBool(PrefConstants.showQueue) ?? PrefConstants.defaultShowQueue,
      shuffleMode: _prefs.getBool(PrefConstants.shuffleMode) ?? PrefConstants.defaultShuffleMode,
      sidebarExtended: _prefs.getBool(PrefConstants.sidebarExtended) ?? PrefConstants.defaultSidebarExtended,
      timeLabelType: _getTimeLabelTypeOrDefault(),
      volume: _prefs.getDouble(PrefConstants.volume) ?? PrefConstants.defaultVolume,
    );
  }

  void _setValue(String key, dynamic value) {
    final currentValue = _prefs.get(key);
    if (currentValue == value) return;

    log.d("Update Preferences -> $key: $value");

    try {
      if (value is bool) {
        _prefs.setBool(key, value);
      } else if (value is String) {
        _prefs.setString(key, value);
      } else if (value is int) {
        _prefs.setInt(key, value);
      } else if (value is double) {
        _prefs.setDouble(key, value);
      } else if (value is List<String>) {
        _prefs.setStringList(key, value);
      }
    } catch (e, s) {
      log.e("Failed to save preference: $key", error: e, stackTrace: s);
    }
  }

  void setCachedAlbumArtPath(String? path) {
    state = state.copyWith(cachedAlbumArtPath: path);
    if (path != null) {
      _setValue(PrefConstants.cachedCurrentAlbumArtPath, path);
    } else {
      _prefs.remove(PrefConstants.cachedCurrentAlbumArtPath);
    }
  }

  void setIsMuted(bool value) {
    state = state.copyWith(isMuted: value);
    _setValue(PrefConstants.isMuted, value);
  }

  void setLoopMode(PlaylistMode value) {
    state = state.copyWith(loopMode: value);
    _setValue(PrefConstants.loopMode, value.toString());
  }

  void setShowQueue(bool value) {
    state = state.copyWith(showQueue: value);
    _setValue(PrefConstants.showQueue, value);
  }

  void setShuffleMode(bool value) {
    state = state.copyWith(shuffleMode: value);
    _setValue(PrefConstants.shuffleMode, value);
  }

  void setSidebarExtended(bool value) {
    state = state.copyWith(sidebarExtended: value);
    _setValue(PrefConstants.sidebarExtended, value);
  }

  void setTimeLabelType(TimeLabelType value) {
    state = state.copyWith(timeLabelType: value);
    _setValue(PrefConstants.timeLabelType, value.toString());
  }

  void setVolume(double value) {
    if (state.volume == value) return;

    state = state.copyWith(volume: value);

    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _setValue(PrefConstants.volume, value);
    });
  }

  Future<void> resetToDefaults() async {
    log.w("User requested factory reset of preferences.");
    try {
      if (_debounce?.isActive ?? false) _debounce!.cancel();
      await Future.wait([
        _prefs.remove(PrefConstants.cachedCurrentAlbumArtPath),
        _prefs.remove(PrefConstants.isMuted),
        _prefs.remove(PrefConstants.loopMode),
        _prefs.remove(PrefConstants.showQueue),
        _prefs.remove(PrefConstants.shuffleMode),
        _prefs.remove(PrefConstants.sidebarExtended),
        _prefs.remove(PrefConstants.timeLabelType),
        _prefs.remove(PrefConstants.volume),
      ]);

      // Reset the Riverpod state to trigger UI updates
      state = const PreferencesState(
        isMuted: PrefConstants.defaultIsMuted,
        loopMode: PrefConstants.defaultLoopMode,
        showQueue: PrefConstants.defaultShowQueue,
        shuffleMode: PrefConstants.defaultShuffleMode,
        sidebarExtended: PrefConstants.defaultSidebarExtended,
        timeLabelType: PrefConstants.defaultTimeLabelType,
        volume: PrefConstants.defaultVolume,
      );

      log.i("Preferences reset to defaults.");
    } catch (e, s) {
      log.e("Failed to reset preferences.", error: e, stackTrace: s);
    }
  }

  //
  // Helpers for Complex Types
  //

  PlaylistMode _getLoopModeOrDefault() {
    final result = _prefs.getString(PrefConstants.loopMode);
    if (result == PlaylistMode.loop.toString()) return PlaylistMode.loop;
    if (result == PlaylistMode.single.toString()) return PlaylistMode.single;
    return PrefConstants.defaultLoopMode;
  }

  TimeLabelType _getTimeLabelTypeOrDefault() {
    final result = _prefs.getString(PrefConstants.timeLabelType);
    if (result != null && result.isNotEmpty) {
      if (result == TimeLabelType.totalTime.toString()) {
        return TimeLabelType.totalTime;
      } else {
        return TimeLabelType.remainingTime;
      }
    }
    return PrefConstants.defaultTimeLabelType;
  }
}
