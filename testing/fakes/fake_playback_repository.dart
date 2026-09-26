// ignore_for_file: prefer_initializing_formals

import 'dart:async';

import 'package:media_kit/media_kit.dart' hide Track;
import 'package:nordplayer/data/repositories/playback_repository.dart';
import 'package:nordplayer/domain/models/composite_models.dart';

/// In-memory test double for [PlaybackRepository].
class FakePlaybackRepository({
  List<TrackWithArtists>? initialQueue,
  int? initialIndex,
  bool isPlaying = false,
  Duration position = Duration.zero,
  Duration duration = const Duration(minutes: 3),
  double volume = 100.0,
  bool isMuted = false,
  bool isShuffle = false,
  PlaylistMode loopMode = PlaylistMode.none,
  String playbackContextType = '',
  int? playbackContextId,
}) implements PlaybackRepository {
  List<TrackWithArtists> _currentQueue = initialQueue ?? [];
  List<TrackWithArtists> _originalQueue = initialQueue != null ? List.from(initialQueue) : [];
  int _currentIndex = initialIndex ?? ((initialQueue != null && initialQueue.isNotEmpty) ? 0 : -1);
  bool _isPlaying = isPlaying;
  Duration _position = position;
  final Duration _duration = duration;
  double _volume = volume;
  bool _isMuted = isMuted;
  bool _isShuffle = isShuffle;
  PlaylistMode _loopMode = loopMode;
  String _playbackContextType = playbackContextType;
  int? _playbackContextId = playbackContextId;
  bool _suppressNextScroll = false;

  TrackWithArtists? _overrideCurrentTrack;
  bool _hasOverrideCurrentTrack = false;

  // Test inspection fields
  int moveOld = -1;
  int moveNew = -1;
  int removedIndex = -1;
  List<int> batchRemoved = [];
  bool cleared = false;
  int jumpedIndex = -1;
  bool suppressedScroll = false;
  final List<TrackWithArtists> addedToQueueTracks = [];

  List<TrackWithArtists> lastTracks = [];
  int lastInitialIndex = -1;
  String lastContextType = '';
  int? lastContextId;

  List<TrackWithArtists> get setPlaylistTracks => lastTracks;
  int get setPlaylistIndex => lastInitialIndex;
  String get setPlaylistContextType => lastContextType;
  int? get setPlaylistContextId => lastContextId;
  bool get clearedQueue => cleared;

  final StreamController<TrackWithArtists?> _currentTrackController = StreamController<TrackWithArtists?>.broadcast();
  final StreamController<int> _currentIndexController = StreamController<int>.broadcast();
  final StreamController<List<TrackWithArtists>> _queueController =
      StreamController<List<TrackWithArtists>>.broadcast();
  final StreamController<bool> _isPlayingController = StreamController<bool>.broadcast();
  final StreamController<Duration> _positionController = StreamController<Duration>.broadcast();
  final StreamController<Duration> _durationController = StreamController<Duration>.broadcast();
  final StreamController<double> _volumeController = StreamController<double>.broadcast();
  final StreamController<List<String>> _queueCoverArtController = StreamController<List<String>>.broadcast();

  @override
  List<TrackWithArtists> get originalQueue => List.unmodifiable(_originalQueue);

  @override
  List<TrackWithArtists> get currentQueue => List.unmodifiable(_currentQueue);

  @override
  TrackWithArtists? get currentTrack {
    if (_hasOverrideCurrentTrack) return _overrideCurrentTrack;
    return (_currentIndex >= 0 && _currentIndex < _currentQueue.length) ? _currentQueue[_currentIndex] : null;
  }

  @override
  int get currentIndex => _currentIndex;

  @override
  bool get isPlaying => _isPlaying;

  @override
  Duration get position => _position;

  @override
  Duration get duration => _duration;

  @override
  double get volume => _volume;

  @override
  bool get isMuted => _isMuted;

  @override
  bool get isShuffle => _isShuffle;

  @override
  PlaylistMode get loopMode => _loopMode;

  @override
  String get playbackContextType => _playbackContextType;

  @override
  int? get playbackContextId => _playbackContextId;

  @override
  List<String> get currentQueueCoverArt =>
      _currentQueue.map((t) => t.album.albumArtPath).whereType<String>().take(5).toList();

  @override
  Stream<TrackWithArtists?> watchCurrentTrack() => _currentTrackController.stream;

  @override
  Stream<int> watchCurrentIndex() => _currentIndexController.stream;

  @override
  Stream<List<TrackWithArtists>> watchQueue() => _queueController.stream;

  @override
  Stream<bool> watchIsPlaying() => _isPlayingController.stream;

  @override
  Stream<Duration> watchPosition() => _positionController.stream;

  @override
  Stream<Duration> watchDuration() => _durationController.stream;

  @override
  Stream<double> watchVolume() => _volumeController.stream;

  @override
  Stream<List<String>> watchQueueCoverArt() => _queueCoverArtController.stream;

  void emitQueue(List<TrackWithArtists> queue) {
    _currentQueue = List.from(queue);
    _queueController.add(_currentQueue);
  }

  void emitCurrentTrack(TrackWithArtists? track) {
    _overrideCurrentTrack = track;
    _hasOverrideCurrentTrack = true;
    _currentTrackController.add(track);
  }

  void emitCurrentIndex(int index) {
    _currentIndex = index;
    _currentIndexController.add(index);
  }

  void emitIsPlaying(bool playing) {
    _isPlaying = playing;
    _isPlayingController.add(playing);
  }

  @override
  Future<void> setPlaylist({
    required List<TrackWithArtists> tracksToPlay,
    required int initialIndex,
    required String playbackContextType,
    int? playbackContextId,
    bool forceReload = false,
    bool autoplay = true,
  }) async {
    lastTracks = List.from(tracksToPlay);
    lastInitialIndex = initialIndex;
    lastContextType = playbackContextType;
    lastContextId = playbackContextId;

    _currentQueue = List.from(tracksToPlay);
    _originalQueue = List.from(tracksToPlay);
    _currentIndex = initialIndex;
    _playbackContextType = playbackContextType;
    _playbackContextId = playbackContextId;
    if (autoplay) _isPlaying = true;

    _queueController.add(_currentQueue);
    _currentIndexController.add(_currentIndex);
    _currentTrackController.add(currentTrack);
    _isPlayingController.add(_isPlaying);
    _queueCoverArtController.add(currentQueueCoverArt);
  }

  @override
  Future<void> playTrack(List<TrackWithArtists> tracks, int index) async {
    await setPlaylist(tracksToPlay: tracks, initialIndex: index, playbackContextType: 'direct_play');
  }

  @override
  Future<void> play() async {
    _isPlaying = true;
    _isPlayingController.add(true);
  }

  @override
  Future<void> pause() async {
    _isPlaying = false;
    _isPlayingController.add(false);
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
  Future<void> next() async {
    if (_currentIndex < _currentQueue.length - 1) {
      _currentIndex++;
      _currentIndexController.add(_currentIndex);
      _currentTrackController.add(currentTrack);
    }
  }

  @override
  Future<void> previous() async {
    if (_currentIndex > 0) {
      _currentIndex--;
      _currentIndexController.add(_currentIndex);
      _currentTrackController.add(currentTrack);
    }
  }

  @override
  Future<void> jumpToIndex(int index) async {
    jumpedIndex = index;
    if (index >= 0 && index < _currentQueue.length) {
      _currentIndex = index;
      _currentIndexController.add(_currentIndex);
      _currentTrackController.add(currentTrack);
    }
  }

  @override
  Future<void> seek(Duration position) async {
    _position = position;
    _positionController.add(_position);
  }

  @override
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 100.0);
    _volumeController.add(_volume);
  }

  @override
  Future<void> setVolumeUp([double step = 5]) async {
    await setVolume(_volume + step);
  }

  @override
  Future<void> setVolumeDown([double step = 5]) async {
    await setVolume(_volume - step);
  }

  @override
  Future<void> toggleMute() async {
    _isMuted = !_isMuted;
  }

  @override
  Future<void> toggleShuffle() async {
    _isShuffle = !_isShuffle;
  }

  @override
  Future<void> toggleLoop() async {
    final nextMode = switch (_loopMode) {
      PlaylistMode.none => PlaylistMode.single,
      PlaylistMode.single => PlaylistMode.loop,
      PlaylistMode.loop => PlaylistMode.none,
    };
    _loopMode = nextMode;
  }

  @override
  Future<void> addToQueue(List<TrackWithArtists> tracks) async {
    addedToQueueTracks.addAll(tracks);
    _currentQueue.addAll(tracks);
    _queueController.add(_currentQueue);
    _queueCoverArtController.add(currentQueueCoverArt);
  }

  @override
  Future<void> playNext(List<TrackWithArtists> tracks) async {
    final insertIdx = _currentIndex + 1;
    if (insertIdx <= _currentQueue.length) {
      _currentQueue.insertAll(insertIdx, tracks);
    } else {
      _currentQueue.addAll(tracks);
    }
    _queueController.add(_currentQueue);
    _queueCoverArtController.add(currentQueueCoverArt);
  }

  @override
  Future<void> removeQueueItem(int index) async {
    removedIndex = index;
    if (index >= 0 && index < _currentQueue.length) {
      _currentQueue.removeAt(index);
      if (_currentIndex >= _currentQueue.length && _currentQueue.isNotEmpty) {
        _currentIndex = _currentQueue.length - 1;
      }
      _queueController.add(_currentQueue);
      _currentIndexController.add(_currentIndex);
      _currentTrackController.add(currentTrack);
      _queueCoverArtController.add(currentQueueCoverArt);
    }
  }

  @override
  Future<void> removeQueueItems(List<int> indices) async {
    batchRemoved = List.from(indices);
    final sorted = List<int>.from(indices)..sort((a, b) => b.compareTo(a));
    for (final idx in sorted) {
      if (idx >= 0 && idx < _currentQueue.length) {
        _currentQueue.removeAt(idx);
      }
    }
    if (_currentIndex >= _currentQueue.length && _currentQueue.isNotEmpty) {
      _currentIndex = _currentQueue.length - 1;
    }
    _queueController.add(_currentQueue);
    _currentIndexController.add(_currentIndex);
    _currentTrackController.add(currentTrack);
    _queueCoverArtController.add(currentQueueCoverArt);
  }

  @override
  Future<void> reorderQueue(int oldIndex, int newIndex) async {
    moveOld = oldIndex;
    moveNew = newIndex;
    if (oldIndex < _currentQueue.length && newIndex <= _currentQueue.length) {
      var target = newIndex;
      if (oldIndex < target) target -= 1;
      final item = _currentQueue.removeAt(oldIndex);
      _currentQueue.insert(target, item);
      _queueController.add(_currentQueue);
    }
  }

  @override
  Future<void> clearQueue() async {
    cleared = true;
    _currentQueue.clear();
    _originalQueue.clear();
    _currentIndex = -1;
    _isPlaying = false;
    _queueController.add([]);
    _currentIndexController.add(-1);
    _currentTrackController.add(null);
    _isPlayingController.add(false);
    _queueCoverArtController.add([]);
  }

  @override
  Future<void> restoreQueue() async {}

  @override
  void suppressNextScroll() {
    suppressedScroll = true;
    _suppressNextScroll = true;
  }

  @override
  bool consumeSuppressNextScroll() {
    final val = _suppressNextScroll;
    _suppressNextScroll = false;
    return val;
  }

  void dispose() {
    _currentTrackController.close();
    _currentIndexController.close();
    _queueController.close();
    _isPlayingController.close();
    _positionController.close();
    _durationController.close();
    _volumeController.close();
    _queueCoverArtController.close();
  }
}
