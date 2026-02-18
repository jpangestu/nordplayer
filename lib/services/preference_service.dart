import 'dart:async';

import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:nordplayer/services/logger.dart';
import 'package:nordplayer/widgets/player_bar/progress_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrefConstants {
  static const String loopMode = 'loopMode';
  static const String shuffleMode = 'shuffleMode';
  static const String sidebarExtended = 'sidebarExtended';
  static const String timeLabelType = 'timeLabelType';
  static const String volume = 'volume';

  static const PlaylistMode defaultLoopMode = PlaylistMode.none;
  static const bool defaultShuffleMode = false;
  static const bool defaultSidebarExtended = true;
  static const TimeLabelType defaultTimeLabelType = .totalTime;
  static const double defaultVolume = 1;

  static const Set<String> allowList = {
    loopMode,
    shuffleMode,
    sidebarExtended,
    timeLabelType,
    volume,
  };
}

class PreferenceService extends ChangeNotifier with LoggerMixin {
  PreferenceService._instance();
  static final PreferenceService _singleton = PreferenceService._instance();
  factory PreferenceService() => _singleton;

  SharedPreferencesWithCache? _prefs;

  PlaylistMode get loopMode {
    final result = _prefs?.getString(PrefConstants.loopMode);
    if (result == PlaylistMode.loop .toString()) return PlaylistMode.loop;
    if (result == PlaylistMode.single.toString()) return PlaylistMode.single;
    return PrefConstants.defaultLoopMode;
  }

  void setLoopMode(PlaylistMode value) {
    _setValue(PrefConstants.loopMode, value.toString());
  }

  bool get shuffleMode =>
      _prefs?.getBool(PrefConstants.shuffleMode) ??
      PrefConstants.defaultShuffleMode;

  void setShuffleMode(bool value) {
    _setValue(PrefConstants.shuffleMode, value);
  }

  bool get sidebarExtended =>
      _prefs?.getBool(PrefConstants.sidebarExtended) ??
      PrefConstants.defaultSidebarExtended;

  void setSidebarExtended(bool value) {
    _setValue(PrefConstants.sidebarExtended, value);
  }

  TimeLabelType get timeLabelType {
    final result = _prefs?.getString(PrefConstants.timeLabelType);

    if (result != null && result.isNotEmpty) {
      if (result == TimeLabelType.totalTime.toString()) {
        return TimeLabelType.totalTime;
      } else {
        return TimeLabelType.remainingTime;
      }
    }
    return PrefConstants.defaultTimeLabelType;
  }

  void setTimeLabelType(TimeLabelType value) {
    _setValue(PrefConstants.timeLabelType, value.toString());
  }

  double? _optimisticVolume;

  double get volume {
    // Return the memory value if it exists, otherwise check disk
    return _optimisticVolume ??
        _prefs?.getDouble(PrefConstants.volume) ??
        PrefConstants.defaultVolume;
  }

  Timer? _debounce;

  void setVolume(double value) {
    // Update memory and UI immediately
    if (_optimisticVolume == value) return;
    _optimisticVolume = value;
    notifyListeners();

    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _setValue(PrefConstants.volume, value);
      _optimisticVolume = null;
    });
  }

  /// Initializes the Shared Preferences cache.
  /// Must be called before accessing any properties.
  Future<void> init() async {
    log.d("Initializing Preference Service...");

    if (_prefs != null) {
      log.d("Preferences already initialized. Skipping.");
      return;
    }

    try {
      _prefs = await SharedPreferencesWithCache.create(
        cacheOptions: SharedPreferencesWithCacheOptions(
          allowList: PrefConstants.allowList,
        ),
      );

      log.i(
        "Preferences loaded successfully.\n"
        "Loop Mode      : $loopMode\n"
        "Shuffle Mode   : ${shuffleMode ? 'True' : 'False'}\n"
        "Sidebar        : ${sidebarExtended ? 'Extended' : 'Collapsed'}\n"
        "Time Label Type: $timeLabelType\n"
        "Volume         : $volume",
      );
    } catch (e, s) {
      log.e(
        "Failed to initialize preferences service.",
        error: e,
        stackTrace: s,
      );
    }
  }

  void _setValue(String key, dynamic value) {
    final currentValue = _prefs?.get(key);
    if (currentValue == value) return;

    log.d("Update Preferences -> $key: $value");

    try {
      if (value is bool) {
        _prefs?.setBool(key, value);
      } else if (value is String) {
        _prefs?.setString(key, value);
      } else if (value is int) {
        _prefs?.setInt(key, value);
      } else if (value is double) {
        _prefs?.setDouble(key, value);
      } else if (value is List<String>) {
        _prefs?.setStringList(key, value);
      }

      notifyListeners();
    } catch (e, s) {
      log.e("Failed to save preference: $key", error: e, stackTrace: s);
    }
  }

  Future<void> resetToDefaults() async {
    log.w("User requested factory reset of preferences.");

    try {
      _optimisticVolume = null;
      await _prefs?.clear();
      notifyListeners();
      log.i("Preferences reset to defaults.");
    } catch (e, s) {
      log.e("Failed to reset preferences.", error: e, stackTrace: s);
    }
  }
}
