import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:nordplayer/services/logger.dart';
import 'package:nordplayer/widgets/player_bar/progress_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrefConstants {
  static const String isMuted = 'isMuted';
  static const String loopMode = 'loopMode';
  static const String shuffleMode = 'shuffleMode';
  static const String sidebarExtended = 'sidebarExtended';
  static const String timeLabelType = 'timeLabelType';
  static const String volume = 'volume';

  static const bool defaultIsMuted = false;
  static const PlaylistMode defaultLoopMode = PlaylistMode.none;
  static const bool defaultShuffleMode = false;
  static const bool defaultSidebarExtended = true;
  static const TimeLabelType defaultTimeLabelType = .totalTime;
  static const double defaultVolume = 100;

  static const Set<String> allowList = {
    isMuted,
    loopMode,
    shuffleMode,
    sidebarExtended,
    timeLabelType,
    volume,
  };
}

@immutable
class PreferencesState {
  final bool isMuted;
  final PlaylistMode loopMode;
  final bool shuffleMode;
  final bool sidebarExtended;
  final TimeLabelType timeLabelType;
  final double volume;

  const PreferencesState({
    required this.isMuted,
    required this.loopMode,
    required this.shuffleMode,
    required this.sidebarExtended,
    required this.timeLabelType,
    required this.volume,
  });

  PreferencesState copyWith({
    bool? isMuted,
    PlaylistMode? loopMode,
    bool? shuffleMode,
    bool? sidebarExtended,
    TimeLabelType? timeLabelType,
    double? volume,
  }) {
    return PreferencesState(
      isMuted: isMuted ?? this.isMuted,
      loopMode: loopMode ?? this.loopMode,
      shuffleMode: shuffleMode ?? this.shuffleMode,
      sidebarExtended: sidebarExtended ?? this.sidebarExtended,
      timeLabelType: timeLabelType ?? this.timeLabelType,
      volume: volume ?? this.volume,
    );
  }
}

final sharedPrefsProvider = Provider<SharedPreferencesWithCache>((ref) {
  throw UnimplementedError('Initialize this in main.dart');
});

final preferenceServiceProvider =
    NotifierProvider<PreferenceService, PreferencesState>(() {
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
      isMuted:
          _prefs.getBool(PrefConstants.isMuted) ?? PrefConstants.defaultIsMuted,
      loopMode: _getLoopModeOrDefault(),
      shuffleMode:
          _prefs.getBool(PrefConstants.shuffleMode) ??
          PrefConstants.defaultShuffleMode,
      sidebarExtended:
          _prefs.getBool(PrefConstants.sidebarExtended) ??
          PrefConstants.defaultSidebarExtended,
      timeLabelType: _getTimeLabelTypeOrDefault(),
      volume:
          _prefs.getDouble(PrefConstants.volume) ?? PrefConstants.defaultVolume,
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

  void setIsMuted(bool value) {
    state = state.copyWith(isMuted: value);
    _setValue(PrefConstants.isMuted, value);
  }

  void setLoopMode(PlaylistMode value) {
    state = state.copyWith(loopMode: value);
    _setValue(PrefConstants.loopMode, value.toString());
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
      await _prefs.clear();

      // Reset the Riverpod state to trigger UI updates
      state = const PreferencesState(
        isMuted: PrefConstants.defaultIsMuted,
        loopMode: PrefConstants.defaultLoopMode,
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
