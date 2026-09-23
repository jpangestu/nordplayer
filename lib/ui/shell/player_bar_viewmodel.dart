import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nordplayer/domain/models/time_label_type.dart';
import 'package:nordplayer/data/repositories/config_repository.dart';
import 'package:nordplayer/data/repositories/playback_repository.dart';
import 'package:nordplayer/data/repositories/settings_repository.dart';
import 'package:nordplayer/ui/shell/player_bar_ui_state.dart';

/// ViewModel managing the player bar and playback controls.
class PlayerBarViewModel extends Notifier<PlayerBarUiState> {
  late PlaybackRepository _playbackRepo;
  late SettingsRepository _settingsRepo;
  late ConfigRepository _configRepo;

  @override
  PlayerBarUiState build() {
    _playbackRepo = ref.watch(playbackRepositoryProvider);
    _settingsRepo = ref.watch(settingsRepositoryProvider);
    _configRepo = ref.watch(configRepositoryProvider);

    final currentSettings = _settingsRepo.currentSettings;
    final currentConfig = _configRepo.currentConfig;

    final initialState = PlayerBarUiState(
      currentTrack: _playbackRepo.currentTrack,
      isPlaying: _playbackRepo.isPlaying,
      position: _playbackRepo.position,
      duration: _playbackRepo.duration,
      volume: currentSettings.volume,
      isMuted: currentSettings.isMuted,
      isShuffle: currentSettings.shuffleMode,
      loopMode: currentSettings.loopMode,
      showQueue: currentSettings.showQueue,
      timeLabelType: currentSettings.timeLabelType,
      isAdaptiveBgOn: currentConfig.adaptiveBg,
      adaptiveBgPanelBlur: currentConfig.adaptiveBgPanelBlur,
      adaptiveBgThemeOverlay: currentConfig.adaptiveBgThemeOverlay,
    );

    _listenToStreams();

    return initialState;
  }

  void _listenToStreams() {
    final sub1 = _playbackRepo.watchCurrentTrack().listen((track) {
      state = state.copyWith(currentTrack: () => track);
    });
    final sub2 = _playbackRepo.watchIsPlaying().listen((playing) {
      state = state.copyWith(isPlaying: playing);
    });
    final sub3 = _playbackRepo.watchPosition().listen((pos) {
      state = state.copyWith(position: pos);
    });
    final sub4 = _playbackRepo.watchDuration().listen((dur) {
      state = state.copyWith(duration: dur);
    });
    final sub5 = _settingsRepo.watchSettings().listen((settings) {
      state = state.copyWith(
        volume: settings.volume,
        isMuted: settings.isMuted,
        isShuffle: settings.shuffleMode,
        loopMode: settings.loopMode,
        showQueue: settings.showQueue,
        timeLabelType: settings.timeLabelType,
      );
    });
    final sub6 = _configRepo.watchConfig().listen((config) {
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
    });
  }

  // User Actions (Intents)

  Future<void> playOrPause() => _playbackRepo.playOrPause();

  Future<void> next() => _playbackRepo.next();

  Future<void> previous() => _playbackRepo.previous();

  Future<void> toggleShuffle() => _playbackRepo.toggleShuffle();

  Future<void> cycleLoopMode() => _playbackRepo.toggleLoop();

  Future<void> seek(Duration position) => _playbackRepo.seek(position);

  Future<void> setVolume(double volume) => _playbackRepo.setVolume(volume);

  Future<void> toggleMute() => _playbackRepo.toggleMute();

  Future<void> setVolumeUp([double step = 5]) => _playbackRepo.setVolumeUp(step);

  Future<void> setVolumeDown([double step = 5]) => _playbackRepo.setVolumeDown(step);

  Future<void> toggleShowQueue() => _settingsRepo.setShowQueue(!state.showQueue);

  Future<void> toggleTimeLabelType() {
    final nextType = state.timeLabelType == TimeLabelType.totalTime
        ? TimeLabelType.remainingTime
        : TimeLabelType.totalTime;
    return _settingsRepo.setTimeLabelType(nextType);
  }
}

/// Provider for [PlayerBarViewModel] and its immutable [PlayerBarUiState].
final playerBarViewModelProvider = NotifierProvider<PlayerBarViewModel, PlayerBarUiState>(PlayerBarViewModel.new);
