import 'dart:async';

import 'package:nordplayer/data/repositories/ui_preferences_repository.dart';
import 'package:nordplayer/domain/models/time_label_type.dart';

/// In-memory test double for [UiPreferencesRepository].
class FakeUiPreferencesRepository({UiPreferencesState? initialState}) implements UiPreferencesRepository {
  UiPreferencesState _state = initialState ?? const UiPreferencesState();
  final StreamController<UiPreferencesState> _controller = StreamController<UiPreferencesState>.broadcast();

  @override
  UiPreferencesState get currentPreferences => _state;

  bool get showQueue => _state.showQueue;
  set showQueue(bool value) => setShowQueue(value);

  @override
  Stream<UiPreferencesState> watchPreferences() => _controller.stream;

  void _emit(UiPreferencesState newState) {
    _state = newState;
    _controller.add(_state);
  }

  @override
  Future<void> setCachedAlbumArtPath(String? path) async {
    _emit(_state.copyWith(cachedAlbumArtPath: path));
  }

  @override
  Future<void> setShowQueue(bool value) async {
    _emit(_state.copyWith(showQueue: value));
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
  Future<void> resetToDefaults() async {
    _emit(const UiPreferencesState());
  }

  void dispose() {
    _controller.close();
  }
}
