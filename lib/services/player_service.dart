import 'dart:async';

import 'package:media_kit/media_kit.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nordplayer/database/app_database.dart';
import 'package:nordplayer/services/logger.dart';
import 'package:nordplayer/services/preference_service.dart';

class PlayerService with LoggerMixin {
  final Ref ref;
  final Player _mkPlayer;

  PlayerService(this.ref) : _mkPlayer = Player();

  Player get mkPlayer => _mkPlayer;

  // Set up this way to prevent last position resetting to zero on startup
  bool _isRestoringQueue = false;
  Future<void> initializeQueueFromDatabase() async {
    _isRestoringQueue = true; // Lock the listeners

    try {
      final (playbackContextType, playbackContextId, tracks, index, position) =
          await ref.read(appDatabaseProvider).loadQueue();
      if (tracks.isNotEmpty) {
        await setPlaylist(
          tracksToPlay: tracks,
          initialIndex: index,
          playbackContextType: playbackContextType,
          playbackContextId: playbackContextId,
          autoplay: false,
        );

        await Future.delayed(const Duration(milliseconds: 300));
        await _mkPlayer.seek(position); // Restore the position
      }
    } finally {
      // Give the engine 500ms to settle, then unlock the listeners
      await Future.delayed(const Duration(milliseconds: 500));
      _isRestoringQueue = false;
    }
  }

  PlayerService.withPlayer(this.ref, this._mkPlayer) {
    DateTime? lastSaveTime;

    _mkPlayer.stream.playlist.listen((playlist) {
      if (_isRestoringQueue || playlist.medias.isEmpty) return;
      final tracks = playlist.medias
          .map((m) => m.extras?['data'] as TrackWithArtists?)
          .whereType<TrackWithArtists>()
          .toList();

      final playbackContext = ref.read(playbackContextProvider);

      ref
          .read(appDatabaseProvider)
          .saveQueue(
            playbackContext?.type ?? '',
            playbackContext?.id,
            tracks,
            playlist.index,
            _mkPlayer.state.position,
          );
    });

    _mkPlayer.stream.position.listen((position) {
      if (_isRestoringQueue) return;

      final now = DateTime.now();

      // DateTime-based debounce (can't use timer)
      if (lastSaveTime == null ||
          now.difference(lastSaveTime!) >= const Duration(seconds: 5)) {
        lastSaveTime = now;

        ref
            .read(appDatabaseProvider)
            .updateCurrentPosition(position.inMilliseconds);
      }
    });
  }

  /// Initialize with saved preferences
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

  /// Opens a list of tracks as a Playlist and play the given index
  Future<void> setPlaylist({
    required List<TrackWithArtists> tracksToPlay,
    required int initialIndex,
    required String playbackContextType,
    int? playbackContextId,
    bool autoplay = true,
  }) async {
    ref
        .read(playbackContextProvider.notifier)
        .setContext(playbackContextType, playbackContextId);

    final shouldShuffle = ref.read(preferenceServiceProvider).shuffleMode;

    final currentPaths = _mkPlayer.state.playlist.medias
        .map((m) => m.uri)
        .toList();

    final newPaths = tracksToPlay.map((s) => s.track.filePath).toList();

    bool isSamePlaylist = false;
    if (currentPaths.length == newPaths.length && currentPaths.isNotEmpty) {
      final currentSet = currentPaths.toSet();

      // Heuristic Check: If it has the exact same length, and the engine's set
      // contains the first, middle, and last tracks from the UI's list,
      // it is safely the exact same playlist.
      if (currentSet.contains(newPaths.first) &&
          currentSet.contains(newPaths.last) &&
          currentSet.contains(newPaths[newPaths.length ~/ 2])) {
        isSamePlaylist = true;
      }
    }

    final targetTrackPath = tracksToPlay[initialIndex].track.filePath;

    if (isSamePlaylist) {
      // Find where the target track ended up in the shuffled queue
      final targetIndex = _mkPlayer.state.playlist.medias.indexWhere(
        (m) => m.uri == targetTrackPath,
      );

      if (targetIndex != -1) {
        log.d(
          "Same playlist detected. Jumping to actual engine index: $targetIndex.",
        );
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
          extras: {
            'title': track.track.title,
            'artists': track.artists,
            'data': track,
          },
        );
      }).toList();

      try {
        await _mkPlayer.open(
          Playlist(playableMedia, index: initialIndex),
          play: autoplay,
        );
      } catch (e) {
        log.e("Error loading media_kit playlist: $e");
      }

      if (shouldShuffle) {
        await Future.delayed(const Duration(milliseconds: 100));
        await _mkPlayer.setShuffle(true);
      }
    }
  }

  // ========================== Queue Management ==============================

  /// Appends a list of tracks to the end of the current playback queue
  Future<void> addToQueue(
    List<TrackWithArtists> tracksToAdd,
    String contextType,
    int? contextId,
  ) async {
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

    // Convert tracks to media_kit Media objects
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

    // Append each track to the media_kit engine
    for (final media in playableMedia) {
      await _mkPlayer.add(media);
    }

    log.i("Added ${tracksToAdd.length} tracks to the queue.");
  }

  /// Moves a track from one index to another in the current queue
  Future<void> moveTrack(int oldIndex, int newIndex) async {
    try {
      await _mkPlayer.move(oldIndex, newIndex);
      log.i("Moved track from $oldIndex to $newIndex");
    } catch (e) {
      log.e("Error moving track: $e");
    }
  }

  /// Removes a track at a specific index from the queue
  Future<void> removeTrack(int index) async {
    try {
      await _mkPlayer.remove(index);
      log.i("Removed track at index $index");
    } catch (e) {
      log.e("Error removing track: $e");
    }
  }

  // =============================== Playback =================================

  Future<void> playOrPause() async {
    if (_mkPlayer.state.playlist.medias.isEmpty) return;
    await _mkPlayer.playOrPause();
  }

  Future<void> next() async => await _mkPlayer.next();
  Future<void> previous() async => await _mkPlayer.previous();

  Future<void> toggleShuffle() async {
    if (_mkPlayer.state.playlist.medias.isEmpty) {
      final newState = !ref.read(preferenceServiceProvider).shuffleMode;
      ref.read(preferenceServiceProvider.notifier).setShuffleMode(newState);
      log.w("Shuffle toggled while playlist is empty. Saving preference only.");
      return;
    }

    final bool newState = !_mkPlayer.state.shuffle;
    await _mkPlayer.setShuffle(newState);
    ref.read(preferenceServiceProvider.notifier).setShuffleMode(newState);
  }

  /// Cycle through Loop Modes. logic: Off -> All -> Single -> Off
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

// Handle audio playback communication with the OS
class MediaKitAudioHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
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
        systemActions: const {
          MediaAction.seek,
          MediaAction.skipToPrevious,
          MediaAction.skipToNext,
        },
        androidCompactActionIndices: const [0, 1, 2],
        processingState: _player.state.buffering
            ? AudioProcessingState.buffering
            : AudioProcessingState.ready,
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
// =============================== Provider ===================================
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

/// Converted to riverpod to avoid flicker
/// while switching to new playlist (new player)
final isPlayingProvider = NotifierProvider<IsPlayingNotifier, bool>(
  IsPlayingNotifier.new,
);

class IsPlayingNotifier extends Notifier<bool> {
  Timer? _debounceTimer;

  @override
  bool build() {
    final player = ref.watch(playerServiceProvider).mkPlayer;

    final subscription = player.stream.playing.listen((isPlaying) {
      if (isPlaying) {
        _debounceTimer?.cancel();
        state = true;
      } else {
        // Wait 150ms before telling the UI to show the "Play" icon.
        _debounceTimer?.cancel();
        _debounceTimer = Timer(const Duration(milliseconds: 150), () {
          state = false;
        });
      }
    });

    ref.onDispose(() {
      subscription.cancel();
      _debounceTimer?.cancel();
    });

    return player.state.playing;
  }
}

/// Track the currently played playlist
final playbackContextProvider =
    NotifierProvider<PlaybackContextNotifier, PlaybackContext?>(
      PlaybackContextNotifier.new,
    );

class PlaybackContext {
  final String type; // e.g., 'library', 'playlist', 'album'
  final int? id; // e.g., 5 (the playlist ID). Null for 'library'

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

// ============================ Current Queue =================================

/// Return MediaKit playlist stream
final rawPlaylistProvider = StreamProvider<Playlist>((ref) async* {
  final player = ref.watch(playerServiceProvider).mkPlayer;

  yield player.state.playlist;
  yield* player.stream.playlist;
});

/// Return currently playing track (single)
final currentTrackProvider = Provider<TrackWithArtists?>((ref) {
  final playlist = ref.watch(rawPlaylistProvider).value;
  if (playlist == null || playlist.medias.isEmpty) return null;

  final index = playlist.index;
  if (index < 0 || index >= playlist.medias.length) return null;

  return playlist.medias[index].extras?['data'] as TrackWithArtists?;
});

/// Return currently played track index in queue or -1 if no track played
final currentTrackIndexProvider = Provider<int>((ref) {
  final playlist = ref.watch(rawPlaylistProvider).value;
  return playlist?.index ?? -1;
});

/// Return all the tracks currently in queue
final currentTracksInQueueProvider = Provider<List<TrackWithArtists?>>((ref) {
  final playlist = ref.watch(rawPlaylistProvider).value;
  if (playlist == null || playlist.medias.isEmpty) return [];

  return playlist.medias
      .map((media) => media.extras?['data'] as TrackWithArtists?)
      .toList();
});

/// Return upcoming album arts for the queue (current and the next 4)
final current5TracksAlbumArtInQueueProvider = Provider<List<String>>((ref) {
  final playlist = ref.watch(rawPlaylistProvider).value;
  final loopMode = ref.watch(
    preferenceServiceProvider.select((prefs) => prefs.loopMode),
  );

  if (playlist == null || playlist.medias.isEmpty || playlist.index < 0) {
    return [];
  }

  final int currentIndex = playlist.index;
  final List<Media> allMedia = playlist.medias;
  final List<String> stackCovers = [];

  // Calculate up to 5 upcoming covers
  for (
    int count = 0;
    count < allMedia.length && stackCovers.length < 5;
    count++
  ) {
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
      final artPath = track.album.albumArtPath?.isNotEmpty == true
          ? track.album.albumArtPath!
          : "";

      stackCovers.add(artPath);
    }
  }

  return stackCovers;
});
