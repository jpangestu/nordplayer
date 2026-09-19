import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:nordplayer/core/database/app_database.dart';
import 'package:nordplayer/core/models/queue_scroll_behavior.dart';
import 'package:nordplayer/core/services/logger.dart';
import 'package:nordplayer/core/services/preference_service.dart';
import 'package:nordplayer/core/utils/debouncer.dart';
import 'package:nordplayer/core/utils/string_extension.dart';
import 'package:nordplayer/data/repositories/repositories.dart';
import 'package:nordplayer/services/player_state.dart';

export 'package:nordplayer/core/models/playback_context.dart';
export 'package:nordplayer/core/models/queue_scroll_behavior.dart';
export 'package:nordplayer/services/audio_handler.dart';
export 'package:nordplayer/services/player_state.dart';

/// Central coordinator for playback operations, queue manipulation,
/// shuffle/loop sequencing, volume management, and persistent queue state.
class PlayerService with LoggerMixin {
  final Ref _ref;
  final Player _mkPlayer;

  Player get mkPlayer => _mkPlayer;

  /// The original unshuffled queue.
  List<TrackWithArtists> _originalQueue = [];

  bool _shouldSuppressNextScroll = false;
  bool _isRestoringQueue = false;
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  late final Debouncer _queueSaveDebouncer = Debouncer(
    const Duration(milliseconds: 300),
  );

  /// Primary constructor injecting the Riverpod [Ref] and [Player] engine.
  PlayerService(this._ref, this._mkPlayer) {
    _setupEngineListeners();
  }

  /// Backward-compatible named constructor for test or legacy callers.
  PlayerService.withPlayer(Ref ref, Player player) : this(ref, player);

  void _setupEngineListeners() {
    DateTime? lastSaveTime;

    // Save queue state whenever playlist structure/indices change (debounced)
    _subscriptions.add(
      _mkPlayer.stream.playlist.listen((playlist) {
        if (_isRestoringQueue || playlist.medias.isEmpty) return;
        _queueSaveDebouncer(() => _saveQueueState(newIndex: playlist.index));
      }),
    );

    // Save playback position periodically (every 5 seconds)
    _subscriptions.add(
      _mkPlayer.stream.position.listen((position) {
        if (_isRestoringQueue) return;

        final now = DateTime.now();
        if (lastSaveTime == null ||
            now.difference(lastSaveTime!) >= const Duration(seconds: 5)) {
          lastSaveTime = now;

          log.d(
            "Saving playback position to database: ${position.inSeconds}s (${position.inMilliseconds}ms)",
          );
          _ref
              .read(queueRepositoryProvider)
              .updateCurrentPosition(position.inMilliseconds);
        }
      }),
    );
  }

  /// Call this before an intentional programmatic track change to suppress auto-scroll.
  void suppressNextScroll() {
    _shouldSuppressNextScroll = true;
  }

  /// Checks and resets the suppression flag for the next track change.
  bool consumeSuppressNextScroll() {
    if (_shouldSuppressNextScroll) {
      _shouldSuppressNextScroll = false;
      return true;
    }
    return false;
  }

  /// Initialize engine with saved user preferences (Volume, Loop Mode, Mute).
  Future<void> init() async {
    final prefsState = _ref.read(preferenceServiceProvider);

    try {
      await _mkPlayer.setVolume(prefsState.volume.clamp(0.0, 100.0));
      await _mkPlayer.setPlaylistMode(prefsState.loopMode);

      if (prefsState.isMuted) {
        await _mkPlayer.setVolume(0);
      }

      log.i(
        "PlayerService initialized:\n"
        "Volume ${prefsState.volume},\n"
        "Mute ${prefsState.isMuted},\n"
        "Loop ${prefsState.loopMode}",
      );
    } catch (e) {
      log.e("Error during PlayerService init: $e");
    }
  }

  /// Restores the exact playback sequence and position from the last session.
  Future<void> initializeQueueFromDatabase() async {
    _isRestoringQueue = true;

    try {
      final (originalQueue, lastIndex, lastPosition, type, id) =
          await _ref.read(queueRepositoryProvider).loadQueue();

      if (originalQueue.isNotEmpty) {
        _originalQueue = List.from(originalQueue);
        _ref.read(playbackContextProvider.notifier).setContext(type, id);

        final playableMedia = _originalQueue.map((track) {
          return Media(
            track.track.filePath,
            extras: {
              'title': track.track.title,
              'artists': track.artists,
              'data': track,
            },
          );
        }).toList();

        final initialIndex = lastIndex.clamp(0, playableMedia.length - 1);
        await _mkPlayer.open(
          Playlist(playableMedia, index: initialIndex),
          play: false,
        );

        final isShuffle = _ref.read(preferenceServiceProvider).shuffleMode;
        if (isShuffle) {
          await _mkPlayer.setShuffle(true);

          final lastTrackPlayedPath = _originalQueue[initialIndex].track.filePath
              .normalizePath()
              .toLowerCase();
          final lastTrackPlayedNewIndex = _mkPlayer.state.playlist.medias
              .indexWhere(
                (m) =>
                    m.uri.normalizePath().toLowerCase() == lastTrackPlayedPath,
              );
          if (lastTrackPlayedNewIndex != -1) {
            await _mkPlayer.move(lastTrackPlayedNewIndex, 0);
          }
        }

        // Wait for the player to reach an initialized duration state
        if (_mkPlayer.state.duration.inMilliseconds == 0) {
          try {
            await _mkPlayer.stream.duration
                .firstWhere((duration) => duration.inMilliseconds > 0)
                .timeout(const Duration(milliseconds: 500));
          } catch (_) {}
        }
        await _mkPlayer.seek(lastPosition);
      }
    } finally {
      _isRestoringQueue = false;
    }
  }

  /// Save current queue state to the database.
  void _saveQueueState({int? newIndex}) {
    if (_originalQueue.isEmpty || _mkPlayer.state.playlist.medias.isEmpty) {
      log.w("Aborting queue save: originalQueue or medias is empty.");
      return;
    }

    final context = _ref.read(playbackContextProvider);
    final engineIdx = newIndex ?? _mkPlayer.state.playlist.index;

    String? currentlyPlayedTrackPath;
    if (engineIdx >= 0 && engineIdx < _mkPlayer.state.playlist.medias.length) {
      currentlyPlayedTrackPath = _mkPlayer.state.playlist.medias[engineIdx].uri;
    }

    log.d(
      "Currently played track path: $currentlyPlayedTrackPath (index: $engineIdx)",
    );

    _ref
        .read(queueRepositoryProvider)
        .saveQueue(
          _originalQueue,
          currentlyPlayedTrackPath,
          _mkPlayer.state.position,
          context?.type ?? '',
          context?.id,
        );
  }

  /// Opens a list of tracks as a Playlist.
  Future<void> setPlaylist({
    required List<TrackWithArtists> tracksToPlay,
    required int initialIndex,
    required String playbackContextType,
    int? playbackContextId,
    bool autoplay = true,
    bool forceReload = false,
  }) async {
    final currentContext = _ref.read(playbackContextProvider);
    bool isSamePlaylist =
        currentContext?.isPlaying(playbackContextType, playbackContextId) ??
        false;

    if (forceReload) {
      isSamePlaylist = false;
    }

    _ref
        .read(playbackContextProvider.notifier)
        .setContext(playbackContextType, playbackContextId);

    _originalQueue = List.from(tracksToPlay);
    final shouldShuffle = _ref.read(preferenceServiceProvider).shuffleMode;
    final targetTrackPath = tracksToPlay[initialIndex].track.filePath
        .normalizePath()
        .toLowerCase();

    // Jump logic
    if (isSamePlaylist && _mkPlayer.state.playlist.medias.isNotEmpty) {
      final targetIndex = _mkPlayer.state.playlist.medias.indexWhere(
        (m) => m.uri.normalizePath().toLowerCase() == targetTrackPath,
      );

      if (targetIndex != -1) {
        log.d("Same context detected. Jumping to engine index: $targetIndex.");
        await _mkPlayer.jump(targetIndex);
        if (autoplay) await _mkPlayer.play();
        return;
      }
    }

    // Reload logic
    log.d("New context or force reload. Opening new media pipeline.");
    final playableMedia = tracksToPlay.map((track) {
      return Media(
        track.track.filePath,
        extras: {
          'title': track.track.title,
          'artists': track.artists,
          'data': track,
        },
      );
    }).toList();

    try {
      _shouldSuppressNextScroll = false;
      _ref
          .read(queueScrollBehaviorProvider.notifier)
          .setIntent(QueueScrollBehavior.jump);

      await _mkPlayer.open(
        Playlist(playableMedia, index: initialIndex),
        play: autoplay,
      );
      _saveQueueState(newIndex: initialIndex);
    } catch (e) {
      log.e("Error loading media_kit playlist: $e");
    }

    if (shouldShuffle) {
      await Future.delayed(const Duration(milliseconds: 100));
      await _mkPlayer.setShuffle(true);
      final currentEngineIdx = _mkPlayer.state.playlist.index;
      if (currentEngineIdx > 0) {
        await _mkPlayer.move(currentEngineIdx, 0);
      }
    }
  }

  /// Jumps playback directly to the track at [index].
  Future<void> jumpToIndex(int index) async {
    if (index >= 0 && index < _mkPlayer.state.playlist.medias.length) {
      await _mkPlayer.jump(index);
    }
  }

  // =========================================== Queue Management =====================================================

  /// Completely clears the player queue and stops playback.
  Future<void> clearQueue() async {
    await _mkPlayer.stop();
    await _mkPlayer.open(const Playlist([]), play: false);
    _originalQueue.clear();

    await _ref
        .read(queueRepositoryProvider)
        .saveQueue([], null, Duration.zero, '', null);
    _ref.read(playbackContextProvider.notifier).setContext('', null);

    log.i("Queue cleared successfully.");
  }

  /// Inserts track(s) immediately after the currently playing track.
  Future<void> playNext(
    List<TrackWithArtists> tracksToAdd,
    String contextType,
    int? contextId,
  ) async {
    if (tracksToAdd.isEmpty) return;

    if (_mkPlayer.state.playlist.medias.isEmpty) {
      await setPlaylist(
        tracksToPlay: tracksToAdd,
        initialIndex: 0,
        playbackContextType: contextType,
        playbackContextId: contextId,
      );
      return;
    }

    final engineCurrentIndex = _mkPlayer.state.playlist.index;
    final engineCurrentUri = _mkPlayer
        .state
        .playlist
        .medias[engineCurrentIndex]
        .uri
        .normalizePath()
        .toLowerCase();

    final baseCurrentIndex = _originalQueue.indexWhere(
      (t) => t.track.filePath.normalizePath().toLowerCase() == engineCurrentUri,
    );
    if (baseCurrentIndex != -1) {
      _originalQueue.insertAll(baseCurrentIndex + 1, tracksToAdd);
    } else {
      _originalQueue.addAll(tracksToAdd);
    }

    final playableMedia = tracksToAdd.map((track) {
      return Media(
        track.track.filePath,
        extras: {
          'title': track.track.title,
          'artists': track.artists,
          'data': track,
        },
      );
    }).toList();

    int targetInsertIndex = engineCurrentIndex + 1;
    for (int i = 0; i < playableMedia.length; i++) {
      await _mkPlayer.add(playableMedia[i]);
      final lastIndex = _mkPlayer.state.playlist.medias.length - 1;
      await _mkPlayer.move(lastIndex, targetInsertIndex + i);
    }

    _saveQueueState();
    log.i("Set ${tracksToAdd.length} tracks to play next.");
  }

  /// Appends track(s) to the very end of the current queue.
  Future<void> addToQueue(
    List<TrackWithArtists> tracksToAdd,
    String contextType,
    int? contextId,
  ) async {
    if (tracksToAdd.isEmpty) return;

    if (_mkPlayer.state.playlist.medias.isEmpty) {
      await setPlaylist(
        tracksToPlay: tracksToAdd,
        initialIndex: 0,
        playbackContextType: contextType,
        playbackContextId: contextId,
      );
      return;
    }

    _originalQueue.addAll(tracksToAdd);

    final playableMedia = tracksToAdd.map((track) {
      return Media(
        track.track.filePath,
        extras: {
          'title': track.track.title,
          'artists': track.artists,
          'data': track,
        },
      );
    }).toList();

    for (final media in playableMedia) {
      await _mkPlayer.add(media);
    }

    _saveQueueState();
    log.i("Added ${tracksToAdd.length} tracks to the queue.");
  }

  /// Moves a track from one index to another in the active queue.
  Future<void> moveTrack(int oldIndex, int newIndex) async {
    try {
      final oldIndexPath = _mkPlayer.state.playlist.medias[oldIndex].uri
          .normalizePath()
          .toLowerCase();

      final engineNewIndex = oldIndex < newIndex ? newIndex + 1 : newIndex;
      await _mkPlayer.move(oldIndex, engineNewIndex);

      // In unshuffled mode, reflect manual reordering in _originalQueue
      if (!_mkPlayer.state.shuffle) {
        final originalQueueOldIndex = _originalQueue.indexWhere(
          (t) => t.track.filePath.normalizePath().toLowerCase() == oldIndexPath,
        );
        if (originalQueueOldIndex != -1) {
          final track = _originalQueue.removeAt(originalQueueOldIndex);
          final clampedNewIndex = newIndex.clamp(0, _originalQueue.length);
          _originalQueue.insert(clampedNewIndex, track);
        }
      }

      _saveQueueState();
      log.i("Moved track from $oldIndex to $newIndex");
    } catch (e) {
      log.e("Error moving track: $e");
    }
  }

  /// Removes a track at a specific index from the queue.
  Future<void> removeTrack(int index) async {
    if (index < 0 || index >= _mkPlayer.state.playlist.medias.length) return;
    try {
      final trackPath = _mkPlayer.state.playlist.medias[index].uri
          .normalizePath()
          .toLowerCase();
      _originalQueue.removeWhere(
        (t) => t.track.filePath.normalizePath().toLowerCase() == trackPath,
      );

      await _mkPlayer.remove(index);
      _saveQueueState();
      log.i("Removed track at index $index");
    } catch (e) {
      log.e("Error removing track: $e");
    }
  }

  /// Removes multiple tracks from the queue by their indices.
  Future<void> removeTracks(List<int> indices) async {
    if (indices.isEmpty) return;

    final sortedIndices = List<int>.from(indices)..sort((a, b) => b.compareTo(a));

    try {
      final pathsToRemove = <String>{};
      for (final index in sortedIndices) {
        if (index >= 0 && index < _mkPlayer.state.playlist.medias.length) {
          pathsToRemove.add(
            _mkPlayer.state.playlist.medias[index].uri.normalizePath().toLowerCase(),
          );
        }
      }

      _originalQueue.removeWhere(
        (t) => pathsToRemove.contains(t.track.filePath.normalizePath().toLowerCase()),
      );

      for (final index in sortedIndices) {
        if (index >= 0 && index < _mkPlayer.state.playlist.medias.length) {
          await _mkPlayer.remove(index);
        }
      }
      _saveQueueState();
      log.i("Removed ${indices.length} tracks from queue");
    } catch (e) {
      log.e("Error removing tracks: $e");
    }
  }

  /// Removes all instances of a track with the given path from the queue.
  Future<void> removeTrackByPath(String path) async {
    try {
      final normalizedPath = path.normalizePath().toLowerCase();
      final indicesToRemove = <int>[];
      final medias = _mkPlayer.state.playlist.medias;
      for (int i = 0; i < medias.length; i++) {
        if (medias[i].uri.normalizePath().toLowerCase() == normalizedPath) {
          indicesToRemove.add(i);
        }
      }
      if (indicesToRemove.isNotEmpty) {
        await removeTracks(indicesToRemove);
      }
    } catch (e) {
      log.e("Error removing track by path: $e");
    }
  }

  // ============================================= Playback ===========================================================

  Future<void> playOrPause() async {
    if (_mkPlayer.state.playlist.medias.isEmpty) return;
    await _mkPlayer.playOrPause();
  }

  Future<void> next() async {
    _ref
        .read(queueScrollBehaviorProvider.notifier)
        .setIntent(QueueScrollBehavior.animate);
    await _mkPlayer.next();
  }

  Future<void> previous() async {
    _ref
        .read(queueScrollBehaviorProvider.notifier)
        .setIntent(QueueScrollBehavior.animate);
    await _mkPlayer.previous();
  }

  Future<void> toggleShuffle() async {
    if (_mkPlayer.state.playlist.medias.isEmpty) {
      final newState = !_ref.read(preferenceServiceProvider).shuffleMode;
      _ref.read(preferenceServiceProvider.notifier).setShuffleMode(newState);
      return;
    }

    final newState = !_mkPlayer.state.shuffle;
    _ref.read(preferenceServiceProvider.notifier).setShuffleMode(newState);

    if (newState) {
      await _mkPlayer.setShuffle(true);
      final currentIndex = _mkPlayer.state.playlist.index;
      if (currentIndex > 0) {
        await _mkPlayer.move(currentIndex, 0);
      }
    } else {
      // Unshuffling: restore original sequence while preserving current track
      await _mkPlayer.setShuffle(false);
      if (_originalQueue.isNotEmpty) {
        final currentEngineIdx = _mkPlayer.state.playlist.index;
        final currentUri =
            (currentEngineIdx >= 0 &&
                currentEngineIdx < _mkPlayer.state.playlist.medias.length)
            ? _mkPlayer
                  .state
                  .playlist
                  .medias[currentEngineIdx]
                  .uri
                  .normalizePath()
                  .toLowerCase()
            : null;

        final originalIndex = currentUri != null
            ? _originalQueue.indexWhere(
                (t) =>
                    t.track.filePath.normalizePath().toLowerCase() ==
                    currentUri,
              )
            : -1;

        final playableMedia = _originalQueue.map((track) {
          return Media(
            track.track.filePath,
            extras: {
              'title': track.track.title,
              'artists': track.artists,
              'data': track,
            },
          );
        }).toList();

        final resumePos = _mkPlayer.state.position;
        final wasPlaying = _mkPlayer.state.playing;
        final targetIndex = originalIndex != -1 ? originalIndex : 0;

        await _mkPlayer.open(
          Playlist(playableMedia, index: targetIndex),
          play: wasPlaying,
        );
        if (resumePos > Duration.zero) {
          await _mkPlayer.seek(resumePos);
        }
      }
    }

    _ref
        .read(queueScrollBehaviorProvider.notifier)
        .setIntent(QueueScrollBehavior.jump);
    _saveQueueState();
  }

  /// Cycle through Loop Modes: Off -> All -> Single -> Off ...
  Future<void> cycleLoopMode() async {
    final current = _ref.read(preferenceServiceProvider).loopMode;

    final next = switch (current) {
      PlaylistMode.none => PlaylistMode.loop,
      PlaylistMode.loop => PlaylistMode.single,
      PlaylistMode.single => PlaylistMode.none,
    };

    await _mkPlayer.setPlaylistMode(next);
    _ref.read(preferenceServiceProvider.notifier).setLoopMode(next);
  }

  Future<void> setVolume(double volume) async {
    final clamped = volume.clamp(0.0, 100.0);
    final prefsNotifier = _ref.read(preferenceServiceProvider.notifier);

    prefsNotifier.setIsMuted(clamped == 0);
    await _mkPlayer.setVolume(clamped);
    prefsNotifier.setVolume(clamped);
  }

  Future<void> setVolumeUp(double increment) async {
    final prefsVolume = _ref.read(preferenceServiceProvider).volume;
    _ref.read(preferenceServiceProvider.notifier).setIsMuted(false);

    final double volume = (prefsVolume + increment).clamp(0.0, 100.0);
    await _mkPlayer.setVolume(volume);
    _ref.read(preferenceServiceProvider.notifier).setVolume(volume);
  }

  Future<void> setVolumeDown(double decrement) async {
    final prefsVolume = _ref.read(preferenceServiceProvider).volume;
    final double volume = (prefsVolume - decrement).clamp(0.0, 100.0);

    _ref.read(preferenceServiceProvider.notifier).setIsMuted(volume == 0);
    await _mkPlayer.setVolume(volume);
    _ref.read(preferenceServiceProvider.notifier).setVolume(volume);
  }

  Future<void> toggleMute() async {
    final prefsState = _ref.read(preferenceServiceProvider);
    final prefsNotifier = _ref.read(preferenceServiceProvider.notifier);

    if (prefsState.isMuted) {
      prefsNotifier.setIsMuted(false);
      await _mkPlayer.setVolume(prefsState.volume.clamp(0.0, 100.0));
    } else {
      prefsNotifier.setIsMuted(true);
      await _mkPlayer.setVolume(0.0);
    }
  }

  /// Releases resources, cancels all stream subscriptions, and disposes the player.
  Future<void> dispose() async {
    for (final sub in _subscriptions) {
      await sub.cancel();
    }
    _subscriptions.clear();
    _queueSaveDebouncer.dispose();
    await _mkPlayer.dispose();
  }
}

// =========================================== Providers =======================================================

/// Global audio player engine provider.
final audioPlayerProvider = Provider<Player>((ref) {
  final player = Player();
  ref.onDispose(() => player.dispose());
  return player;
});

/// Global player service coordinating playback, queue manipulation, and audio state.
final playerServiceProvider = Provider<PlayerService>((ref) {
  final player = ref.watch(audioPlayerProvider);
  final service = PlayerService(ref, player);
  ref.onDispose(() => service.dispose());
  return service;
});
