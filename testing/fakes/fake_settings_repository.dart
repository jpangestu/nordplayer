import 'dart:async';

import 'package:media_kit/media_kit.dart';
import 'package:nordplayer/data/repositories/settings_repository.dart';
import 'package:nordplayer/data/services/system/preference_service.dart';

/// In-memory test double for [SettingsRepository].
class FakeSettingsRepository implements SettingsRepository {
  PreferencesState _state;
  final StreamController<PreferencesState> _controller =
      StreamController<PreferencesState>.broadcast();

  FakeSettingsRepository({
    PreferencesState? initialState,
  }) : _state = initialState ??
            const PreferencesState(
              cachedAlbumArtPath: null,
              isMuted: PrefConstants.defaultIsMuted,
              loopMode: PrefConstants.defaultLoopMode,
              showQueue: PrefConstants.defaultShowQueue,
              shuffleMode: PrefConstants.defaultShuffleMode,
              sidebarExtended: PrefConstants.defaultSidebarExtended,
              timeLabelType: PrefConstants.defaultTimeLabelType,
              volume: PrefConstants.defaultVolume,
            );

  @override
  PreferencesState get currentSettings => _state;

  @override
  Stream<PreferencesState> watchSettings() {
    return Stream.value(_state).concatWith([_controller.stream]);
  }

  void _emit(PreferencesState newState) {
    _state = newState;
    _controller.add(_state);
  }

  @override
  Future<void> setCachedAlbumArtPath(String? path) async {
    _emit(_state.copyWith(cachedAlbumArtPath: path));
  }

  @override
  Future<void> setIsMuted(bool value) async {
    _emit(_state.copyWith(isMuted: value));
  }

  @override
  Future<void> setLoopMode(PlaylistMode value) async {
    _emit(_state.copyWith(loopMode: value));
  }

  @override
  Future<void> setShowQueue(bool value) async {
    _emit(_state.copyWith(showQueue: value));
  }

  @override
  Future<void> setShuffleMode(bool value) async {
    _emit(_state.copyWith(shuffleMode: value));
  }

  @override
  Future<void> setSidebarExtended(bool value) async {
    _emit(_state.copyWith(sidebarExtended: value));
  }

  @override
  Future<void> setTimeLabelType(TimeLabelType value) async {
    _emit(_state.copyWith(timeLabelType: value));
  }

  @override
  void setVolume(double value) {
    _emit(_state.copyWith(volume: value));
  }

  @override
  Future<void> resetToDefaults() async {
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
  }

  void dispose() {
    _controller.close();
  }
}

extension on Stream<dynamic> {
  Stream<T> concatWith<T>(Iterable<Stream<T>> others) async* {
    if (this is Stream<T>) {
      yield* this as Stream<T>;
    }
    for (final other in others) {
      yield* other;
    }
  }
}
