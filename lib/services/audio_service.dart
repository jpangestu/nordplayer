import 'dart:async';

import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart'; // REQUIRED for notifications
import 'package:suara/models/song.dart';
import 'package:suara/widgets/position_data.dart';

/// Central service for music playback.
/// Handles the Queue, Shuffle logic, Loop modes, and background audio notifications.
class AudioService {
  // ===========================================================================
  // SINGLETON & INITIALIZATION
  // ===========================================================================

  static final AudioService _instance = AudioService._internal();

  factory AudioService() {
    return _instance;
  }

  AudioService._internal() {
    // Listen for natural song completion to trigger auto-advance
    _player.playerStateStream.listen((playerState) {
      if (playerState.processingState == ProcessingState.completed) {
        next();
      }
    });
  }

  final AudioPlayer _player = AudioPlayer();

  // Internal State
  List<Song> _queue = []; // The currently active playlist (might be shuffled)
  List<Song> _originalQueue = []; // Backup of the clean, ordered playlist
  bool _isShuffle = false;
  int _currentIndex = -1;

  // ===========================================================================
  // PUBLIC STREAMS (UI Listeners)
  // ===========================================================================

  Stream<bool> get playingStream => _player.playingStream;

  /// Combines Position, Buffer, and Duration into a single stream for the Slider.
  /// Acts as a "Switchboard" to prevent the UI from managing 3 separate subscriptions.
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


  // Internal variable to remember the last value
  Song? _currentSong; 
  Song? get currentSong => _currentSong;

  /// Stream for the currently playing Song object
  final StreamController<Song?> _songController =
      StreamController<Song?>.broadcast();
  Stream<Song?> get currentSongStream => _songController.stream;

  // ===========================================================================
  // QUEUE MANAGEMENT
  // ===========================================================================

  /// Sets the queue and plays the song with the given [initialSongId].
  ///
  /// We use [initialSongId] instead of an index because indices are unstable
  /// if the list is sorted or filtered differently in the UI.
  void setQueueAndPlay(List<Song> songs, int initialSongId) {
    _originalQueue = List.of(songs);
    _queue = List.of(songs);

    // --- STEP 1: FIND TARGET ---
    // Locate the exact song the user tapped, regardless of list order.
    int targetIndex = _queue.indexWhere((s) => s.id == initialSongId);

    if (targetIndex == -1) {
      // Fallback: If ID not found (should never happen), play first song
      targetIndex = 0;
    }

    // --- STEP 2: HANDLE SHUFFLE ---
    if (_isShuffle) {
      _queue.shuffle();

      // UX Rule: The song the user tapped MUST play first, even in shuffle mode.
      // So we find it, pull it out, and jam it to the top of the list.
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

  final StreamController<bool> _shuffleSubject =
      StreamController<bool>.broadcast();
  Stream<bool> get shuffleModeStream => _shuffleSubject.stream;

  /// Synchronous getter for UI to know state before stream emits.
  bool get isShuffleEnabled => _isShuffle;

  /// Toggles shuffle on/off while preserving the currently playing song.
  void toggleShuffle() {
    // Capture the ID of the song currently playing so we don't interrupt it.
    final currentSongId = _currentIndex >= 0 ? _queue[_currentIndex].id : -1;

    if (!_isShuffle) {
      // --- ENABLING SHUFFLE ---
      final newQueue = List.of(_originalQueue);
      newQueue.shuffle();

      // If playing, ensure current song stays at index 0 of the new shuffled list
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
      // --- DISABLING SHUFFLE ---
      // Restore the clean, original order
      _queue = List.of(_originalQueue);

      // Find where our current song lives in the original list so playback continues correctly
      if (currentSongId != -1) {
        _currentIndex = _queue.indexWhere((s) => s.id == currentSongId);
      }

      _isShuffle = false;
    }

    _shuffleSubject.add(_isShuffle);
  }

  // ===========================================================================
  // PLAYER CORE & NOTIFICATIONS
  // ===========================================================================

  Future<void> _play(Song song) async {
    _currentSong = song;
    _songController.add(song);

    try {
      // We wrap the file path in an AudioSource with a 'MediaItem' tag.
      // This 'MediaItem' is what 'just_audio_background' reads to generate
      // the Android/iOS notification and lock screen controls.
      final audioSource = AudioSource.file(
        song.path,
        tag: MediaItem(
          id: song.id.toString(), // Unique ID for the OS
          title: song.title,
          artist: song.artist,
          album: song.album,
          // Load art from local cache if available
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
    }
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  Future<void> next() async {
    if (_queue.isEmpty) return;

    // Check if we are at the end of the queue
    if (_currentIndex == _queue.length - 1) {
      // Only wrap around if LoopMode is ALL
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

    // Check if we are at the start of the queue
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

  // NOTE: We decouple UI LoopMode from the Engine LoopMode.
  // - UI 'All' -> Engine 'Off' (We handle the loop manually in next())
  // - UI 'One' -> Engine 'One' (Native looping)

  LoopMode _loopMode = LoopMode.off;
  final StreamController<LoopMode> _loopModeController =
      StreamController<LoopMode>.broadcast();

  Stream<LoopMode> get loopModeStream => _loopModeController.stream;
  LoopMode get loopMode => _loopMode;

  Future<void> cycleLoopMode() async {
    // 1. Cycle State (Off -> All -> One -> Off)
    _loopMode = switch (_loopMode) {
      LoopMode.off => LoopMode.all,
      LoopMode.all => LoopMode.one,
      LoopMode.one => LoopMode.off,
    };
    _loopModeController.add(_loopMode);

    // 2. Synchronize with Engine
    if (_loopMode == LoopMode.one) {
      await _player.setLoopMode(LoopMode.one);
    } else {
      // For 'All' and 'Off', we set engine to Off so it stops at end of track
      await _player.setLoopMode(LoopMode.off);
    }
  }
}
