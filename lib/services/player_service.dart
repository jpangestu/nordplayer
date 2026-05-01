import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:nordplayer/database/app_database.dart';
import 'package:nordplayer/pages/queue_page.dart';
import 'package:nordplayer/services/logger.dart';
import 'package:nordplayer/services/preference_service.dart';
import 'package:nordplayer/utils/debouncer.dart';
import 'package:nordplayer/utils/stream_extension.dart';

class PlayerService with LoggerMixin {
  final Ref ref;
  final Player _mkPlayer;

  PlayerService(this.ref) : _mkPlayer = Player();
  Player get mkPlayer => _mkPlayer;

  /// The original nshuffled queue
  List<TrackWithArtists> _originalQueue = [];

  PlayerService.withPlayer(this.ref, this._mkPlayer) {
    DateTime? lastSaveTime;

    // Save queue state whenever the playlist changes (track finish, add, remove, move)
    _mkPlayer.stream.playlist.listen((playlist) {
      if (_isRestoringQueue || playlist.medias.isEmpty) return;

      _saveQueueState(newIndex: playlist.index);
    });

    // Save playback position every 5 seconds
    _mkPlayer.stream.position.listen((position) {
      if (_isRestoringQueue) return;

      final now = DateTime.now();

      // DateTime-based debounce (can't use timer)
      if (lastSaveTime == null || now.difference(lastSaveTime!) >= const Duration(seconds: 5)) {
        lastSaveTime = now;

        ref.read(appDatabaseProvider).updateCurrentPosition(position.inMilliseconds);
      }
    });
  }

  /// Initialize with saved user preferences (Volume, Loop Mode, Mute).
  Future<void> init() async {
    final prefsState = ref.read(preferenceServiceProvider);

    try {
      await _mkPlayer.setVolume(prefsState.volume);
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

  // Set up this way to prevent last position resetting to zero on startup
  bool _isRestoringQueue = false;

  /// Restores the exact playback sequence and position from the last session.
  Future<void> initializeQueueFromDatabase() async {
    _isRestoringQueue = true; // Lock listeners

    try {
      final (originalQueue, lastIndex, lastPosition, type, id) = await ref.read(appDatabaseProvider).loadQueue();

      if (originalQueue.isNotEmpty) {
        _originalQueue = List.from(originalQueue);
        ref.read(playbackContextProvider.notifier).setContext(type, id);

        final playableMedia = _originalQueue.map((track) {
          return Media(
            track.track.filePath,
            extras: {'title': track.track.title, 'artists': track.artists, 'data': track},
          );
        }).toList();

        await _mkPlayer.open(Playlist(playableMedia, index: lastIndex), play: false);

        final isShuffle = ref.read(preferenceServiceProvider).shuffleMode;
        if (isShuffle) {
          await _mkPlayer.setShuffle(true);
          // Wait for shuffle to finish
          await Future.delayed(const Duration(milliseconds: 100));
        }

        final lastTrackPlayedPath = _originalQueue[lastIndex].track.filePath;
        final lastTrackPlayedNewIndex = _mkPlayer.state.playlist.medias.indexWhere((m) => m.uri == lastTrackPlayedPath);
        await _mkPlayer.move(lastTrackPlayedNewIndex, 0);

        // Give the engine time to settle before jumping to the exact millisecond
        await Future.delayed(const Duration(milliseconds: 200));
        await _mkPlayer.seek(lastPosition);
      }
    } finally {
      await Future.delayed(const Duration(milliseconds: 500));
      _isRestoringQueue = false;
    }
  }

  /// Save current queue state to the database.
  void _saveQueueState({int? newIndex}) {
    if (_originalQueue.isEmpty || _mkPlayer.state.playlist.medias.isEmpty) return;

    final context = ref.read(playbackContextProvider);
    final engineIdx = _mkPlayer.state.playlist.index;

    String? currentlyPlayedTrackPath;
    if (engineIdx >= 0 && engineIdx < _mkPlayer.state.playlist.medias.length) {
      currentlyPlayedTrackPath = _mkPlayer.state.playlist.medias[engineIdx].uri;
    }

    ref
        .read(appDatabaseProvider)
        .saveQueue(
          _originalQueue,
          currentlyPlayedTrackPath,
          _mkPlayer.state.position,
          context?.type ?? '',
          context?.id,
        );
  }

  /// Opens a list of tracks as a Playlist
  Future<void> setPlaylist({
    required List<TrackWithArtists> tracksToPlay,
    required int initialIndex,
    required String playbackContextType,
    int? playbackContextId,
    bool autoplay = true,
  }) async {
    ref.read(playbackContextProvider.notifier).setContext(playbackContextType, playbackContextId);

    _originalQueue = List.from(tracksToPlay);
    final shouldShuffle = ref.read(preferenceServiceProvider).shuffleMode;

    final currentPaths = _mkPlayer.state.playlist.medias.map((m) => m.uri).toList();
    final newPaths = tracksToPlay.map((s) => s.track.filePath).toList();

    bool isSamePlaylist = false;
    if (currentPaths.length == newPaths.length && currentPaths.isNotEmpty) {
      final currentSet = currentPaths.toSet();

      // Heuristic Check: If it has the exact same length, and the engine's set contains the first, middle, and last
      // tracks from the UI's list, it is safely to assume that the track is from the exact same playlist.
      if (currentSet.contains(newPaths.first) &&
          currentSet.contains(newPaths.last) &&
          currentSet.contains(newPaths[newPaths.length ~/ 2])) {
        isSamePlaylist = true;
      }
    }

    final targetTrackPath = tracksToPlay[initialIndex].track.filePath;

    if (isSamePlaylist) {
      // Find where the target track ended up in the shuffled queue
      final targetIndex = _mkPlayer.state.playlist.medias.indexWhere((m) => m.uri == targetTrackPath);

      if (targetIndex != -1) {
        log.d("Same playlist detected. Jumping to actual engine index: $targetIndex.");
        await _mkPlayer.jump(targetIndex);
        await _mkPlayer.play();
      } else {
        isSamePlaylist = false;
      }
    }

    if (!isSamePlaylist) {
      log.d("New playlist detected. Opening new media pipeline.");
      final playableMedia = tracksToPlay.map((track) {
        return Media(
          track.track.filePath,
          extras: {'title': track.track.title, 'artists': track.artists, 'data': track},
        );
      }).toList();

      try {
        await _mkPlayer.open(Playlist(playableMedia, index: initialIndex), play: autoplay);
        _saveQueueState();
      } catch (e) {
        log.e("Error loading media_kit playlist: $e");
      }

      if (shouldShuffle) {
        await Future.delayed(const Duration(milliseconds: 100));
        await _mkPlayer.setShuffle(true);
      }
    }
  }

  // =========================================== Queue Management =====================================================

  /// Inserts track(s) immediately after the currently playing track
  Future<void> playNext(List<TrackWithArtists> tracksToAdd) async {
    if (tracksToAdd.isEmpty) return;

    // If nothing is currently in the playlist, just start playing these tracks
    if (_mkPlayer.state.playlist.medias.isEmpty) {
      await setPlaylist(
        tracksToPlay: tracksToAdd,
        initialIndex: 0,
        playbackContextType: 'play_next',
        playbackContextId: null,
      );
      return;
    }

    final engineCurrentIndex = _mkPlayer.state.playlist.index;
    final engineCurrentUri = _mkPlayer.state.playlist.medias[engineCurrentIndex].uri;

    // Synce originalQueue
    final baseCurrentIndex = _originalQueue.indexWhere((t) => t.track.filePath == engineCurrentUri);
    if (baseCurrentIndex != -1) {
      _originalQueue.insertAll(baseCurrentIndex + 1, tracksToAdd);
    } else {
      _originalQueue.addAll(tracksToAdd);
    }

    // Synce engineQueue
    final playableMedia = tracksToAdd.map((track) {
      return Media(track.track.filePath, extras: {'title': track.track.title, 'artists': track.artists, 'data': track});
    }).toList();

    // Add to engine and move into position
    int targetInsertIndex = engineCurrentIndex + 1;
    for (int i = 0; i < playableMedia.length; i++) {
      // Adds to the very end of the engine's playlist first
      await _mkPlayer.add(playableMedia[i]);

      // Calculate the index it was just added to
      final lastIndex = _mkPlayer.state.playlist.medias.length - 1;

      // Move it from the end to the target position
      await _mkPlayer.move(lastIndex, targetInsertIndex + i);
    }

    _saveQueueState();
    log.i("Set ${tracksToAdd.length} tracks to play next.");
  }

  /// Appends track(s) to the very end of the current queue.
  Future<void> addToQueue(List<TrackWithArtists> tracksToAdd, String contextType, int? contextId) async {
    if (tracksToAdd.isEmpty) return;

    // If nothing is currently in the playlist, just start playing these tracks
    if (_mkPlayer.state.playlist.medias.isEmpty) {
      await setPlaylist(
        tracksToPlay: tracksToAdd,
        initialIndex: 0,
        playbackContextType: contextType,
        playbackContextId: contextId,
      );
      return;
    }

    // Update originalQueue
    _originalQueue.addAll(tracksToAdd);

    // Convert tracks to media_kit Media objects
    final playableMedia = tracksToAdd.map((track) {
      return Media(track.track.filePath, extras: {'title': track.track.title, 'artists': track.artists, 'data': track});
    }).toList();

    // Append each track to the media_kit engine
    for (final media in playableMedia) {
      await _mkPlayer.add(media);
    }

    _saveQueueState();
    log.i("Added ${tracksToAdd.length} tracks to the queue.");
  }

  /// Moves a track from one index to another in the current queue
  Future<void> moveTrack(int oldIndex, int newIndex) async {
    try {
      final oldIndexPath = _mkPlayer.state.playlist.medias[oldIndex].uri;

      // Move in Engine
      await _mkPlayer.move(oldIndex, newIndex);

      // Save changes from manual moving to original queue only when shuffle is off
      final originalQueueOldIndex = _originalQueue.indexWhere((t) => t.track.filePath == oldIndexPath);
      if (originalQueueOldIndex != -1) {
        final track = _originalQueue.removeAt(originalQueueOldIndex);

        if (!_mkPlayer.state.shuffle) {
          _originalQueue.insert(newIndex, track);
        }
      }

      _saveQueueState();
      log.i("Moved track from $oldIndex to $newIndex");
    } catch (e) {
      log.e("Error moving track: $e");
    }
  }

  /// Removes a track at a specific index from the queue
  Future<void> removeTrack(int index) async {
    try {
      // Identify the actual track to remove
      final trackPath = _mkPlayer.state.playlist.medias[index].uri;
      _originalQueue.removeWhere((t) => t.track.filePath == trackPath);

      await _mkPlayer.remove(index);
      _saveQueueState();
      log.i("Removed track at index $index");
    } catch (e) {
      log.e("Error removing track: $e");
    }
  }

  // ============================================= Playback ===========================================================

  Future<void> playOrPause() async {
    if (_mkPlayer.state.playlist.medias.isEmpty) return;
    await _mkPlayer.playOrPause();
  }

  Future<void> next() async {
    ref.read(queueScrollBehaviorProvider.notifier).setIntent(QueueScrollBehavior.animate);
    await _mkPlayer.next();
  }

  Future<void> previous() async {
    ref.read(queueScrollBehaviorProvider.notifier).setIntent(QueueScrollBehavior.animate);
    await _mkPlayer.previous();
  }

  Future<void> toggleShuffle() async {
    ref.read(queueScrollBehaviorProvider.notifier).setIntent(QueueScrollBehavior.jump);

    if (_mkPlayer.state.playlist.medias.isEmpty) {
      final newState = !ref.read(preferenceServiceProvider).shuffleMode;
      ref.read(preferenceServiceProvider.notifier).setShuffleMode(newState);
      return;
    }

    final newState = !_mkPlayer.state.shuffle;
    ref.read(preferenceServiceProvider.notifier).setShuffleMode(newState);

    await _mkPlayer.setShuffle(newState);

    // Always put the current track at index 0 when shuffling
    // if (newState == true) {
    //   final currentIndex = _mkPlayer.state.playlist.index;
    //   await _mkPlayer.move(currentIndex, 0);
    // }

    _saveQueueState();
  }

  /// Cycle through Loop Modes. logic: Off -> All -> Single -> Off ...
  Future<void> cycleLoopMode() async {
    final current = ref.read(preferenceServiceProvider).loopMode;

    final next = switch (current) {
      PlaylistMode.none => PlaylistMode.loop,
      PlaylistMode.loop => PlaylistMode.single,
      PlaylistMode.single => PlaylistMode.none,
    };

    await _mkPlayer.setPlaylistMode(next);
    ref.read(preferenceServiceProvider.notifier).setLoopMode(next);
  }

  Future<void> setVolume(double volume) async {
    final prefsNotifier = ref.read(preferenceServiceProvider.notifier);

    if (volume == 0) {
      prefsNotifier.setIsMuted(true);
    } else {
      prefsNotifier.setIsMuted(false);
    }

    await _mkPlayer.setVolume(volume);
    prefsNotifier.setVolume(volume);
  }

  Future<void> setVolumeUp(double increment) async {
    final prefsVolume = ref.read(preferenceServiceProvider).volume;
    ref.read(preferenceServiceProvider.notifier).setIsMuted(false);

    final double volume = (prefsVolume + increment).clamp(0, 100);
    await _mkPlayer.setVolume(volume);
    ref.read(preferenceServiceProvider.notifier).setVolume(volume);
  }

  Future<void> setVolumeDown(double decrement) async {
    final prefsVolume = ref.read(preferenceServiceProvider).volume;

    final double volume = (prefsVolume - decrement).clamp(0, 100);

    if (volume == 0) {
      ref.read(preferenceServiceProvider.notifier).setIsMuted(true);
    } else {
      ref.read(preferenceServiceProvider.notifier).setIsMuted(false);
    }

    await _mkPlayer.setVolume(volume);
    ref.read(preferenceServiceProvider.notifier).setVolume(volume);
  }

  Future<void> toggleMute() async {
    final prefsState = ref.read(preferenceServiceProvider);
    final prefsNotifier = ref.read(preferenceServiceProvider.notifier);

    if (prefsState.isMuted) {
      // UNMUTE: Restore to the saved volume
      prefsNotifier.setIsMuted(false);
      await _mkPlayer.setVolume(prefsState.volume);
    } else {
      // MUTE: Drop engine to 0, but leave prefs volume alone
      prefsNotifier.setIsMuted(true);
      await _mkPlayer.setVolume(0.0);
    }
  }

  /// Dispose when the app closes
  Future<void> dispose() async {
    await _mkPlayer.dispose();
  }
}

// ============================================== Audio Handler =======================================================

// Handle audio playback communication with the OS
class MediaKitAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final Player _player;

  MediaKitAudioHandler(this._player) {
    _listenToPlayerStreams();
  }

  void _listenToPlayerStreams() {
    // Sync playing state
    _player.stream.playing.listen((playing) => _broadcastState());
    _player.stream.position.listen((_) => _broadcastState());
    _player.stream.buffering.listen((_) => _broadcastState());

    // Sync current track
    _player.stream.playlist.listen((playlist) {
      if (playlist.medias.isEmpty) {
        mediaItem.add(null);
        return;
      }
      final media = playlist.medias[playlist.index];
      final data = media.extras?['data'] as TrackWithArtists?;
      if (data != null) {
        mediaItem.add(
          MediaItem(
            id: media.uri,
            title: data.track.title,
            artist: data.artists.map((a) => a.name).join(', '),
            artUri: Uri.file(data.album.albumArtPath ?? ''),
          ),
        );
      }

      // Sync full queue
      queue.add(
        playlist.medias.map((m) {
          final d = m.extras?['data'] as TrackWithArtists?;
          return MediaItem(
            id: m.uri,
            title: d?.track.title ?? m.uri,
            artist: d?.artists.map((a) => a.name).join(', ') ?? '',
          );
        }).toList(),
      );
    });
  }

  void _broadcastState() {
    playbackState.add(
      PlaybackState(
        controls: [
          MediaControl.skipToPrevious,
          if (_player.state.playing) MediaControl.pause else MediaControl.play,
          MediaControl.skipToNext,
          MediaControl.stop,
        ],
        systemActions: const {MediaAction.seek, MediaAction.skipToPrevious, MediaAction.skipToNext},
        androidCompactActionIndices: const [0, 1, 2],
        processingState: _player.state.buffering ? AudioProcessingState.buffering : AudioProcessingState.ready,
        playing: _player.state.playing,
        updatePosition: _player.state.position,
        bufferedPosition: _player.state.buffer,
        speed: 1.0,
      ),
    );
  }

  // --- Playback controls (media keys / playerctl) ---

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() => _player.next();

  @override
  Future<void> skipToPrevious() => _player.previous();

  @override
  Future<void> skipToQueueItem(int index) => _player.jump(index);
}

//
// ============================================== Provider ============================================================
//

final playerServiceProvider = Provider<PlayerService>((ref) {
  final service = PlayerService(ref);

  ref.onDispose(() => service.dispose());

  return service;
});

final positionStreamProvider = StreamProvider<Duration>((ref) {
  final player = ref.watch(playerServiceProvider).mkPlayer;
  return player.stream.position;
});

final bufferStreamProvider = StreamProvider<Duration>((ref) {
  final player = ref.watch(playerServiceProvider).mkPlayer;
  return player.stream.buffer;
});

final durationStreamProvider = StreamProvider<Duration>((ref) {
  final player = ref.watch(playerServiceProvider).mkPlayer;
  return player.stream.duration;
});

/// Return bool on whether media kit player is currently playing a track
final isPlayingProvider = NotifierProvider<IsPlayingNotifier, bool>(IsPlayingNotifier.new);

class IsPlayingNotifier extends Notifier<bool> {
  // Debounce to ignore rapid changes when feeding new playlist to mkPlayer
  final _debouncer = Debouncer(const Duration(milliseconds: 50));

  @override
  bool build() {
    final player = ref.watch(playerServiceProvider).mkPlayer;

    final subscription = player.stream.playing.listen((isPlaying) {
      if (isPlaying) {
        state = true;
      } else {
        _debouncer(() {
          state = false;
        });
      }
    });

    ref.onDispose(() {
      subscription.cancel();
      _debouncer.dispose();
    });

    // Initial synchronous return for instant UI painting
    return player.state.playing;
  }
}

/// Track the currently played playlist
final playbackContextProvider = NotifierProvider<PlaybackContextNotifier, PlaybackContext?>(
  PlaybackContextNotifier.new,
);

class PlaybackContext {
  final String type; // e.g., 'all_tracks', 'playlist', 'album'
  final int? id; // e.g., 5 (the playlist ID). Null for 'all_tracks'

  PlaybackContext({required this.type, this.id});

  bool isPlaying(String targetType, int? targetId) {
    return type == targetType && id == targetId;
  }
}

class PlaybackContextNotifier extends Notifier<PlaybackContext?> {
  @override
  PlaybackContext? build() => null;

  void setContext(String type, int? id) {
    state = PlaybackContext(type: type, id: id);
  }
}

// ============================================== Current Queue =======================================================

/// Return curently played track
final currentTrackProvider = NotifierProvider<CurrentTrackNotifier, TrackWithArtists?>(CurrentTrackNotifier.new);

class CurrentTrackNotifier extends Notifier<TrackWithArtists?> {
  @override
  TrackWithArtists? build() {
    final player = ref.watch(playerServiceProvider).mkPlayer;

    final trackStream = player.stream.playlist
        .map((playlist) {
          // Synchronously extract the track from the incoming playlist state
          if (playlist.medias.isEmpty || playlist.index < 0 || playlist.index >= playlist.medias.length) {
            return null;
          }
          return playlist.medias[playlist.index].extras?['data'] as TrackWithArtists?;
        })
        .distinct((prev, next) {
          // Only proceed if the track actually changed (comparing file paths)
          return prev?.track.filePath == next?.track.filePath;
        })
        .debounceTime(const Duration(milliseconds: 50));

    final subscription = trackStream.listen((currentTrack) {
      state = currentTrack;
    });

    ref.onDispose(() {
      subscription.cancel();
    });

    final initialPlaylist = player.state.playlist;
    if (initialPlaylist.medias.isEmpty ||
        initialPlaylist.index < 0 ||
        initialPlaylist.index >= initialPlaylist.medias.length) {
      return null;
    }

    return initialPlaylist.medias[initialPlaylist.index].extras?['data'] as TrackWithArtists?;
  }
}

/// Return currently played track index
final currentTrackIndexProvider = NotifierProvider<CurrentTrackIndexNotifier, int>(CurrentTrackIndexNotifier.new);

class CurrentTrackIndexNotifier extends Notifier<int> {
  @override
  int build() {
    final player = ref.watch(playerServiceProvider).mkPlayer;

    final subscription = player.stream.playlist.listen((playlist) {
      final newIndex = playlist.index;

      if (newIndex != state) {
        state = newIndex;
      }
    });

    ref.onDispose(() {
      subscription.cancel();
    });

    return player.state.playlist.index;
  }
}

/// Return all tracks that's currently in queue
final currentTracksInQueueProvider = NotifierProvider<CurrentTracksInQueueNotifier, List<TrackWithArtists>>(
  CurrentTracksInQueueNotifier.new,
);

class CurrentTracksInQueueNotifier extends Notifier<List<TrackWithArtists>> {
  @override
  List<TrackWithArtists> build() {
    final player = ref.watch(playerServiceProvider).mkPlayer;

    final subscription = player.stream.playlist.listen((playlist) {
      // Drop any nulls just in case
      state = playlist.medias.map((media) => media.extras?['data']).whereType<TrackWithArtists>().toList();
    });

    ref.onDispose(() {
      subscription.cancel();
    });

    return player.state.playlist.medias.map((media) => media.extras?['data']).whereType<TrackWithArtists>().toList();
  }
}

/// Return upcoming album art paths for the current and the next 4 tracks in queue
final current5TracksAlbumArtInQueueProvider = NotifierProvider<Current5TracksAlbumArtNotifier, List<String>>(
  Current5TracksAlbumArtNotifier.new,
);

class Current5TracksAlbumArtNotifier extends Notifier<List<String>> {
  @override
  List<String> build() {
    final player = ref.watch(playerServiceProvider).mkPlayer;
    final loopMode = ref.watch(preferenceServiceProvider.select((prefs) => prefs.loopMode));

    final subscription = player.stream.playlist.listen((playlist) {
      state = _calculateCovers(playlist, loopMode);
    });

    ref.onDispose(() {
      subscription.cancel();
    });

    return _calculateCovers(player.state.playlist, loopMode);
  }

  List<String> _calculateCovers(Playlist playlist, PlaylistMode loopMode) {
    if (playlist.medias.isEmpty || playlist.index < 0) {
      return [];
    }

    final int currentIndex = playlist.index;
    final List<Media> allMedia = playlist.medias;
    final List<String> stackCovers = [];

    // Calculate up to 5 upcoming covers
    for (int count = 0; count < allMedia.length && stackCovers.length < 5; count++) {
      int targetIndex = currentIndex + count;

      // Handle wrap-around logic
      if (targetIndex >= allMedia.length) {
        if (loopMode == PlaylistMode.loop) {
          targetIndex = targetIndex % allMedia.length;
        } else {
          break; // Stop wrapping around if loop is off
        }
      }

      // Extract the track data
      final track = allMedia[targetIndex].extras?['data'] as TrackWithArtists?;

      if (track != null) {
        final artPath = track.album.albumArtPath?.isNotEmpty == true ? track.album.albumArtPath! : "";
        stackCovers.add(artPath);
      }
    }

    return stackCovers;
  }
}
