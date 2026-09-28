import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nordplayer/data/repositories/config_repository.dart';
import 'package:nordplayer/data/repositories/ui_preferences_repository.dart';
import 'package:nordplayer/data/services/audio/playback_controller.dart';
import 'package:nordplayer/domain/models/time_label_type.dart';
import 'package:nordplayer/ui/shell/player_bar_ui_state.dart';

/// ViewModel managing the player bar and playback controls.
class PlayerBarViewModel extends Notifier<PlayerBarUiState> {
  late PlaybackController _playbackController;
  late UiPreferencesRepository _uiPreferencesRepo;
  late ConfigRepository _configRepo;

  @override
  PlayerBarUiState build() {
    _playbackController = ref.watch(playbackControllerProvider);
    _uiPreferencesRepo = ref.watch(uiPreferencesRepositoryProvider);
    _configRepo = ref.watch(configRepositoryProvider);

    final currentPrefs = _uiPreferencesRepo.currentPreferences;
    final currentConfig = _configRepo.currentConfig;
    final currentQueueState = _playbackController.queueState;

    final initialState = PlayerBarUiState(
      currentTrack: _playbackController.currentTrack,
      isPlaying: _playbackController.isPlaying,
      position: _playbackController.position,
      duration: _playbackController.duration,
      volume: _playbackController.volume,
      isMuted: _playbackController.isMuted,
      isShuffle: currentQueueState.isShuffle,
      loopMode: currentQueueState.loopMode.toPlaylistMode(),
      showQueue: currentPrefs.showQueue,
      timeLabelType: currentPrefs.timeLabelType,
      isAdaptiveBgOn: currentConfig.adaptiveBg,
      adaptiveBgPanelBlur: currentConfig.adaptiveBgPanelBlur,
      adaptiveBgThemeOverlay: currentConfig.adaptiveBgThemeOverlay,
    );

    _listenToStreams();

    return initialState;
  }

  void _listenToStreams() {
    final sub1 = _playbackController.watchCurrentTrack().listen((track) {
      state = state.copyWith(currentTrack: () => track);
    });
    final sub2 = _playbackController.watchIsPlaying().listen((playing) {
      state = state.copyWith(isPlaying: playing);
    });
    final sub3 = _playbackController.watchPosition().listen((pos) {
      state = state.copyWith(position: pos);
    });
    final sub4 = _playbackController.watchDuration().listen((dur) {
      state = state.copyWith(duration: dur);
    });
    final sub5 = _playbackController.watchVolume().listen((vol) {
      state = state.copyWith(volume: vol);
    });
    final sub6 = _playbackController.watchIsMuted().listen((muted) {
      state = state.copyWith(isMuted: muted);
    });
    final sub7 = _playbackController.watchQueueState().listen((qs) {
      state = state.copyWith(isShuffle: qs.isShuffle, loopMode: qs.loopMode.toPlaylistMode());
    });
    final sub8 = _uiPreferencesRepo.watchPreferences().listen((prefs) {
      state = state.copyWith(showQueue: prefs.showQueue, timeLabelType: prefs.timeLabelType);
    });
    final sub9 = _configRepo.watchConfig().listen((config) {
      state = state.copyWith(
        isAdaptiveBgOn: config.adaptiveBg,
        adaptiveBgPanelBlur: config.adaptiveBgPanelBlur,
        adaptiveBgThemeOverlay: config.adaptiveBgThemeOverlay,
      );
    });

    ref.onDispose(() {
      sub1.cancel();
      sub2.cancel();
      sub3.cancel();
      sub4.cancel();
      sub5.cancel();
      sub6.cancel();
      sub7.cancel();
      sub8.cancel();
      sub9.cancel();
    });
  }

  // User Actions (Intents)

  Future<void> playOrPause() => _playbackController.playOrPause();

  Future<void> next() => _playbackController.next();

  Future<void> previous() => _playbackController.previous();

  Future<void> toggleShuffle() => _playbackController.toggleShuffle();

  Future<void> cycleLoopMode() => _playbackController.toggleLoop();

  Future<void> seek(Duration position) => _playbackController.seek(position);

  Future<void> setVolume(double volume) => _playbackController.setVolume(volume);

  Future<void> toggleMute() => _playbackController.toggleMute();

  Future<void> setVolumeUp([double step = 5]) => _playbackController.setVolumeUp(step);

  Future<void> setVolumeDown([double step = 5]) => _playbackController.setVolumeDown(step);

  Future<void> toggleShowQueue() => _uiPreferencesRepo.setShowQueue(!state.showQueue);

  Future<void> toggleTimeLabelType() {
    final nextType = state.timeLabelType == TimeLabelType.totalTime
        ? TimeLabelType.remainingTime
        : TimeLabelType.totalTime;
    return _uiPreferencesRepo.setTimeLabelType(nextType);
  }
}

/// Provider for [PlayerBarViewModel] and its immutable [PlayerBarUiState].
final playerBarViewModelProvider = NotifierProvider<PlayerBarViewModel, PlayerBarUiState>(PlayerBarViewModel.new);
