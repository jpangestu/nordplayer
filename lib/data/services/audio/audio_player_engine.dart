import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:nordplayer/data/services/audio/player_service.dart' show audioPlayerProvider;

/// Abstract transport driver defining platform-independent audio operations and streams.
abstract interface class AudioPlayerEngine {
  /// Opens a track by [uri] and sets the initial playback state.
  ///
  /// If [startPosition] is provided, seeks to that position after opening.
  /// If [autoplay] is true, playback begins immediately.
  Future<void> open(String uri, {Duration? startPosition, bool autoplay = true});

  /// Pre-buffers the next track for native gapless transition.
  ///
  /// Passing `null` clears any pre-buffered next track.
  Future<void> setNextMedia(String? uri);

  /// Resumes or starts playback.
  Future<void> play();

  /// Pauses playback.
  Future<void> pause();

  /// Toggles between play and pause.
  Future<void> playOrPause();

  /// Stops playback and releases active media buffers.
  Future<void> stop();

  /// Seeks to a specific [position].
  Future<void> seek(Duration position);

  /// Sets audio volume between 0.0 and 100.0.
  Future<void> setVolume(double volume);

  /// Disposes underlying engine resources and stream subscriptions.
  Future<void> dispose();

  /// Stream of play/pause state changes.
  Stream<bool> get isPlayingStream;

  /// Stream of continuous playback position updates.
  Stream<Duration> get positionStream;

  /// Stream of total track duration.
  Stream<Duration> get durationStream;

  /// Stream of buffered duration.
  Stream<Duration> get bufferStream;

  /// Stream of audio volume updates.
  Stream<double> get volumeStream;

  /// Stream emitting when a track completes (either naturally or via gapless handoff),
  /// signaling the queue coordinator to advance.
  Stream<void> get completedStream;

  /// Snapshot of whether the engine is currently playing.
  bool get isPlaying;

  /// Current playback position snapshot.
  Duration get position;

  /// Current track duration snapshot.
  Duration get duration;

  /// Current volume snapshot (0.0 - 100.0).
  double get volume;

  /// Active track URI currently loaded in the transport engine.
  String? get currentUri;

  /// Next track URI pre-buffered in the transport engine for gapless playback.
  String? get nextUri;
}

/// [media_kit.Player] implementation of [AudioPlayerEngine] featuring a rolling 2-track window
/// for gapless transitions without excessive native memory allocation.
class MediaKitAudioPlayerEngine(
  final Player _player, {
  final bool disposePlayer = true,
}) implements AudioPlayerEngine {
  final bool _disposePlayer = disposePlayer;
  String? _currentUri;
  String? _nextUri;
  final StreamController<void> _completedController = StreamController<void>.broadcast();
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  bool _isTransitioning = false;

  this {
    _initEngineListeners();
  }

  void _initEngineListeners() {
    // 1. Detect gapless transition when media_kit advances to index 1 of the 2-track window
    _subscriptions.add(
      _player.stream.playlist.listen((playlist) async {
        if (playlist.medias.length >= 2 && playlist.index == 1 && !_isTransitioning) {
          _isTransitioning = true;
          try {
            // Native gapless transition to track 1 occurred
            _currentUri = _nextUri;
            _nextUri = null;
            // Drop old track 0 to maintain 2-track rolling window BEFORE emitting completion
            try {
              await _player.remove(0);
            } catch (_) {}
            _completedController.add(null);
          } finally {
            _isTransitioning = false;
          }
        }
      }),
    );

    // 2. Detect natural end of playback when there was no next track queued
    _subscriptions.add(
      _player.stream.completed.listen((isCompleted) {
        if (isCompleted && _player.state.playlist.index <= 0) {
          _completedController.add(null);
        }
      }),
    );
  }

  /// Underlying raw [Player] instance for native platform integration (e.g. MPRIS / SMTC).
  Player get rawPlayer => _player;

  @override
  String? get currentUri => _currentUri;

  @override
  String? get nextUri => _nextUri;

  @override
  Future<void> open(String uri, {Duration? startPosition, bool autoplay = true}) async {
    _currentUri = uri;
    _nextUri = null;
    await _player.open(Playlist([Media(uri)]), play: autoplay);
    if (startPosition != null && startPosition > Duration.zero) {
      await _player.seek(startPosition);
    }
  }

  @override
  Future<void> setNextMedia(String? uri) async {
    if (_nextUri == uri) return;

    // Await active transition so index 0 removal does not collide with index 1 modification
    while (_isTransitioning) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }

    _nextUri = uri;

    final playlist = _player.state.playlist;
    if (playlist.medias.isEmpty) return;

    try {
      if (uri == null) {
        if (playlist.medias.length > 1) {
          await _player.remove(1);
        }
      } else {
        if (playlist.medias.length == 1) {
          await _player.add(Media(uri));
        } else if (playlist.medias.length > 1 && playlist.medias[1].uri != Media(uri).uri) {
          await _player.remove(1);
          await _player.add(Media(uri));
        }
      }
    } catch (_) {}
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> playOrPause() => _player.playOrPause();

  @override
  Future<void> stop() async {
    _currentUri = null;
    _nextUri = null;
    await _player.stop();
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> setVolume(double volume) => _player.setVolume(volume);

  @override
  Stream<bool> get isPlayingStream => _player.stream.playing;

  @override
  Stream<Duration> get positionStream => _player.stream.position;

  @override
  Stream<Duration> get durationStream => _player.stream.duration;

  @override
  Stream<Duration> get bufferStream => _player.stream.buffer;

  @override
  Stream<double> get volumeStream => _player.stream.volume;

  @override
  Stream<void> get completedStream => _completedController.stream;

  @override
  bool get isPlaying => _player.state.playing;

  @override
  Duration get position => _player.state.position;

  @override
  Duration get duration => _player.state.duration;

  @override
  double get volume => _player.state.volume;

  @override
  Future<void> dispose() async {
    for (final sub in _subscriptions) {
      await sub.cancel();
    }
    _subscriptions.clear();
    await _completedController.close();
    if (_disposePlayer) {
      await _player.dispose();
    }
  }
}

/// Riverpod provider for [AudioPlayerEngine].
final audioPlayerEngineProvider = Provider<AudioPlayerEngine>((ref) {
  final player = ref.watch(audioPlayerProvider);
  final engine = MediaKitAudioPlayerEngine(player, disposePlayer: false);
  ref.onDispose(() => engine.dispose());
  return engine;
});
