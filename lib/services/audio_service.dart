import 'dart:async';

import 'package:flutter/foundation.dart'; // REQUIRED for ChangeNotifier
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:suara/models/song.dart';

/// Central service for music playback.
/// Handles the Queue, Shuffle logic, Loop modes, and background audio notifications.
class AudioService extends ChangeNotifier {
  AudioService._internal() {
    // Listen for natural song completion to trigger auto-advance
    _player.playerStateStream.listen((playerState) {
      if (playerState.processingState == ProcessingState.completed) {
        next();
      }
      // Notify UI listeners when state changes (Buffering, Loading, Completed)
      notifyListeners();
    });

    // Listen for Play/Pause changes to update UI automatically
    _player.playingStream.listen((_) {
      notifyListeners();
    });
  }

  static final AudioService _singleton = AudioService._internal();
  factory AudioService() {
    return _singleton;
  }

  final AudioPlayer _player = AudioPlayer();

  // Internal State
  List<Song> _queue = [];
  List<Song> _originalQueue = [];
  bool _isShuffle = false;
  int _currentIndex = -1;

  // ===========================================================================
  // PUBLIC ACCESSORS (Replaces Streams)
  // ===========================================================================

  // Helper to check play state without a Stream
  bool get isPlaying => _player.playing;

  // Internal variable to remember the last value
  Song? _currentSong;
  Song? get currentSong => _currentSong;

  // Queue Accessor
  List<Song> get queue => _queue;

  /// Combines Position, Buffer, and Duration into a single stream for the Slider.
  Stream<PositionData> get positionDataStream {
    StreamController<PositionData>? controller;
    StreamSubscription? positionSub;
    StreamSubscription? bufferSub;
    StreamSubscription? durationSub;

    void emitData() {
      if (controller != null && !controller.isClosed) {
        controller.add(
          PositionData(
            _player.position,
            _player.bufferedPosition,
            _player.duration ?? Duration.zero,
          ),
        );
      }
    }

    controller = StreamController<PositionData>(
      onListen: () {
        positionSub = _player.positionStream.listen((_) => emitData());
        bufferSub = _player.bufferedPositionStream.listen((_) => emitData());
        durationSub = _player.durationStream.listen((_) => emitData());
      },
      onCancel: () {
        positionSub?.cancel();
        bufferSub?.cancel();
        durationSub?.cancel();
      },
    );

    return controller.stream;
  }

  // ===========================================================================
  // QUEUE MANAGEMENT
  // ===========================================================================

  /// Sets the queue and plays the song with the given [initialSongId].
  void setQueueAndPlay(List<Song> songs, int initialSongId) {
    _originalQueue = List.of(songs);
    _queue = List.of(songs);

    // --- STEP 1: FIND TARGET ---
    int targetIndex = _queue.indexWhere((s) => s.id == initialSongId);

    if (targetIndex == -1) {
      targetIndex = 0;
    }

    // --- STEP 2: HANDLE SHUFFLE ---
    if (_isShuffle) {
      _queue.shuffle();

      // Move selected song to the first index of the shuffled queue
      final targetSong = songs.firstWhere((s) => s.id == initialSongId);
      _queue.removeWhere((s) => s.id == initialSongId);
      _queue.insert(0, targetSong);

      _currentIndex = 0;
      _play(_queue[0]);
    } else {
      // Normal Playback
      _currentIndex = targetIndex;
      _play(_queue[_currentIndex]);
    }
  }

  // ===========================================================================
  // SHUFFLE LOGIC
  // ===========================================================================

  /// Synchronous getter for UI.
  bool get isShuffleEnabled => _isShuffle;

  /// Toggles shuffle on/off while preserving the currently playing song.
  void toggleShuffle() {
    final currentSongId = _currentIndex >= 0 ? _queue[_currentIndex].id : -1;

    if (!_isShuffle) {
      final newQueue = List.of(_originalQueue);
      newQueue.shuffle();

      if (currentSongId != -1) {
        final currentSong = _originalQueue.firstWhere(
          (s) => s.id == currentSongId,
        );
        newQueue.removeWhere((s) => s.id == currentSongId);
        newQueue.insert(0, currentSong);
        _currentIndex = 0;
      }

      _queue = newQueue;
      _isShuffle = true;
    } else {
      _queue = List.of(_originalQueue);

      if (currentSongId != -1) {
        _currentIndex = _queue.indexWhere((s) => s.id == currentSongId);
      }

      _isShuffle = false;
    }

    // Notify UI that shuffle state (and potentially queue order) changed
    notifyListeners();
  }

  // ===========================================================================
  // PLAYER CORE & NOTIFICATIONS
  // ===========================================================================

  Future<void> _play(Song song) async {
    _currentSong = song;
    // Update UI immediately (Song Title, Art)
    notifyListeners();

    try {
      final audioSource = AudioSource.file(
        song.path,
        tag: MediaItem(
          id: song.id.toString(),
          title: song.title,
          artist: song.artist,
          album: song.album,
          artUri: song.artPath != null ? Uri.file(song.artPath!) : null,
          duration: song.duration,
        ),
      );

      await _player.setAudioSource(audioSource);
      await _player.play();
    } catch (e) {
      print("AUDIO_DEBUG: Error playing audio: $e");
    }
  }

  // ===========================================================================
  // PLAYBACK CONTROLS
  // ===========================================================================

  Future<void> resume() async {
    if (_currentIndex != -1) {
      await _player.play();
      // notifyListeners() is handled by the listener in the constructor
    }
  }

  Future<void> pause() async {
    await _player.pause();
    // notifyListeners() is handled by the listener in the constructor
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  Future<void> next() async {
    if (_queue.isEmpty) return;

    if (_currentIndex == _queue.length - 1) {
      if (_loopMode == LoopMode.all) {
        _currentIndex = 0;
        await _play(_queue[_currentIndex]);
      }
    } else {
      _currentIndex++;
      await _play(_queue[_currentIndex]);
    }
  }

  Future<void> previous() async {
    if (_queue.isEmpty) return;

    if (_currentIndex == 0) {
      if (_loopMode == LoopMode.all) {
        _currentIndex = _queue.length - 1;
        await _play(_queue[_currentIndex]);
      }
    } else {
      _currentIndex--;
      await _play(_queue[_currentIndex]);
    }
  }

  // ===========================================================================
  // LOOP MODE ARCHITECTURE
  // ===========================================================================

  LoopMode _loopMode = LoopMode.off;

  // Getter replaced Stream
  LoopMode get loopMode => _loopMode;

  Future<void> cycleLoopMode() async {
    // Cycle State
    _loopMode = switch (_loopMode) {
      LoopMode.off => LoopMode.all,
      LoopMode.all => LoopMode.one,
      LoopMode.one => LoopMode.off,
    };

    // Synchronize with Engine
    if (_loopMode == LoopMode.one) {
      await _player.setLoopMode(LoopMode.one);
    } else {
      await _player.setLoopMode(LoopMode.off);
    }

    // Notify UI
    notifyListeners();
  }
}

class PositionData {
  final Duration position;
  final Duration bufferedPosition;
  final Duration duration;

  PositionData(this.position, this.bufferedPosition, this.duration);
}
