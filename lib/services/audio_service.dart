import 'dart:async';

import 'package:just_audio/just_audio.dart';
import 'package:suara/models/song.dart';
import 'package:suara/widgets/position_data.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  List<Song> _queue = []; // The active queue
  List<Song> _originalQueue = []; // Backup of the clean order
  bool _isShuffle = false;
  int _currentIndex = -1;

  factory AudioService() {
    return _instance;
  }

  AudioService._internal() {
    // Listen to player state for autoplay next song
    _player.playerStateStream.listen((playerState) {
      // Check if the engine finished the song naturally
      if (playerState.processingState == ProcessingState.completed) {
        next();
      }
    });
  }

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

  // LOOP MODE ARCHITECTURE
  //
  // We decouple the UI's LoopMode from the AudioPlayer's LoopMode.
  //
  // PROBLEM: `just_audio` calculates loops based on the current audio source.
  // Since we feed it one song at a time, `LoopMode.all` would infinitely loop
  // the CURRENT song, never triggering the 'completed' event we need for auto-advance.
  //
  // SOLUTION:
  // 1. UI: Shows the user's intent (Off, All, One).
  // 2. Engine:
  //    - If UI is 'One': Engine is set to 'One' (Native looping).
  //    - If UI is 'All': Engine is set to 'OFF'. This forces the song to "finish"
  //      naturally, triggering the listener to call our custom next() logic
  //      which handles the queue wrapping.
  LoopMode _loopMode = LoopMode.off;
  final StreamController<LoopMode> _loopModeController =
      StreamController<LoopMode>.broadcast();

  // Public API
  Stream<LoopMode> get loopModeStream => _loopModeController.stream;
  LoopMode get loopMode => _loopMode;

  // Cycle Logic (Off -> All -> One -> Off)
  Future<void> cycleLoopMode() async {
    _loopMode = switch (_loopMode) {
      LoopMode.off => LoopMode.all,
      LoopMode.all => LoopMode.one,
      LoopMode.one => LoopMode.off,
    };

    // Broadcast change to UI
    _loopModeController.add(_loopMode);

    // SYNCHRONIZATION LOGIC:
    // If the user wants to loop the entire queue ('All'), we must lie to the engine.
    // We tell it 'Off' so it finishes the track and lets our next() method handle the loop.
    if (_loopMode == LoopMode.one) {
      await _player.setLoopMode(LoopMode.one);
    } else {
      await _player.setLoopMode(LoopMode.off);
    }
  }

  // Shuffle State & Stream
  final StreamController<bool> _shuffleSubject =
      StreamController<bool>.broadcast();
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
    if (_currentIndex != -1) {
      await _player.play();
    }
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> next() async {
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

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }
}
