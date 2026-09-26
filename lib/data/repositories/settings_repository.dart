import 'package:nordplayer/domain/models/time_label_type.dart';
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:nordplayer/utils/logger.dart';
import 'package:nordplayer/data/services/system/preference_service.dart';
import 'package:nordplayer/data/services/storage/shared_preferences_service.dart';

/// Repository interface abstracting user preferences and settings.
abstract interface class SettingsRepository {
  /// The current cached preferences snapshot.
  PreferencesState get currentSettings;

  /// Reactive stream of settings updates.
  Stream<PreferencesState> watchSettings();

  /// Updates cached album art path.
  Future<void> setCachedAlbumArtPath(String? path);

  /// Sets mute state.
  Future<void> setIsMuted(bool value);

  /// Sets playlist loop mode.
  Future<void> setLoopMode(PlaylistMode value);

  /// Sets whether the queue overlay is visible.
  Future<void> setShowQueue(bool value);

  /// Sets shuffle mode.
  Future<void> setShuffleMode(bool value);

  /// Sets whether sidebar is expanded.
  Future<void> setSidebarExtended(bool value);

  /// Sets playback progress time label display style.
  Future<void> setTimeLabelType(TimeLabelType value);

  /// Sets audio playback volume (0-100).
  void setVolume(double value);

  /// Resets all preferences to initial defaults.
  Future<void> resetToDefaults();
}

/// Default implementation of [SettingsRepository] backed by [SharedPreferencesService].
class DefaultSettingsRepository(
  final SharedPreferencesService _prefsService, {
  final Future<void> Function()? onReset,
}) with LoggerMixin implements SettingsRepository {
  final StreamController<PreferencesState> _controller = StreamController<PreferencesState>.broadcast();
  late PreferencesState _state;
  Timer? _volumeDebounce;

  this {
    _state = PreferencesState(
      cachedAlbumArtPath: _prefsService.getString(PrefConstants.cachedCurrentAlbumArtPath),
      isMuted: _prefsService.getBool(PrefConstants.isMuted) ?? PrefConstants.defaultIsMuted,
      loopMode: _getLoopModeOrDefault(),
      showQueue: _prefsService.getBool(PrefConstants.showQueue) ?? PrefConstants.defaultShowQueue,
      shuffleMode: _prefsService.getBool(PrefConstants.shuffleMode) ?? PrefConstants.defaultShuffleMode,
      sidebarExtended: _prefsService.getBool(PrefConstants.sidebarExtended) ?? PrefConstants.defaultSidebarExtended,
      timeLabelType: _getTimeLabelTypeOrDefault(),
      volume: _prefsService.getDouble(PrefConstants.volume) ?? PrefConstants.defaultVolume,
    );
  }

  @override
  PreferencesState get currentSettings => _state;

  @override
  Stream<PreferencesState> watchSettings() => _controller.stream;

  void _emit(PreferencesState newState) {
    _state = newState;
    _controller.add(_state);
  }

  PlaylistMode _getLoopModeOrDefault() {
    final raw = _prefsService.getString(PrefConstants.loopMode);
    return PlaylistMode.values.firstWhere(
      (e) => e.toString() == raw,
      orElse: () => PrefConstants.defaultLoopMode,
    );
  }

  TimeLabelType _getTimeLabelTypeOrDefault() {
    final raw = _prefsService.getString(PrefConstants.timeLabelType);
    return TimeLabelType.values.firstWhere(
      (e) => e.toString() == raw,
      orElse: () => PrefConstants.defaultTimeLabelType,
    );
  }

  @override
  Future<void> setCachedAlbumArtPath(String? path) async {
    _emit(_state.copyWith(cachedAlbumArtPath: path));
    if (path != null) {
      await _prefsService.setString(PrefConstants.cachedCurrentAlbumArtPath, path);
    } else {
      await _prefsService.remove(PrefConstants.cachedCurrentAlbumArtPath);
    }
  }

  @override
  Future<void> setIsMuted(bool value) async {
    _emit(_state.copyWith(isMuted: value));
    await _prefsService.setBool(PrefConstants.isMuted, value);
  }

  @override
  Future<void> setLoopMode(PlaylistMode value) async {
    _emit(_state.copyWith(loopMode: value));
    await _prefsService.setString(PrefConstants.loopMode, value.toString());
  }

  @override
  Future<void> setShowQueue(bool value) async {
    _emit(_state.copyWith(showQueue: value));
    await _prefsService.setBool(PrefConstants.showQueue, value);
  }

  @override
  Future<void> setShuffleMode(bool value) async {
    _emit(_state.copyWith(shuffleMode: value));
    await _prefsService.setBool(PrefConstants.shuffleMode, value);
  }

  @override
  Future<void> setSidebarExtended(bool value) async {
    _emit(_state.copyWith(sidebarExtended: value));
    await _prefsService.setBool(PrefConstants.sidebarExtended, value);
  }

  @override
  Future<void> setTimeLabelType(TimeLabelType value) async {
    _emit(_state.copyWith(timeLabelType: value));
    await _prefsService.setString(PrefConstants.timeLabelType, value.toString());
  }

  @override
  void setVolume(double value) {
    if (_state.volume == value) return;
    _emit(_state.copyWith(volume: value));

    _volumeDebounce?.cancel();
    _volumeDebounce = Timer(const Duration(milliseconds: 500), () {
      _prefsService.setDouble(PrefConstants.volume, value);
    });
  }

  @override
  Future<void> resetToDefaults() async {
    _volumeDebounce?.cancel();
    const defaultState = PreferencesState(
      cachedAlbumArtPath: null,
      isMuted: PrefConstants.defaultIsMuted,
      loopMode: PrefConstants.defaultLoopMode,
      showQueue: PrefConstants.defaultShowQueue,
      shuffleMode: PrefConstants.defaultShuffleMode,
      sidebarExtended: PrefConstants.defaultSidebarExtended,
      timeLabelType: PrefConstants.defaultTimeLabelType,
      volume: PrefConstants.defaultVolume,
    );
    _emit(defaultState);
    await _prefsService.setBool(PrefConstants.isMuted, PrefConstants.defaultIsMuted);
    await _prefsService.setString(PrefConstants.loopMode, PrefConstants.defaultLoopMode.toString());
    await _prefsService.setBool(PrefConstants.showQueue, PrefConstants.defaultShowQueue);
    await _prefsService.setBool(PrefConstants.shuffleMode, PrefConstants.defaultShuffleMode);
    await _prefsService.setBool(PrefConstants.sidebarExtended, PrefConstants.defaultSidebarExtended);
    await _prefsService.setString(PrefConstants.timeLabelType, PrefConstants.defaultTimeLabelType.toString());
    await _prefsService.setDouble(PrefConstants.volume, PrefConstants.defaultVolume);
    await _prefsService.remove(PrefConstants.cachedCurrentAlbumArtPath);
    await onReset?.call();
  }

  void dispose() {
    _volumeDebounce?.cancel();
    _controller.close();
  }
}

/// Riverpod provider for [SettingsRepository].
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  // If sharedPreferencesInstanceProvider is overridden (e.g. from main or tests), use it
  try {
    final prefsService = ref.watch(sharedPreferencesServiceProvider);
    final repo = DefaultSettingsRepository(
      prefsService,
      onReset: () async => ref.read(preferenceServiceProvider.notifier).resetToDefaults(),
    );
    ref.onDispose(repo.dispose);
    return repo;
  } catch (_) {
    // Fallback using sharedPrefsProvider for existing test harnesses
    final rawPrefs = ref.watch(sharedPrefsProvider);
    final repo = DefaultSettingsRepository(
      SharedPreferencesService(rawPrefs),
      onReset: () async => ref.read(preferenceServiceProvider.notifier).resetToDefaults(),
    );
    ref.onDispose(repo.dispose);
    return repo;
  }
});

/// Stream provider for reactive settings updates.
final settingsStreamProvider = StreamProvider<PreferencesState>((ref) {
  final repo = ref.watch(settingsRepositoryProvider);
  return Stream.value(repo.currentSettings).concatWith([repo.watchSettings()]);
});

extension on Stream<PreferencesState> {
  Stream<PreferencesState> concatWith(Iterable<Stream<PreferencesState>> others) async* {
    yield* this;
    for (final other in others) {
      yield* other;
    }
  }
}
