import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:media_kit/media_kit.dart';
import 'package:nordplayer/data/services/audio/audio_player_service.dart';

/// In-memory test double for [AudioPlayerService].
class FakeAudioPlayerService extends Fake implements AudioPlayerService {
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  final Duration _duration = const Duration(minutes: 3);
  double _volume = 100.0;
  PlaylistMode _playlistMode = PlaylistMode.none;

  final StreamController<bool> _playingController = StreamController<bool>.broadcast();
  final StreamController<Duration> _positionController = StreamController<Duration>.broadcast();
  final StreamController<Duration> _durationController = StreamController<Duration>.broadcast();
  final StreamController<double> _volumeController = StreamController<double>.broadcast();
  final StreamController<bool> _completedController = StreamController<bool>.broadcast();

  PlaylistMode get playlistMode => _playlistMode;

  @override
  bool get isPlaying => _isPlaying;

  @override
  Duration get position => _position;

  @override
  Duration get duration => _duration;

  @override
  double get volume => _volume;

  @override
  Stream<bool> get playingStream => _playingController.stream;

  @override
  Stream<Duration> get positionStream => _positionController.stream;

  @override
  Stream<Duration> get durationStream => _durationController.stream;

  @override
  Stream<double> get volumeStream => _volumeController.stream;

  @override
  Stream<bool> get completedStream => _completedController.stream;

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
    _volume = volume;
    _volumeController.add(_volume);
  }

  @override
  Future<void> setPlaylistMode(PlaylistMode mode) async {
    _playlistMode = mode;
  }

  @override
  Future<void> open(Playable playable, {bool play = true}) async {
    if (play) await this.play();
  }

  @override
  Future<void> dispose() async {
    _playingController.close();
    _positionController.close();
    _durationController.close();
    _volumeController.close();
    _completedController.close();
  }
}
