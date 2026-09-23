import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart' hide Track;
import 'package:nordplayer/ui/queue/queue_scroll_behavior.dart';
import 'package:nordplayer/utils/logger.dart';
import 'package:nordplayer/utils/debouncer.dart';
import 'package:nordplayer/data/repositories/queue_repository.dart';
import 'package:nordplayer/data/repositories/settings_repository.dart';
import 'package:nordplayer/domain/models/models.dart' hide Playlist;
import 'package:nordplayer/data/services/audio/audio_player_service.dart';

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

  Stream<TrackWithArtists?> watchCurrentTrack();
  Stream<int> watchCurrentIndex();
  Stream<List<TrackWithArtists>> watchQueue();
  Stream<bool> watchIsPlaying();
  Stream<Duration> watchPosition();
  Stream<Duration> watchDuration();
  Stream<double> watchVolume();

  Future<void> setPlaylist({
    required List<TrackWithArtists> tracksToPlay,
    required int initialIndex,
    required String playbackContextType,
    int? playbackContextId,
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
  Future<void> reorderQueue(int oldIndex, int newIndex);
  Future<void> clearQueue();
  Future<void> restoreQueue();
  void suppressNextScroll();
  bool consumeSuppressNextScroll();
}

/// Default implementation of [PlaybackRepository] coordinating [AudioPlayerService],
/// [QueueRepository], and [SettingsRepository].
class DefaultPlaybackRepository(
  final AudioPlayerService _playerService,
  final QueueRepository _queueRepository,
  final SettingsRepository _settingsRepository,
  final Ref _ref,
) with LoggerMixin implements PlaybackRepository {
  List<TrackWithArtists> _originalQueue = [];
  String _playbackContextType = '';
  int? _playbackContextId;
  bool _isRestoringQueue = false;
  bool _shouldSuppressNextScroll = false;
  DateTime? _lastPositionSaveTime;

  final Debouncer _queueSaveDebouncer = Debouncer(const Duration(seconds: 1));
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  final StreamController<TrackWithArtists?> _currentTrackController = StreamController<TrackWithArtists?>.broadcast();
  final StreamController<List<TrackWithArtists>> _queueController =
      StreamController<List<TrackWithArtists>>.broadcast();
  final StreamController<int> _currentIndexController = StreamController<int>.broadcast();

  this {
    _init();
  }

  void _init() {
    // Listen to player playlist changes
    _subscriptions.add(
      _playerService.playlistStream.listen((playlist) {
        final current = currentTrack;
        _currentTrackController.add(current);
        _queueController.add(currentQueue);
        _currentIndexController.add(playlist.index);

        if (_isRestoringQueue || playlist.medias.isEmpty) return;
        _queueSaveDebouncer(() => _saveQueueState(newIndex: playlist.index));
      }),
    );

    // Periodically persist playback position
    _subscriptions.add(
      _playerService.positionStream.listen((pos) {
        if (_isRestoringQueue) return;

        final now = DateTime.now();
        if (_lastPositionSaveTime == null || now.difference(_lastPositionSaveTime!) >= const Duration(seconds: 5)) {
          _lastPositionSaveTime = now;
          _queueRepository.updateCurrentPosition(pos.inMilliseconds);
        }
      }),
    );
  }

  @override
  List<TrackWithArtists> get originalQueue => List.unmodifiable(_originalQueue);

  @override
  List<TrackWithArtists> get currentQueue {
    final medias = _playerService.playlist.medias;
    return medias.map((m) => m.extras?['data'] as TrackWithArtists?).whereType<TrackWithArtists>().toList();
  }

  @override
  TrackWithArtists? get currentTrack {
    final playlist = _playerService.playlist;
    if (playlist.index < 0 || playlist.index >= playlist.medias.length) return null;
    return playlist.medias[playlist.index].extras?['data'] as TrackWithArtists?;
  }

  @override
  int get currentIndex => _playerService.playlist.index;

  @override
  bool get isPlaying => _playerService.isPlaying;

  @override
  Duration get position => _playerService.position;

  @override
  Duration get duration => _playerService.duration;

  @override
  double get volume => _playerService.volume;

  @override
  bool get isMuted => _settingsRepository.currentSettings.isMuted;

  @override
  bool get isShuffle => _settingsRepository.currentSettings.shuffleMode;

  @override
  PlaylistMode get loopMode => _settingsRepository.currentSettings.loopMode;

  @override
  String get playbackContextType => _playbackContextType;

  @override
  int? get playbackContextId => _playbackContextId;

  @override
  Stream<TrackWithArtists?> watchCurrentTrack() => _currentTrackController.stream;

  @override
  Stream<int> watchCurrentIndex() => _currentIndexController.stream;

  @override
  Stream<List<TrackWithArtists>> watchQueue() => _queueController.stream;

  @override
  Stream<bool> watchIsPlaying() => _playerService.playingStream;

  @override
  Stream<Duration> watchPosition() => _playerService.positionStream;

  @override
  Stream<Duration> watchDuration() => _playerService.durationStream;

  @override
  Stream<double> watchVolume() => _playerService.volumeStream;

  Media _createMedia(TrackWithArtists trackWithArtists) {
    return Media(
      trackWithArtists.track.filePath,
      extras: {'title': trackWithArtists.track.title, 'artists': trackWithArtists.artists, 'data': trackWithArtists},
    );
  }

  @override
  Future<void> playTrack(List<TrackWithArtists> tracks, int index) async {
    await setPlaylist(tracksToPlay: tracks, initialIndex: index, playbackContextType: 'direct');
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
    if (tracksToPlay.isEmpty) return;

    _playbackContextType = playbackContextType;
    _playbackContextId = playbackContextId;
    _originalQueue = List.from(tracksToPlay);

    final playableMedia = tracksToPlay.map(_createMedia).toList();

    try {
      _shouldSuppressNextScroll = false;
      _ref.read(queueScrollBehaviorProvider.notifier).setIntent(QueueScrollBehavior.jump);

      await _playerService.open(Playlist(playableMedia, index: initialIndex), play: autoplay);

      _saveQueueState(newIndex: initialIndex);
    } catch (e, s) {
      log.e("Error loading media_kit playlist", error: e, stackTrace: s);
    }

    if (isShuffle) {
      await Future.delayed(const Duration(milliseconds: 100));
      await _playerService.rawPlayer.setShuffle(true);
      final currentEngineIdx = _playerService.playlist.index;
      if (currentEngineIdx > 0) {
        await _playerService.rawPlayer.move(currentEngineIdx, 0);
      }
    }
  }

  @override
  Future<void> play() => _playerService.play();

  @override
  Future<void> pause() => _playerService.pause();

  @override
  Future<void> playOrPause() => _playerService.playOrPause();

  @override
  Future<void> next() => _playerService.rawPlayer.next();

  @override
  Future<void> previous() => _playerService.rawPlayer.previous();

  @override
  Future<void> jumpToIndex(int index) async {
    if (index >= 0 && index < _playerService.playlist.medias.length) {
      await _playerService.rawPlayer.jump(index);
    }
  }

  @override
  Future<void> seek(Duration position) => _playerService.seek(position);

  @override
  Future<void> setVolume(double volume) async {
    await _playerService.setVolume(volume);
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
    await _playerService.setVolume(nextMute ? 0.0 : _settingsRepository.currentSettings.volume);
  }

  @override
  Future<void> toggleShuffle() async {
    final nextShuffle = !isShuffle;
    await _settingsRepository.setShuffleMode(nextShuffle);
    await _playerService.rawPlayer.setShuffle(nextShuffle);
  }

  @override
  Future<void> toggleLoop() async {
    final nextMode = switch (loopMode) {
      PlaylistMode.none => PlaylistMode.single,
      PlaylistMode.single => PlaylistMode.loop,
      PlaylistMode.loop => PlaylistMode.none,
    };
    await _settingsRepository.setLoopMode(nextMode);
    await _playerService.setPlaylistMode(nextMode);
  }

  @override
  Future<void> addToQueue(List<TrackWithArtists> tracks) async {
    if (tracks.isEmpty) return;
    _originalQueue.addAll(tracks);
    for (final track in tracks) {
      await _playerService.rawPlayer.add(_createMedia(track));
    }
    _saveQueueState();
  }

  @override
  Future<void> playNext(List<TrackWithArtists> tracks) async {
    if (tracks.isEmpty) return;
    final insertIndex = currentIndex + 1;
    _originalQueue.insertAll(insertIndex, tracks);
    for (var i = 0; i < tracks.length; i++) {
      await _playerService.rawPlayer.add(_createMedia(tracks[i]));
      final lastIndex = _playerService.playlist.medias.length - 1;
      await _playerService.rawPlayer.move(lastIndex, insertIndex + i);
    }
    _saveQueueState();
  }

  @override
  Future<void> removeQueueItem(int index) async {
    if (index < 0 || index >= _playerService.playlist.medias.length) return;
    await _playerService.rawPlayer.remove(index);
    if (index < _originalQueue.length) {
      _originalQueue.removeAt(index);
    }
    _saveQueueState();
  }

  @override
  Future<void> removeQueueItems(List<int> indices) async {
    final sorted = List<int>.from(indices)..sort((a, b) => b.compareTo(a));
    for (final index in sorted) {
      await removeQueueItem(index);
    }
  }

  @override
  Future<void> reorderQueue(int oldIndex, int newIndex) async {
    final engineNewIndex = oldIndex < newIndex ? newIndex + 1 : newIndex;
    await _playerService.rawPlayer.move(oldIndex, engineNewIndex);
    if (oldIndex < _originalQueue.length && newIndex < _originalQueue.length) {
      final item = _originalQueue.removeAt(oldIndex);
      _originalQueue.insert(newIndex, item);
    }
    _saveQueueState();
  }

  @override
  Future<void> clearQueue() async {
    await _playerService.stop();
    await _playerService.open(const Playlist([]), play: false);
    _originalQueue.clear();
    await _queueRepository.saveQueue([], null, Duration.zero, '', null);
  }

  @override
  Future<void> restoreQueue() async {
    _isRestoringQueue = true;
    try {
      final (restoredQueue, lastIndex, lastPos, contextType, contextId) = await _queueRepository.loadQueue();

      if (restoredQueue.isEmpty) return;

      _originalQueue = List.from(restoredQueue);
      _playbackContextType = contextType;
      _playbackContextId = contextId;

      final playableMedia = restoredQueue.map(_createMedia).toList();
      final validIndex = (lastIndex >= 0 && lastIndex < restoredQueue.length) ? lastIndex : 0;

      await _playerService.open(Playlist(playableMedia, index: validIndex), play: false);

      _currentIndexController.add(validIndex);

      if (lastPos > Duration.zero) {
        await _playerService.seek(lastPos);
      }
    } finally {
      _isRestoringQueue = false;
    }
  }

  @override
  void suppressNextScroll() {
    _shouldSuppressNextScroll = true;
  }

  void _saveQueueState({int? newIndex}) {
    final activeIndex = newIndex ?? currentIndex;
    final playingTrack = (activeIndex >= 0 && activeIndex < currentQueue.length) ? currentQueue[activeIndex] : null;

    _queueRepository.saveQueue(
      _originalQueue,
      playingTrack?.track.filePath,
      position,
      _playbackContextType,
      _playbackContextId,
    );
  }

  @override
  bool consumeSuppressNextScroll() {
    if (_shouldSuppressNextScroll) {
      _shouldSuppressNextScroll = false;
      return true;
    }
    return false;
  }

  void dispose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _queueSaveDebouncer.cancel();
    _currentTrackController.close();
    _currentIndexController.close();
    _queueController.close();
  }
}

/// Riverpod provider for [PlaybackRepository].
final playbackRepositoryProvider = Provider<PlaybackRepository>((ref) {
  final playerService = ref.watch(audioPlayerServiceProvider);
  final queueRepo = ref.watch(queueRepositoryProvider);
  final settingsRepo = ref.watch(settingsRepositoryProvider);

  final repo = DefaultPlaybackRepository(playerService, queueRepo, settingsRepo, ref);

  ref.onDispose(repo.dispose);
  return repo;
});
