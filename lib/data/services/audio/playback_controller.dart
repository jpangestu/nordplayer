import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart' hide Track;
import 'package:nordplayer/data/repositories/queue_repository.dart';
import 'package:nordplayer/data/services/audio/audio_handler.dart';
import 'package:nordplayer/data/services/audio/audio_player_engine.dart';
import 'package:nordplayer/data/services/audio/volume_controller.dart';
import 'package:nordplayer/domain/models/composite_models.dart';
import 'package:nordplayer/domain/models/playback_context.dart';
import 'package:nordplayer/domain/queue/queue_manager.dart';
import 'package:nordplayer/domain/queue/queue_models.dart';
import 'package:nordplayer/utils/debouncer.dart';
import 'package:nordplayer/utils/logger.dart';

/// Conversion extension between media_kit [PlaylistMode] and domain [LoopMode].
extension LoopModeConversion on PlaylistMode {
  LoopMode toLoopMode() => switch (this) {
    PlaylistMode.none => LoopMode.off,
    PlaylistMode.single => LoopMode.single,
    PlaylistMode.loop => LoopMode.all,
  };
}

/// Conversion extension between domain [LoopMode] and media_kit [PlaylistMode].
extension PlaylistModeConversion on LoopMode {
  PlaylistMode toPlaylistMode() => switch (this) {
    LoopMode.off => PlaylistMode.none,
    LoopMode.single => PlaylistMode.single,
    LoopMode.all => PlaylistMode.loop,
  };
}

/// Controller interface abstracting active playback session, queue sequencing,
/// transport actions, shuffle/loop state, and persistent queue synchronization.
abstract interface class PlaybackController {
  List<TrackWithArtists> get originalQueue;
  List<TrackWithArtists> get currentQueue;
  TrackWithArtists? get currentTrack;
  int get currentIndex;
  bool get isPlaying;
  Duration get position;
  Duration get duration;
  double get volume;
  bool get isMuted;
  bool get isShuffle;
  PlaylistMode get loopMode;
  String get playbackContextType;
  int? get playbackContextId;
  PlaybackContext get playbackContext;

  QueueState get queueState;
  List<QueueItem> get currentQueueItems;

  Stream<TrackWithArtists?> watchCurrentTrack();
  Stream<int> watchCurrentIndex();
  Stream<List<TrackWithArtists>> watchQueue();
  Stream<bool> watchIsPlaying();
  Stream<Duration> watchPosition();
  Stream<Duration> watchDuration();
  Stream<double> watchVolume();
  Stream<bool> watchIsMuted();
  List<String> get currentQueueCoverArt;
  Stream<List<String>> watchQueueCoverArt();

  Stream<QueueState> watchQueueState();
  Stream<List<QueueItem>> watchQueueItems();
  Stream<PlaybackContext> watchPlaybackContext();

  Future<void> setPlaylist({
    required List<TrackWithArtists> tracksToPlay,
    required int initialIndex,
    PlaybackContext? context,
    String? playbackContextType,
    int? playbackContextId,
    String? playbackContextTitle,
    bool forceReload = false,
    bool autoplay = true,
  });

  Future<void> playTrack(List<TrackWithArtists> tracks, int index);
  Future<void> play();
  Future<void> pause();
  Future<void> playOrPause();
  Future<void> next();
  Future<void> previous();
  Future<void> jumpToIndex(int index);
  Future<void> seek(Duration position);
  Future<void> setVolume(double volume);
  Future<void> setVolumeUp([double step = 5]);
  Future<void> setVolumeDown([double step = 5]);
  Future<void> toggleMute();
  Future<void> toggleShuffle();
  Future<void> setShuffle(bool enable);
  Future<void> toggleLoop();
  Future<void> addToQueue(List<TrackWithArtists> tracks);
  Future<void> playNext(List<TrackWithArtists> tracks);
  Future<void> removeQueueItem(int index);
  Future<void> removeQueueItems(List<int> indices);
  Future<void> removeTrackByPath(String filePath);
  Future<void> removeTracksByPaths(Set<String> filePaths);
  Future<void> reorderQueue(int oldIndex, int newIndex);
  Future<void> sortBy(QueueSortCriteria criteria, {bool ascending = true});
  Future<void> revertSort();
  Future<void> clearQueue();
  Future<void> restoreQueue();
}

/// Default implementation of [PlaybackController] coordinating [QueueManager],
/// [AudioPlayerEngine], [VolumeController], and persistent [QueueRepository].
class DefaultPlaybackController(
  final AudioPlayerEngine _playerEngine,
  final QueueRepository _queueRepository, {
  QueueManager? queueManager,
  VolumeController? volumeController,
}) with LoggerMixin implements PlaybackController {
  final QueueManager _queueManager = queueManager ?? QueueManager();
  final VolumeController _volumeController =
      volumeController ?? VolumeController(_playerEngine, _queueRepository, persistDebounce: Duration.zero);
  String _playbackContextType = '';
  int? _playbackContextId;
  bool _isRestoringQueue = false;
  DateTime? _lastPositionSaveTime;

  final Debouncer _queueSaveDebouncer = Debouncer(const Duration(seconds: 1));
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  final StreamController<QueueState> _queueStateController = StreamController<QueueState>.broadcast();

  this {
    _init();
  }

  void _init() {
    // 1. Transport gapless transition & playback completed
    _subscriptions.add(
      _playerEngine.completedStream.listen((_) async {
        final currentEngineUri = _playerEngine.currentUri;
        final nextItem = _queueManager.advanceNext();
        _emitQueueState();

        if (nextItem == null) {
          await _playerEngine.pause();
          return;
        }

        final targetFilePath = nextItem.track.track.filePath;
        final isSeamless = currentEngineUri == targetFilePath && _playerEngine.isPlaying;

        if (isSeamless) {
          // Seamless gapless transition occurred via rolling window; pre-buffer upcoming track
          await _playerEngine.setNextMedia(_queueManager.nextTrackFilePath);
        } else {
          // Non-seamless (e.g. wrapped around, natural completion in loop single, or restarted)
          await _playerEngine.open(targetFilePath, autoplay: true);
          await _playerEngine.setNextMedia(_queueManager.nextTrackFilePath);
        }

        _queueRepository.updateActiveTrack(
          currentIndex,
          currentTrack?.track.filePath,
          activeTrackId: currentTrack?.track.id,
        );
      }),
    );

    // 2. Position stream updates & periodic persistence
    _subscriptions.add(
      _playerEngine.positionStream.listen((pos) {
        if (_isRestoringQueue) return;

        final now = DateTime.now();
        if (_lastPositionSaveTime == null || now.difference(_lastPositionSaveTime!) >= const Duration(seconds: 5)) {
          _lastPositionSaveTime = now;
          _queueRepository.updateCurrentPosition(pos.inMilliseconds);
        }
      }),
    );

    // 3. Playback engine error notifications
    _subscriptions.add(
      _playerEngine.errorStream.listen((error) {
        log.e('AudioPlayerEngine playback error: $error');
      }),
    );
  }

  void _emitQueueState() {
    _queueStateController.add(queueState);
  }

  PlaybackContext _resolvePlaybackContext(String type, int? id, {String? title}) {
    return switch (type.toLowerCase()) {
      'album' => PlaybackContext.album(id: id ?? 0, title: title ?? ''),
      'playlist' => PlaybackContext.playlist(id: id ?? 0, title: title ?? ''),
      'all' || 'tracks' || 'library' || 'all_tracks' => const PlaybackContext.allTracks(),
      'search' => PlaybackContext.search(query: title ?? ''),
      'manual' => const PlaybackContext.manual(),
      _ => PlaybackContext(type: type, id: id, title: title),
    };
  }

  @override
  List<TrackWithArtists> get originalQueue => List.unmodifiable(_queueManager.rawItems.map((item) => item.track));

  @override
  List<TrackWithArtists> get currentQueue => _queueManager.displayTracks;

  @override
  TrackWithArtists? get currentTrack => _queueManager.currentTrack;

  @override
  int get currentIndex => _queueManager.activeIndex;

  @override
  QueueState get queueState => _queueManager.state;

  @override
  List<QueueItem> get currentQueueItems => _queueManager.displayQueue;

  @override
  List<String> get currentQueueCoverArt => _queueManager.upcomingCoverArts;

  @override
  PlaybackContext get playbackContext => _queueManager.context;

  @override
  bool get isPlaying => _playerEngine.isPlaying;

  @override
  Duration get position => _playerEngine.position;

  @override
  Duration get duration => _playerEngine.duration;

  @override
  double get volume => _volumeController.volume;

  @override
  bool get isMuted => _volumeController.isMuted;

  @override
  bool get isShuffle => _queueManager.isShuffle;

  @override
  PlaylistMode get loopMode => _queueManager.loopMode.toPlaylistMode();

  @override
  String get playbackContextType => _playbackContextType;

  @override
  int? get playbackContextId => _playbackContextId;

  @override
  Stream<QueueState> watchQueueState() async* {
    yield queueState;
    yield* _queueStateController.stream;
  }

  @override
  Stream<TrackWithArtists?> watchCurrentTrack() {
    return watchQueueState().map((s) => s.currentItem?.track).distinct();
  }

  @override
  Stream<int> watchCurrentIndex() {
    return watchQueueState().map((s) => s.activeIndex).distinct();
  }

  @override
  Stream<List<TrackWithArtists>> watchQueue() {
    return watchQueueState().map((s) => s.tracks).distinct(listEquals);
  }

  @override
  Stream<List<String>> watchQueueCoverArt() {
    return watchQueueState().map((s) => s.upcomingCoverArts).distinct(listEquals);
  }

  @override
  Stream<List<QueueItem>> watchQueueItems() {
    return watchQueueState().map((s) => s.displayQueue).distinct(listEquals);
  }

  @override
  Stream<PlaybackContext> watchPlaybackContext() {
    return watchQueueState().map((s) => s.context).distinct();
  }

  @override
  Stream<bool> watchIsPlaying() async* {
    yield isPlaying;
    yield* _playerEngine.isPlayingStream;
  }

  @override
  Stream<Duration> watchPosition() async* {
    yield position;
    yield* _playerEngine.positionStream;
  }

  @override
  Stream<Duration> watchDuration() async* {
    yield duration;
    yield* _playerEngine.durationStream;
  }

  @override
  Stream<double> watchVolume() => _volumeController.watchVolume();

  @override
  Stream<bool> watchIsMuted() => _volumeController.watchIsMuted();

  @override
  Future<void> playTrack(List<TrackWithArtists> tracks, int index) async {
    await setPlaylist(tracksToPlay: tracks, initialIndex: index, playbackContextType: 'tracks', forceReload: true);
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
    final resolvedContext =
        context ?? _resolvePlaybackContext(playbackContextType ?? '', playbackContextId, title: playbackContextTitle);

    _playbackContextType = resolvedContext.type;
    _playbackContextId = resolvedContext.id;

    _queueManager.setQueue(tracksToPlay, initialIndex: initialIndex, context: resolvedContext);
    _emitQueueState();

    await _playCurrentAndPreBufferNext(autoplay: autoplay, startPosition: Duration.zero);
    _queueSaveDebouncer(() => _saveQueueState());
  }

  @override
  Future<void> play() => _playerEngine.play();

  @override
  Future<void> pause() => _playerEngine.pause();

  @override
  Future<void> playOrPause() => _playerEngine.playOrPause();

  @override
  Future<void> next() async {
    final nextItem = _queueManager.advanceNext();
    _emitQueueState();
    if (nextItem != null) {
      await _playCurrentAndPreBufferNext();
    } else {
      _queueRepository.updateActiveTrack(
        currentIndex,
        currentTrack?.track.filePath,
        activeTrackId: currentTrack?.track.id,
      );
    }
  }

  @override
  Future<void> previous() async {
    final prevItem = _queueManager.stepPrevious(currentPosition: position);
    _emitQueueState();
    if (prevItem != null) {
      await _playCurrentAndPreBufferNext();
    } else {
      _queueRepository.updateActiveTrack(
        currentIndex,
        currentTrack?.track.filePath,
        activeTrackId: currentTrack?.track.id,
      );
    }
  }

  @override
  Future<void> jumpToIndex(int index) async {
    if (index >= 0 && index < _queueManager.displayQueue.length) {
      _queueManager.jumpTo(index);
      _emitQueueState();
      await _playCurrentAndPreBufferNext();
    }
  }

  @override
  Future<void> seek(Duration position) async {
    await _playerEngine.seek(position);
    _queueRepository.updateCurrentPosition(position.inMilliseconds);
  }

  @override
  Future<void> setVolume(double volume) => _volumeController.setVolume(volume);

  @override
  Future<void> setVolumeUp([double step = 5]) => _volumeController.setVolumeUp(step);

  @override
  Future<void> setVolumeDown([double step = 5]) => _volumeController.setVolumeDown(step);

  @override
  Future<void> toggleMute() => _volumeController.toggleMute();

  @override
  Future<void> toggleShuffle() async {
    _queueManager.toggleShuffle();
    await _playerEngine.setNextMedia(_queueManager.nextTrackFilePath);
    _emitQueueState();
    _queueRepository.updateShuffleMode(
      isShuffle: _queueManager.isShuffle,
      shuffleIndices: _queueManager.state.shuffleIndices,
      activeIndex: currentIndex,
      activeTrackPath: currentTrack?.track.filePath,
      activeTrackId: currentTrack?.track.id,
    );
  }

  @override
  Future<void> setShuffle(bool enable) async {
    if (_queueManager.isShuffle == enable) return;
    await toggleShuffle();
  }

  @override
  Future<void> toggleLoop() async {
    final nextMode = switch (loopMode) {
      PlaylistMode.none => PlaylistMode.single,
      PlaylistMode.single => PlaylistMode.loop,
      PlaylistMode.loop => PlaylistMode.none,
    };
    _queueManager.setLoopMode(nextMode.toLoopMode());
    await _playerEngine.setNextMedia(_queueManager.nextTrackFilePath);
    _emitQueueState();
    _queueRepository.updateLoopMode(nextMode.toLoopMode().name);
  }

  @override
  Future<void> addToQueue(List<TrackWithArtists> tracks) async {
    if (tracks.isEmpty) return;
    _queueManager.addToQueue(tracks);
    await _notifyQueueModified();
  }

  @override
  Future<void> playNext(List<TrackWithArtists> tracks) async {
    if (tracks.isEmpty) return;
    _queueManager.playNext(tracks);
    await _notifyQueueModified();
  }

  @override
  Future<void> removeQueueItem(int index) async {
    if (index < 0 || index >= _queueManager.displayQueue.length) return;
    final prevTrack = currentTrack?.track.filePath;
    _queueManager.removeAt(index);
    await _handlePostQueueModification(previousActivePath: prevTrack);
  }

  @override
  Future<void> removeQueueItems(List<int> indices) async {
    final prevTrack = currentTrack?.track.filePath;
    _queueManager.removeIndices(indices);
    await _handlePostQueueModification(previousActivePath: prevTrack);
  }

  @override
  Future<void> removeTrackByPath(String filePath) async {
    final prevTrack = currentTrack?.track.filePath;
    _queueManager.removeTrackByPath(filePath);
    await _handlePostQueueModification(previousActivePath: prevTrack);
  }

  @override
  Future<void> removeTracksByPaths(Set<String> filePaths) async {
    final prevTrack = currentTrack?.track.filePath;
    _queueManager.removeTracksByPaths(filePaths);
    await _handlePostQueueModification(previousActivePath: prevTrack);
  }

  @override
  Future<void> reorderQueue(int oldIndex, int newIndex) async {
    _queueManager.reorder(oldIndex, newIndex);
    await _notifyQueueModified();
  }

  @override
  Future<void> sortBy(QueueSortCriteria criteria, {bool ascending = true}) async {
    _queueManager.sortBy(criteria, ascending: ascending);
    await _notifyQueueModified();
  }

  @override
  Future<void> revertSort() async {
    _queueManager.revertSort();
    await _notifyQueueModified();
  }

  @override
  Future<void> clearQueue() async {
    await _playerEngine.pause();
    await _playerEngine.setNextMedia(null);
    _queueManager.clear();
    _emitQueueState();
    await _queueRepository.saveQueueState(_queueManager.state, Duration.zero);
  }

  @override
  Future<void> restoreQueue() async {
    _isRestoringQueue = true;
    try {
      final restored = await _queueRepository.restoreQueueState();
      if (restored != null) {
        await _volumeController.initialize(volume: restored.volume, isMuted: restored.isMuted);

        if (restored.state.items.isNotEmpty) {
          _playbackContextType = restored.state.context.type;
          _playbackContextId = restored.state.context.id;

          _queueManager.restoreFromState(restored.state);
          _emitQueueState();

          await _playCurrentAndPreBufferNext(
            autoplay: false,
            startPosition: restored.resumePosition,
            updatePersistence: false,
          );
        }
      }
    } finally {
      _isRestoringQueue = false;
    }
  }

  Future<void> _handlePostQueueModification({required String? previousActivePath}) async {
    if (_queueManager.isEmpty) {
      await _playerEngine.pause();
      await _playerEngine.setNextMedia(null);
    } else {
      final current = _queueManager.currentTrack;
      if (current != null && current.track.filePath != previousActivePath) {
        await _playerEngine.open(current.track.filePath, autoplay: _playerEngine.isPlaying);
      }
      await _notifyQueueModified();
    }
  }

  Future<void> _playCurrentAndPreBufferNext({
    bool autoplay = true,
    Duration? startPosition,
    bool updatePersistence = true,
  }) async {
    final current = _queueManager.currentTrack;
    if (current != null) {
      await _playerEngine.open(current.track.filePath, autoplay: autoplay, startPosition: startPosition);
      await _playerEngine.setNextMedia(_queueManager.nextTrackFilePath);
    }
    if (updatePersistence) {
      _queueRepository.updateActiveTrack(
        currentIndex,
        currentTrack?.track.filePath,
        activeTrackId: currentTrack?.track.id,
      );
    }
  }

  Future<void> _notifyQueueModified() async {
    await _playerEngine.setNextMedia(_queueManager.nextTrackFilePath);
    _emitQueueState();
    _queueSaveDebouncer(() => _saveQueueState());
  }

  void _saveQueueState() {
    if (_isRestoringQueue) return;
    _queueRepository.saveQueueState(queueState, position);
  }

  void dispose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _queueSaveDebouncer.flush();
    _queueSaveDebouncer.dispose();
    _queueStateController.close();
  }
}

/// Riverpod provider for [PlaybackController].
final playbackControllerProvider = Provider<PlaybackController>((ref) {
  final playerEngine = ref.watch(audioPlayerEngineProvider);
  final queueRepo = ref.watch(queueRepositoryProvider);
  final volumeController = ref.watch(volumeControllerProvider);

  final controller = DefaultPlaybackController(playerEngine, queueRepo, volumeController: volumeController);
  final audioHandler = ref.watch(audioHandlerProvider);
  if (audioHandler != null) {
    audioHandler.attachController(controller);
  }

  ref.onDispose(controller.dispose);
  return controller;
});
