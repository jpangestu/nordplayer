import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nordplayer/data/repositories/settings_repository.dart';
import 'package:nordplayer/data/services/audio/audio_player_engine.dart';

/// Controller coordinating volume level, mute state, and volume step adjustments
/// between the underlying [AudioPlayerEngine] and persistent [SettingsRepository].
class VolumeController(final AudioPlayerEngine _playerEngine, final SettingsRepository _settingsRepository) {
  /// Current volume level [0.0 - 100.0].
  double get volume => _playerEngine.volume;

  /// Whether audio output is currently muted.
  bool get isMuted => _settingsRepository.currentSettings.isMuted;

  /// Continuous stream of volume changes from the audio engine, starting with current volume.
  Stream<double> watchVolume() async* {
    yield volume;
    yield* _playerEngine.volumeStream;
  }

  /// Sets the absolute volume level [0.0 - 100.0] and persists the setting.
  Future<void> setVolume(double volume) async {
    final clamped = volume.clamp(0.0, 100.0);
    await _playerEngine.setVolume(clamped);
    _settingsRepository.setVolume(clamped);
  }

  /// Increments volume by [step] (default 5.0) and unmutes if currently muted.
  Future<void> setVolumeUp([double step = 5]) async {
    final current = _settingsRepository.currentSettings.volume;
    final next = (current + step).clamp(0.0, 100.0);
    await _settingsRepository.setIsMuted(false);
    await setVolume(next);
  }

  /// Decrements volume by [step] (default 5.0), automatically muting if reaching 0.
  Future<void> setVolumeDown([double step = 5]) async {
    final current = _settingsRepository.currentSettings.volume;
    final next = (current - step).clamp(0.0, 100.0);
    if (next == 0) {
      await _settingsRepository.setIsMuted(true);
    }
    await setVolume(next);
  }

  /// Toggles mute state, restoring the previous volume level when unmuted.
  Future<void> toggleMute() async {
    final nextMute = !isMuted;
    await _settingsRepository.setIsMuted(nextMute);
    await _playerEngine.setVolume(nextMute ? 0.0 : _settingsRepository.currentSettings.volume);
  }
}

/// Riverpod provider for [VolumeController].
final volumeControllerProvider = Provider<VolumeController>((ref) {
  final playerEngine = ref.watch(audioPlayerEngineProvider);
  final settingsRepo = ref.watch(settingsRepositoryProvider);
  return VolumeController(playerEngine, settingsRepo);
});
