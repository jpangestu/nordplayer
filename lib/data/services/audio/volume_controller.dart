import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nordplayer/data/repositories/queue_repository.dart';
import 'package:nordplayer/data/services/audio/audio_player_engine.dart';
import 'package:nordplayer/utils/debouncer.dart';

/// Controller coordinating volume level, mute state, and volume step adjustments
/// between the underlying [AudioPlayerEngine] and persistent [QueueRepository].
class VolumeController(
  final AudioPlayerEngine _playerEngine,
  final QueueRepository _queueRepository, {
  double initialVolume = 100.0,
  bool initialIsMuted = false,
  final Duration persistDebounce = const Duration(milliseconds: 300),
}) {
  double _volume = initialVolume.clamp(0.0, 100.0);
  bool _isMuted = initialIsMuted;
  final StreamController<bool> _isMutedController = StreamController<bool>.broadcast();
  final Debouncer _persistenceDebouncer = Debouncer(persistDebounce);

  /// Current volume level [0.0 - 100.0].
  double get volume => _volume;

  /// Whether audio output is currently muted.
  bool get isMuted => _isMuted;

  /// Continuous stream of volume changes from the audio engine, starting with current volume.
  Stream<double> watchVolume() async* {
    yield volume;
    yield* _playerEngine.volumeStream;
  }

  /// Continuous stream of mute state changes, starting with current state.
  Stream<bool> watchIsMuted() async* {
    yield isMuted;
    yield* _isMutedController.stream;
  }

  /// Initializes volume and mute state from restored persistent session.
  Future<void> initialize({required double volume, required bool isMuted}) async {
    _volume = volume.clamp(0.0, 100.0);
    _isMuted = isMuted;
    _isMutedController.add(_isMuted);
    await _playerEngine.setVolume(_isMuted ? 0.0 : _volume);
  }

  void _persist() {
    if (persistDebounce == Duration.zero) {
      _queueRepository.updateVolume(volume: _volume, isMuted: _isMuted);
    } else {
      _persistenceDebouncer(() {
        _queueRepository.updateVolume(volume: _volume, isMuted: _isMuted);
      });
    }
  }

  /// Sets the absolute volume level [0.0 - 100.0] and persists the setting.
  Future<void> setVolume(double newVolume) async {
    final clamped = newVolume.clamp(0.0, 100.0);
    _volume = clamped;
    if (_isMuted && clamped > 0) {
      _isMuted = false;
      _isMutedController.add(false);
    }
    await _playerEngine.setVolume(_isMuted ? 0.0 : clamped);
    _persist();
  }

  /// Increments volume by [step] (default 5.0) and unmutes if currently muted.
  Future<void> setVolumeUp([double step = 5]) async {
    final next = (_volume + step).clamp(0.0, 100.0);
    _isMuted = false;
    _isMutedController.add(false);
    await setVolume(next);
  }

  /// Decrements volume by [step] (default 5.0), automatically muting if reaching 0.
  Future<void> setVolumeDown([double step = 5]) async {
    final next = (_volume - step).clamp(0.0, 100.0);
    if (next == 0) {
      _isMuted = true;
      _isMutedController.add(true);
    }
    await setVolume(next);
  }

  /// Toggles mute state, restoring the previous volume level when unmuted.
  Future<void> toggleMute() async {
    _isMuted = !_isMuted;
    _isMutedController.add(_isMuted);
    await _playerEngine.setVolume(_isMuted ? 0.0 : _volume);
    _persist();
  }

  void dispose() {
    _persistenceDebouncer.cancel();
    _isMutedController.close();
  }
}

/// Riverpod provider for [VolumeController].
final volumeControllerProvider = Provider<VolumeController>((ref) {
  final playerEngine = ref.watch(audioPlayerEngineProvider);
  final queueRepo = ref.watch(queueRepositoryProvider);
  final controller = VolumeController(playerEngine, queueRepo);
  ref.onDispose(controller.dispose);
  return controller;
});
