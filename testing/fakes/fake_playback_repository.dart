// ignore_for_file: prefer_initializing_formals

import 'dart:async';

import 'package:media_kit/media_kit.dart' hide Track;
import 'package:nordplayer/data/repositories/playback_repository.dart';
import 'package:nordplayer/domain/models/composite_models.dart';
import 'package:nordplayer/domain/models/playback_context.dart';
import 'package:nordplayer/domain/queue/queue_models.dart';
import 'package:nordplayer/utils/string_extension.dart';

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
  PlaybackContext? playbackContext,
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
  PlaybackContext _playbackContext = playbackContext ??
      (playbackContextType.isNotEmpty
          ? PlaybackContext(type: playbackContextType, id: playbackContextId)
          : const PlaybackContext.manual());

  TrackWithArtists? _overrideCurrentTrack;
  bool _hasOverrideCurrentTrack = false;

  // Test inspection fields
  int moveOld = -1;
  int moveNew = -1;
  int removedIndex = -1;
  List<int> batchRemoved = [];
  bool cleared = false;
  int jumpedIndex = -1;
  final List<TrackWithArtists> addedToQueueTracks = [];

  List<TrackWithArtists> lastTracks = [];
  int lastInitialIndex = -1;
  String lastContextType = '';
  int? lastContextId;
  String? lastContextTitle;
  PlaybackContext? lastContext;

  List<TrackWithArtists> get setPlaylistTracks => lastTracks;
  int get setPlaylistIndex => lastInitialIndex;
  String get setPlaylistContextType => lastContextType;
  int? get setPlaylistContextId => lastContextId;
  String? get setPlaylistContextTitle => lastContextTitle;
  PlaybackContext? get setPlaylistContext => lastContext;
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
  final StreamController<QueueState> _queueStateController = StreamController<QueueState>.broadcast();
  final StreamController<List<QueueItem>> _queueItemsController = StreamController<List<QueueItem>>.broadcast();
  final StreamController<PlaybackContext> _playbackContextController =
      StreamController<PlaybackContext>.broadcast();

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
  PlaybackContext get playbackContext => _playbackContext;

  @override
  QueueState get queueState {
    final items = currentQueueItems;
    return QueueState(
      items: items,
      shuffleIndices: List.generate(items.length, (i) => i),
      activeIndex: _currentIndex,
      isShuffle: _isShuffle,
      loopMode: _loopMode.toLoopMode(),
      context: playbackContext,
    );
  }

  @override
  List<QueueItem> get currentQueueItems => [
    for (int i = 0; i < _currentQueue.length; i++)
      QueueItem.create(track: _currentQueue[i], originalOrder: i, source: QueueSource.context),
  ];

  @override
  List<String> get currentQueueCoverArt =>
      _currentQueue.map((t) => t.album.albumArtPath).whereType<String>().take(5).toList();

  @override
  Stream<TrackWithArtists?> watchCurrentTrack() async* {
    yield currentTrack;
    yield* _currentTrackController.stream;
  }

  @override
  Stream<int> watchCurrentIndex() async* {
    yield currentIndex;
    yield* _currentIndexController.stream;
  }

  @override
  Stream<List<TrackWithArtists>> watchQueue() async* {
    yield currentQueue;
    yield* _queueController.stream;
  }

  @override
  Stream<QueueState> watchQueueState() async* {
    yield queueState;
    yield* _queueStateController.stream;
  }

  @override
  Stream<List<QueueItem>> watchQueueItems() async* {
    yield currentQueueItems;
    yield* _queueItemsController.stream;
  }

  @override
  Stream<PlaybackContext> watchPlaybackContext() async* {
    yield playbackContext;
    yield* _playbackContextController.stream;
  }

  @override
  Stream<bool> watchIsPlaying() async* {
    yield isPlaying;
    yield* _isPlayingController.stream;
  }

  @override
  Stream<Duration> watchPosition() async* {
    yield position;
    yield* _positionController.stream;
  }

  @override
  Stream<Duration> watchDuration() async* {
    yield duration;
    yield* _durationController.stream;
  }

  @override
  Stream<double> watchVolume() async* {
    yield volume;
    yield* _volumeController.stream;
  }

  @override
  Stream<List<String>> watchQueueCoverArt() async* {
    yield currentQueueCoverArt;
    yield* _queueCoverArtController.stream;
  }

  void emitQueue(List<TrackWithArtists> queue) {
    _currentQueue = List.from(queue);
    _queueController.add(_currentQueue);
    _queueStateController.add(queueState);
  }

  void emitCurrentTrack(TrackWithArtists? track) {
    _overrideCurrentTrack = track;
    _hasOverrideCurrentTrack = true;
    _currentTrackController.add(track);
    _queueStateController.add(queueState);
  }

  void emitCurrentIndex(int index) {
    _currentIndex = index;
    _currentIndexController.add(index);
    _queueStateController.add(queueState);
  }

  void emitQueueState(QueueState state) {
    _queueStateController.add(state);
  }

  void emitIsPlaying(bool playing) {
    _isPlaying = playing;
    _isPlayingController.add(playing);
  }

  @override
  Future<void> setPlaylist({
    required List<TrackWithArtists> tracksToPlay,
    required int initialIndex,
    PlaybackContext? context,
    String? playbackContextType,
    int? playbackContextId,
    String? playbackContextTitle,
    bool forceReload = false,
    bool autoplay = true,
  }) async {
    final resolvedContext = context ??
        switch ((playbackContextType ?? 'manual').toLowerCase()) {
          'album' => PlaybackContext.album(id: playbackContextId ?? 0, title: playbackContextTitle ?? ''),
          'playlist' => PlaybackContext.playlist(id: playbackContextId ?? 0, title: playbackContextTitle ?? ''),
          'all' || 'tracks' || 'library' || 'all_tracks' => const PlaybackContext.allTracks(),
          'search' => PlaybackContext.search(query: playbackContextTitle ?? ''),
          'manual' => const PlaybackContext.manual(),
          _ => PlaybackContext(type: playbackContextType ?? 'manual', id: playbackContextId, title: playbackContextTitle),
        };

    lastTracks = List.from(tracksToPlay);
    lastInitialIndex = initialIndex;
    lastContextType = resolvedContext.type;
    lastContextId = resolvedContext.id;
    lastContextTitle = resolvedContext.title;
    lastContext = resolvedContext;

    _currentQueue = List.from(tracksToPlay);
    _originalQueue = List.from(tracksToPlay);
    _currentIndex = initialIndex;
    _playbackContextType = resolvedContext.type;
    _playbackContextId = resolvedContext.id;
    _playbackContext = resolvedContext;
    if (autoplay) _isPlaying = true;

    _queueController.add(_currentQueue);
    _currentIndexController.add(_currentIndex);
    _currentTrackController.add(currentTrack);
    _isPlayingController.add(_isPlaying);
    _queueCoverArtController.add(currentQueueCoverArt);
    _playbackContextController.add(_playbackContext);
    _queueStateController.add(queueState);
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
  Future<void> removeTrackByPath(String filePath) async {
    final normalized = filePath.normalizePath().toLowerCase();
    _currentQueue.removeWhere((t) => t.track.filePath.normalizePath().toLowerCase() == normalized);
    if (_currentIndex >= _currentQueue.length && _currentQueue.isNotEmpty) {
      _currentIndex = _currentQueue.length - 1;
    }
    _queueController.add(_currentQueue);
    _currentIndexController.add(_currentIndex);
    _currentTrackController.add(currentTrack);
    _queueCoverArtController.add(currentQueueCoverArt);
  }

  @override
  Future<void> removeTracksByPaths(Set<String> filePaths) async {
    final normalized = filePaths.map((p) => p.normalizePath().toLowerCase()).toSet();
    _currentQueue.removeWhere((t) => normalized.contains(t.track.filePath.normalizePath().toLowerCase()));
    if (_currentIndex >= _currentQueue.length && _currentQueue.isNotEmpty) {
      _currentIndex = _currentQueue.length - 1;
    }
    _queueController.add(_currentQueue);
    _currentIndexController.add(_currentIndex);
    _currentTrackController.add(currentTrack);
    _queueCoverArtController.add(currentQueueCoverArt);
  }

  @override
  Future<void> sortBy(QueueSortCriteria criteria, {bool ascending = true}) async {
    _currentQueue.sort((a, b) {
      final res = switch (criteria) {
        QueueSortCriteria.title => a.track.title.toLowerCase().compareTo(b.track.title.toLowerCase()),
        QueueSortCriteria.artist => (a.artists.firstOrNull?.name ?? '').toLowerCase().compareTo(
          (b.artists.firstOrNull?.name ?? '').toLowerCase(),
        ),
        QueueSortCriteria.album => a.album.title.toLowerCase().compareTo(b.album.title.toLowerCase()),
        QueueSortCriteria.duration => a.track.durationMs.compareTo(b.track.durationMs),
        QueueSortCriteria.originalOrder => 0,
      };
      return ascending ? res : -res;
    });
    _queueController.add(_currentQueue);
    _currentTrackController.add(currentTrack);
  }

  @override
  Future<void> revertSort() async {
    _currentQueue = List.from(_originalQueue);
    _queueController.add(_currentQueue);
    _currentTrackController.add(currentTrack);
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
    _queueStateController.close();
    _queueItemsController.close();
  }
}
