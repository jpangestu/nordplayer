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

  PlayerService.withPlayer(this.ref, this._mkPlayer) {
    Timer? positionDebounce;

    _mkPlayer.stream.playlist.listen((playlist) {
      if (playlist.medias.isEmpty) return;
      _persistQueue(playlist);
    });

    _mkPlayer.stream.position.listen((position) {
      positionDebounce?.cancel();
      positionDebounce = Timer(const Duration(seconds: 5), () {
        final playlist = _mkPlayer.state.playlist;
        if (playlist.medias.isEmpty) return;
        _persistQueue(playlist);
      });
    });
  }

  void _persistQueue(Playlist playlist) {
    final tracks = playlist.medias
        .map((m) => m.extras?['data'] as TrackWithArtists?)
        .whereType<TrackWithArtists>()
        .toList();

    ref
        .read(appDatabaseProvider)
        .saveQueue(tracks, playlist.index, _mkPlayer.state.position);
  }

  /// Initialize with saved preferences
  Future<void> init() async {
    final prefsState = ref.read(preferenceServiceProvider);

    try {
      await _mkPlayer.setVolume(prefsState.volume);
      await _mkPlayer.setPlaylistMode(prefsState.loopMode);
      log.i(
        "PlayerService initialized:\n"
        "Vol ${prefsState.volume},\n"
        "Loop ${prefsState.loopMode}",
      );
    } catch (e) {
      log.e("Error during PlayerService init: $e");
    }
  }

  /// Opens a list of tracks as a Playlist and play the given index
  Future<void> setPlaylist(
    List<TrackWithArtists> tracks,
    int initialIndex,
  ) async {
    final shouldShuffle = ref.read(preferenceServiceProvider).shuffleMode;

    final currentPaths = _mkPlayer.state.playlist.medias
        .map((m) => m.uri)
        .toList();

    final newPaths = tracks.map((s) => s.track.filePath).toList();

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

    final targetTrackPath = tracks[initialIndex].track.filePath;

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
      final playableMedia = tracks.map((track) {
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
          play: true,
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

  /// Appends a list of tracks to the end of the current playback queue
  Future<void> addToQueue(List<TrackWithArtists> tracks) async {
    if (tracks.isEmpty) return;

    // If nothing is currently in the playlist, just start playing these tracks
    if (_mkPlayer.state.playlist.medias.isEmpty) {
      await setPlaylist(tracks, 0);
      return;
    }

    // Convert tracks to media_kit Media objects
    final playableMedia = tracks.map((track) {
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

    log.i("Added ${tracks.length} tracks to the queue.");
  }

  Future<void> playOrPause() async {
    if (_mkPlayer.state.playlist.medias.isEmpty) return;
    await _mkPlayer.playOrPause();
  }

  Future<void> next() async => await _mkPlayer.next();
  Future<void> previous() async => await _mkPlayer.previous();

  Future<void> setVolume(double volume) async {
    await _mkPlayer.setVolume(volume);
    ref.read(preferenceServiceProvider.notifier).setVolume(volume);
  }

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

  /// Dispose when the app closes
  Future<void> dispose() async {
    await _mkPlayer.dispose();
  }
}

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
// ============================ Provider =================================
//

final playerServiceProvider = Provider<PlayerService>((ref) {
  final service = PlayerService(ref);

  ref.onDispose(() => service.dispose());

  return service;
});

//
// Convert media kit stream to riverpod
//

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
        _debounceTimer = Timer(const Duration(milliseconds: 100), () {
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

final currentTrackProvider = StreamProvider<TrackWithArtists?>((ref) {
  final player = ref.watch(playerServiceProvider).mkPlayer;

  return player.stream.playlist.map((playlist) {
    if (playlist.medias.isEmpty ||
        playlist.index < 0 ||
        playlist.index >= playlist.medias.length) {
      return null;
    }

    final currentMedia = playlist.medias[playlist.index];
    return currentMedia.extras?['data'] as TrackWithArtists?;
  });
});
