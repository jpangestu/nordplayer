import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart' hide Track;
import 'package:nordplayer/data/repositories/queue_repository.dart';
import 'package:nordplayer/data/repositories/settings_repository.dart';
import 'package:nordplayer/data/services/audio/audio_handler.dart';
import 'package:nordplayer/data/services/audio/audio_player_engine.dart';
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

/// Repository interface abstracting active playback session, queue sequencing,
/// shuffle/loop state, and persistent queue synchronization.
abstract interface class PlaybackRepository {
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

/// Default implementation of [PlaybackRepository] coordinating [QueueManager] and [AudioPlayerEngine]
/// with non-destructive shuffle, in-memory sorting, gapless transitions, and persistence.
class DefaultPlaybackRepository(
  final AudioPlayerEngine _playerEngine,
  final QueueRepository _queueRepository,
  final SettingsRepository _settingsRepository, {
  QueueManager? queueManager,
}) with LoggerMixin implements PlaybackRepository {
  final QueueManager _queueManager = queueManager ?? QueueManager();
  String _playbackContextType = '';
  int? _playbackContextId;
  bool _isRestoringQueue = false;
  DateTime? _lastPositionSaveTime;

  final Debouncer _queueSaveDebouncer = Debouncer(const Duration(seconds: 1));
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  final StreamController<TrackWithArtists?> _currentTrackController = StreamController<TrackWithArtists?>.broadcast();
  final StreamController<List<TrackWithArtists>> _queueController =
      StreamController<List<TrackWithArtists>>.broadcast();
  final StreamController<int> _currentIndexController = StreamController<int>.broadcast();
  final StreamController<List<String>> _queueCoverArtController = StreamController<List<String>>.broadcast();
  final StreamController<QueueState> _queueStateController = StreamController<QueueState>.broadcast();
  final StreamController<List<QueueItem>> _queueItemsController = StreamController<List<QueueItem>>.broadcast();
  final StreamController<PlaybackContext> _playbackContextController =
      StreamController<PlaybackContext>.broadcast();

  this {
    _init();
  }

  void _init() {
    // 1. Initial settings sync
    final initialSettings = _settingsRepository.currentSettings;
    if (initialSettings.shuffleMode) {
      _queueManager.setShuffle(true);
    }
    _queueManager.setLoopMode(initialSettings.loopMode.toLoopMode());

    // 2. Transport gapless transition & playback completed
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

    // 3. Position stream updates & periodic persistence
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

    // 4. Settings changes sync
    _subscriptions.add(
      _settingsRepository.watchSettings().listen((settings) async {
        bool changed = false;
        if (settings.shuffleMode != _queueManager.isShuffle) {
          _queueManager.toggleShuffle();
          _queueRepository.updateShuffleMode(
            isShuffle: _queueManager.isShuffle,
            shuffleIndices: _queueManager.state.shuffleIndices,
            activeIndex: currentIndex,
            activeTrackPath: currentTrack?.track.filePath,
            activeTrackId: currentTrack?.track.id,
          );
          changed = true;
        }
        final targetLoop = settings.loopMode.toLoopMode();
        if (targetLoop != _queueManager.loopMode) {
          _queueManager.setLoopMode(targetLoop);
          _queueRepository.updateLoopMode(targetLoop.name);
          changed = true;
        }
        if (changed) {
          await _playerEngine.setNextMedia(_queueManager.nextTrackFilePath);
          _emitQueueState();
        }
      }),
    );
  }

  void _emitQueueState() {
    _currentTrackController.add(currentTrack);
    _queueController.add(currentQueue);
    _currentIndexController.add(currentIndex);
    _queueCoverArtController.add(currentQueueCoverArt);
    _queueStateController.add(queueState);
    _queueItemsController.add(currentQueueItems);
    _playbackContextController.add(playbackContext);
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
  int get currentIndex => _queueManager.currentIndex;

  @override
  List<String> get currentQueueCoverArt => _queueManager.upcomingCoverArts;

  @override
  QueueState get queueState => _queueManager.state;

  @override
  List<QueueItem> get currentQueueItems => _queueManager.displayQueue;

  @override
  PlaybackContext get playbackContext => _queueManager.context;

  @override
  bool get isPlaying => _playerEngine.isPlaying;

  @override
  Duration get position => _playerEngine.position;

  @override
  Duration get duration => _playerEngine.duration;

  @override
  double get volume => _playerEngine.volume;

  @override
  bool get isMuted => _settingsRepository.currentSettings.isMuted;

  @override
  bool get isShuffle => _queueManager.isShuffle;

  @override
  PlaylistMode get loopMode => _queueManager.loopMode.toPlaylistMode();

  @override
  String get playbackContextType => _playbackContextType;

  @override
  int? get playbackContextId => _playbackContextId;

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
  Stream<List<String>> watchQueueCoverArt() async* {
    yield currentQueueCoverArt;
    yield* _queueCoverArtController.stream;
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
  Stream<double> watchVolume() async* {
    yield volume;
    yield* _playerEngine.volumeStream;
  }

  @override
  Future<void> playTrack(List<TrackWithArtists> tracks, int index) async {
    await setPlaylist(tracksToPlay: tracks, initialIndex: index, playbackContextType: 'direct');
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
    if (tracksToPlay.isEmpty) return;

    final resolvedContext = context ??
        _resolvePlaybackContext(
          playbackContextType ?? 'manual',
          playbackContextId,
          title: playbackContextTitle,
        );

    _playbackContextType = resolvedContext.type;
    _playbackContextId = resolvedContext.id;

    _queueManager.setQueue(tracksToPlay, initialIndex: initialIndex, context: resolvedContext, shuffle: isShuffle);
    _queueManager.setLoopMode(loopMode.toLoopMode());

    _emitQueueState();

    final current = _queueManager.currentTrack;
    if (current != null) {
      await _playerEngine.open(current.track.filePath, autoplay: autoplay);
      await _playerEngine.setNextMedia(_queueManager.nextTrackFilePath);
    }

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
      await _playerEngine.open(nextItem.track.track.filePath, autoplay: true);
      await _playerEngine.setNextMedia(_queueManager.nextTrackFilePath);
    }
    _queueRepository.updateActiveTrack(
      currentIndex,
      currentTrack?.track.filePath,
      activeTrackId: currentTrack?.track.id,
    );
  }

  @override
  Future<void> previous() async {
    final prevItem = _queueManager.stepPrevious(currentPosition: position);
    _emitQueueState();
    if (prevItem != null) {
      await _playerEngine.open(prevItem.track.track.filePath, autoplay: true);
      await _playerEngine.setNextMedia(_queueManager.nextTrackFilePath);
    }
    _queueRepository.updateActiveTrack(
      currentIndex,
      currentTrack?.track.filePath,
      activeTrackId: currentTrack?.track.id,
    );
  }

  @override
  Future<void> jumpToIndex(int index) async {
    if (index >= 0 && index < _queueManager.displayQueue.length) {
      _queueManager.jumpTo(index);
      _emitQueueState();
      final current = _queueManager.currentTrack;
      if (current != null) {
        await _playerEngine.open(current.track.filePath, autoplay: true);
        await _playerEngine.setNextMedia(_queueManager.nextTrackFilePath);
      }
      _queueRepository.updateActiveTrack(
        currentIndex,
        currentTrack?.track.filePath,
        activeTrackId: currentTrack?.track.id,
      );
    }
  }

  @override
  Future<void> seek(Duration position) async {
    await _playerEngine.seek(position);
    _queueRepository.updateCurrentPosition(position.inMilliseconds);
  }

  @override
  Future<void> setVolume(double volume) async {
    await _playerEngine.setVolume(volume);
    _settingsRepository.setVolume(volume);
  }

  @override
  Future<void> setVolumeUp([double step = 5]) async {
    final current = _settingsRepository.currentSettings.volume;
    final next = (current + step).clamp(0.0, 100.0);
    await _settingsRepository.setIsMuted(false);
    await setVolume(next);
  }

  @override
  Future<void> setVolumeDown([double step = 5]) async {
    final current = _settingsRepository.currentSettings.volume;
    final next = (current - step).clamp(0.0, 100.0);
    if (next == 0) {
      await _settingsRepository.setIsMuted(true);
    }
    await setVolume(next);
  }

  @override
  Future<void> toggleMute() async {
    final nextMute = !isMuted;
    await _settingsRepository.setIsMuted(nextMute);
    await _playerEngine.setVolume(nextMute ? 0.0 : _settingsRepository.currentSettings.volume);
  }

  @override
  Future<void> toggleShuffle() async {
    _queueManager.toggleShuffle();
    await _settingsRepository.setShuffleMode(_queueManager.isShuffle);
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
  Future<void> toggleLoop() async {
    final nextMode = switch (loopMode) {
      PlaylistMode.none => PlaylistMode.single,
      PlaylistMode.single => PlaylistMode.loop,
      PlaylistMode.loop => PlaylistMode.none,
    };
    await _settingsRepository.setLoopMode(nextMode);
    _queueManager.setLoopMode(nextMode.toLoopMode());
    await _playerEngine.setNextMedia(_queueManager.nextTrackFilePath);
    _emitQueueState();
    _queueRepository.updateLoopMode(nextMode.toLoopMode().name);
  }

  @override
  Future<void> addToQueue(List<TrackWithArtists> tracks) async {
    if (tracks.isEmpty) return;
    _queueManager.addToQueue(tracks);
    await _playerEngine.setNextMedia(_queueManager.nextTrackFilePath);
    _emitQueueState();
    _queueSaveDebouncer(() => _saveQueueState());
  }

  @override
  Future<void> playNext(List<TrackWithArtists> tracks) async {
    if (tracks.isEmpty) return;
    _queueManager.playNext(tracks);
    await _playerEngine.setNextMedia(_queueManager.nextTrackFilePath);
    _emitQueueState();
    _queueSaveDebouncer(() => _saveQueueState());
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
    await _playerEngine.setNextMedia(_queueManager.nextTrackFilePath);
    _emitQueueState();
    _queueSaveDebouncer(() => _saveQueueState());
  }

  @override
  Future<void> sortBy(QueueSortCriteria criteria, {bool ascending = true}) async {
    _queueManager.sortBy(criteria, ascending: ascending);
    await _playerEngine.setNextMedia(_queueManager.nextTrackFilePath);
    _emitQueueState();
    _queueSaveDebouncer(() => _saveQueueState());
  }

  @override
  Future<void> revertSort() async {
    _queueManager.revertSort();
    await _playerEngine.setNextMedia(_queueManager.nextTrackFilePath);
    _emitQueueState();
    _queueSaveDebouncer(() => _saveQueueState());
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
      if (restored != null && restored.state.items.isNotEmpty) {
        _playbackContextType = restored.state.context.type;
        _playbackContextId = restored.state.context.id;

        _queueManager.restoreFromState(restored.state);
        _emitQueueState();

        final current = _queueManager.currentTrack;
        if (current != null) {
          await _playerEngine.open(current.track.filePath, startPosition: restored.resumePosition, autoplay: false);
          await _playerEngine.setNextMedia(_queueManager.nextTrackFilePath);
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
      await _playerEngine.setNextMedia(_queueManager.nextTrackFilePath);
    }
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
    _currentTrackController.close();
    _currentIndexController.close();
    _queueController.close();
    _queueCoverArtController.close();
    _queueStateController.close();
    _queueItemsController.close();
    _playbackContextController.close();
  }
}

/// Riverpod provider for [PlaybackRepository].
final playbackRepositoryProvider = Provider<PlaybackRepository>((ref) {
  final playerEngine = ref.watch(audioPlayerEngineProvider);
  final queueRepo = ref.watch(queueRepositoryProvider);
  final settingsRepo = ref.watch(settingsRepositoryProvider);

  final repo = DefaultPlaybackRepository(playerEngine, queueRepo, settingsRepo);
  final audioHandler = ref.watch(audioHandlerProvider);
  if (audioHandler != null) {
    audioHandler.attachRepository(repo);
  }

  ref.onDispose(repo.dispose);
  return repo;
});
