import 'dart:async';

import 'package:just_audio/just_audio.dart';
import 'package:suara/models/song.dart';
import 'package:suara/widgets/position_data.dart';

class AudioManager {
  static final AudioManager _instance = AudioManager._internal();
  List<Song> _queue = []; // The active queue
  bool _isShuffle = false;
  List<Song> _originalQueue = []; // Backup of the clean order
  int _currentIndex = -1;

  factory AudioManager() {
    return _instance;
  }

  AudioManager._internal();

  final AudioPlayer _player = AudioPlayer();

  // Expose the playing status as a stream
  Stream<bool> get playingStream => _player.playingStream;

  // FULL AI GENERATED
  Stream<PositionData> get positionDataStream {
    // 1. Create a controller to manage the output stream
    StreamController<PositionData>? controller;

    // 2. We need to keep track of subscriptions to cancel them later
    StreamSubscription? positionSub;
    StreamSubscription? bufferSub;
    StreamSubscription? durationSub;

    // 3. The "Switchboard Operator" function
    // Whenever an event comes in, grab the LATEST values from the player
    // and push a new package to the UI.
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
        // Start listening to all three separate streams
        positionSub = _player.positionStream.listen((_) => emitData());
        bufferSub = _player.bufferedPositionStream.listen((_) => emitData());
        durationSub = _player.durationStream.listen((_) => emitData());
      },
      onCancel: () {
        // Clean up when the UI stops listening (Performance Awareness!)
        positionSub?.cancel();
        bufferSub?.cancel();
        durationSub?.cancel();
      },
    );

    return controller.stream;
  }

  // 1. The Switchboard: Holds the current 'Song' (or null if nothing is playing)
  final StreamController<Song?> _songController =
      StreamController<Song?>.broadcast();

  // 2. The Public Line: The UI listens to this
  Stream<Song?> get currentSongStream => _songController.stream;

  void setQueueAndPlay(List<Song> songs, int initialIndex) {
    _originalQueue = List.of(songs);
    _queue = List.of(songs);
    if (_isShuffle) {
      _queue.shuffle();

      final targetSong = songs[initialIndex];
      _queue.remove(targetSong); // Remove if exists
      _queue.insert(0, targetSong); // Force to top

      _currentIndex = 0;
      _play(_queue[0]);
    } else {
      _currentIndex = initialIndex;
      _play(_queue[_currentIndex]);
    }
  }

  // Expose loop mode as astream
  Stream<LoopMode> get loopModeStream => _player.loopModeStream;

  // Cycle Logic (Off -> All -> One -> Off)
  Future<void> cycleLoopMode() async {
    final current = _player.loopMode;
    final next = switch (current) {
      LoopMode.off => LoopMode.all,
      LoopMode.all => LoopMode.one,
      LoopMode.one => LoopMode.off,
    };
    await _player.setLoopMode(next);
  }

  // Shuffle State & Stream
  final StreamController<bool> _shuffleSubject = StreamController<bool>.broadcast();
  Stream<bool> get shuffleModeStream => _shuffleSubject.stream;
  // Helper for UI to know state IMMEDIATELY (before stream emits)
  bool get isShuffleEnabled => _isShuffle;

  void toggleShuffle() {
    if (!_isShuffle) {
      final newQueue = List.of(_originalQueue);
      newQueue.shuffle();
      
      // Keep current song playing?
      if (_currentIndex >= 0 && _currentIndex < _queue.length) {
        final currentSong = _queue[_currentIndex];
        newQueue.remove(currentSong);
        newQueue.insert(0, currentSong);
        _currentIndex = 0;
      }
      
      _queue = newQueue;
      _isShuffle = true;
    } else {
      // Find where our current song is in the ORIGINAL list
      final currentSong = _queue[_currentIndex];
      _currentIndex = _originalQueue.indexOf(currentSong);
      _queue = List.of(_originalQueue);

      _isShuffle = false;
    }

    _shuffleSubject.add(_isShuffle);
  }

  Future<void> _play(Song song) async {
    _songController.add(song);

    try {
      await _player.setFilePath(song.path);

      await _player.play();
    } catch (e) {
      print("AUDIO_DEBUG: Error playing audio: $e");
    }
  }

  Future<void> resume() async {
    await _player.play();
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> next() async {
    if (_currentIndex == _queue.length - 1) {
      if (_player.loopMode == LoopMode.all) {
        _currentIndex = 0;
        await _play(_queue[_currentIndex]);
      }
    } else {
      _currentIndex++;
      await _play(_queue[_currentIndex]);
    }
  }

  Future<void> previous() async {
    if (_currentIndex == 0) {
      if (_player.loopMode == LoopMode.all) {
        _currentIndex = _queue.length - 1;
        await _play(_queue[_currentIndex]);
      }
    } else {
      _currentIndex--;
      await _play(_queue[_currentIndex]);
    }
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }
}
