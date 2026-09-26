import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:nordplayer/data/services/audio/audio_player_engine.dart';

/// In-memory test double for [AudioPlayerEngine] supporting gapless transitions and stream verification.
class FakeAudioPlayerEngine extends Fake implements AudioPlayerEngine {
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = const Duration(minutes: 3);
  Duration _buffer = Duration.zero;
  double _volume = 100.0;
  String? _currentUri;
  String? _nextUri;

  final StreamController<bool> _playingController = StreamController<bool>.broadcast();
  final StreamController<Duration> _positionController = StreamController<Duration>.broadcast();
  final StreamController<Duration> _durationController = StreamController<Duration>.broadcast();
  final StreamController<Duration> _bufferController = StreamController<Duration>.broadcast();
  final StreamController<void> _completedController = StreamController<void>.broadcast();

  String? get currentUri => _currentUri;
  String? get nextUri => _nextUri;

  @override
  bool get isPlaying => _isPlaying;

  @override
  Duration get position => _position;

  @override
  Duration get duration => _duration;

  @override
  double get volume => _volume;

  Duration get buffer => _buffer;

  @override
  Stream<bool> get isPlayingStream => _playingController.stream;

  @override
  Stream<Duration> get positionStream => _positionController.stream;

  @override
  Stream<Duration> get durationStream => _durationController.stream;

  @override
  Stream<Duration> get bufferStream => _bufferController.stream;

  @override
  Stream<void> get completedStream => _completedController.stream;

  @override
  Future<void> open(String uri, {Duration? startPosition, bool autoplay = true}) async {
    _currentUri = uri;
    _nextUri = null;
    _position = startPosition ?? Duration.zero;
    _positionController.add(_position);
    if (autoplay) {
      await play();
    } else {
      await pause();
    }
  }

  @override
  Future<void> setNextMedia(String? uri) async {
    _nextUri = uri;
  }

  @override
  Future<void> play() async {
    _isPlaying = true;
    _playingController.add(true);
  }

  @override
  Future<void> pause() async {
    _isPlaying = false;
    _playingController.add(false);
  }

  @override
  Future<void> playOrPause() async {
    if (_isPlaying) {
      await pause();
    } else {
      await play();
    }
  }

  @override
  Future<void> stop() async {
    _isPlaying = false;
    _position = Duration.zero;
    _currentUri = null;
    _nextUri = null;
    _playingController.add(false);
    _positionController.add(Duration.zero);
  }

  @override
  Future<void> seek(Duration position) async {
    _position = position;
    _positionController.add(_position);
  }

  @override
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 100.0);
  }

  /// Test helper: simulate natural or gapless track completion.
  void simulateTrackCompleted() {
    _completedController.add(null);
  }

  /// Test helper: update track duration.
  void setTrackDuration(Duration duration) {
    _duration = duration;
    _durationController.add(duration);
  }

  /// Test helper: update current playback position.
  void updatePosition(Duration position) {
    _position = position;
    _positionController.add(position);
  }

  /// Test helper: update buffered position.
  void updateBuffer(Duration buffer) {
    _buffer = buffer;
    _bufferController.add(buffer);
  }

  @override
  Future<void> dispose() async {
    await _playingController.close();
    await _positionController.close();
    await _durationController.close();
    await _bufferController.close();
    await _completedController.close();
  }
}
