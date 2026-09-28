import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:nordplayer/data/services/audio/playback_controller.dart';
import 'package:nordplayer/domain/models/composite_models.dart';

/// Bridges [Player] and [PlaybackController] playback events to the host operating system
/// (Windows System Media Transport Controls / Linux MPRIS / Android notification).
class AppAudioHandler(final Player _player) extends BaseAudioHandler with QueueHandler, SeekHandler {
  PlaybackController? _controller;
  final List<StreamSubscription<dynamic>> _playerSubscriptions = [];
  final List<StreamSubscription<dynamic>> _controllerSubscriptions = [];
  StreamSubscription<dynamic>? _fallbackPlaylistSubscription;
  int _lastSyncedQueueLength = -1;
  String _lastSyncedQueueSignature = '';
  DateTime? _lastPositionBroadcast;

  this {
    _listenToPlayerStreams();
  }

  /// Underlying raw [Player] instance.
  Player get player => _player;

  /// Active controller coordinator if attached.
  PlaybackController? get controller => _controller;

  /// Attaches the [PlaybackController] as the single source of truth for queue
  /// sequencing, track metadata, and hardware media key actions.
  void attachController(PlaybackController controller) {
    _controller = controller;
    _listenToController(controller);
  }

  void _listenToPlayerStreams() {
    // Sync playing state and buffering immediately from transport engine
    _playerSubscriptions.add(_player.stream.playing.listen((_) => _broadcastState()));
    _playerSubscriptions.add(_player.stream.buffering.listen((_) => _broadcastState()));

    // Throttle periodic position broadcasts to once every second.
    // The OS automatically interpolates playback position between updates.
    _playerSubscriptions.add(
      _player.stream.position.listen((_) {
        final now = DateTime.now();
        if (_lastPositionBroadcast == null || now.difference(_lastPositionBroadcast!) >= const Duration(seconds: 1)) {
          _lastPositionBroadcast = now;
          _broadcastState();
        }
      }),
    );

    // Initial fallback: sync from media_kit playlist until controller is attached
    _fallbackPlaylistSubscription = _player.stream.playlist.listen((playlist) {
      if (_controller != null) return; // Controller has precedence
      if (playlist.medias.isEmpty || playlist.index < 0 || playlist.index >= playlist.medias.length) {
        mediaItem.add(null);
        return;
      }

      final media = playlist.medias[playlist.index];
      final data = media.extras?['data'] as TrackWithArtists?;
      if (data != null) {
        _updateMediaItemFromTrack(data);
      }
    });
  }

  void _listenToController(PlaybackController controller) {
    // Cancel fallback media_kit playlist listener
    _fallbackPlaylistSubscription?.cancel();
    _fallbackPlaylistSubscription = null;

    for (final sub in _controllerSubscriptions) {
      sub.cancel();
    }
    _controllerSubscriptions.clear();

    // Initial snapshot sync from attached controller
    if (controller.currentTrack != null) {
      _updateMediaItemFromTrack(controller.currentTrack!);
    } else {
      mediaItem.add(null);
    }

    if (controller.currentQueue.isNotEmpty) {
      _syncQueue(controller.currentQueue);
    }

    // 1. Sync active track to OS notification / Windows SMTC
    _controllerSubscriptions.add(
      controller.watchCurrentTrack().listen((track) {
        if (track == null) {
          mediaItem.add(null);
        } else {
          _updateMediaItemFromTrack(track);
        }
      }),
    );

    // 2. Sync full active queue to OS (MPRIS / Android Auto)
    _controllerSubscriptions.add(
      controller.watchQueue().listen((tracks) {
        _syncQueue(tracks);
      }),
    );
  }

  void _syncQueue(List<TrackWithArtists> tracks) {
    final signature = tracks.isEmpty
        ? ''
        : '${tracks.length}:${tracks.first.track.filePath}:${tracks.last.track.filePath}';

    if (tracks.length != _lastSyncedQueueLength || signature != _lastSyncedQueueSignature) {
      _lastSyncedQueueLength = tracks.length;
      _lastSyncedQueueSignature = signature;

      queue.add(
        tracks.map((d) {
          final artPath = d.album.albumArtPath;
          final artUri = (artPath != null && artPath.isNotEmpty) ? Uri.file(artPath) : null;
          return MediaItem(
            id: d.track.filePath,
            title: d.track.title,
            artist: d.artists.map((a) => a.name).join(', '),
            album: d.album.title,
            duration: Duration(milliseconds: d.track.durationMs),
            artUri: artUri,
          );
        }).toList(),
      );
    }
  }

  void _updateMediaItemFromTrack(TrackWithArtists data) {
    final artPath = data.album.albumArtPath;
    final artUri = (artPath != null && artPath.isNotEmpty) ? Uri.file(artPath) : null;

    mediaItem.add(
      MediaItem(
        id: data.track.filePath,
        title: data.track.title,
        artist: data.artists.map((a) => a.name).join(', '),
        album: data.album.title,
        duration: Duration(milliseconds: data.track.durationMs),
        artUri: artUri,
      ),
    );
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
          MediaAction.play,
          MediaAction.pause,
          MediaAction.stop,
        },
        androidCompactActionIndices: const [0, 1, 2],
        processingState: _player.state.buffering ? AudioProcessingState.buffering : AudioProcessingState.ready,
        playing: _player.state.playing,
        updatePosition: _player.state.position,
        bufferedPosition: _player.state.buffer,
        speed: 1.0,
      ),
    );
  }

  // --- Transport Controls (Hardware media keys & OS flyout buttons) ---

  @override
  Future<void> play() async {
    if (_controller != null) {
      await _controller!.play();
    } else {
      await _player.play();
    }
  }

  @override
  Future<void> pause() async {
    if (_controller != null) {
      await _controller!.pause();
    } else {
      await _player.pause();
    }
  }

  @override
  Future<void> stop() async {
    if (_controller != null) {
      await _controller!.pause();
    }
    await _player.stop();
    playbackState.add(playbackState.value.copyWith(processingState: AudioProcessingState.idle, playing: false));
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) async {
    if (_controller != null) {
      await _controller!.seek(position);
    } else {
      await _player.seek(position);
    }
    _lastPositionBroadcast = DateTime.now();
    _broadcastState();
  }

  @override
  Future<void> skipToNext() async {
    if (_controller != null) {
      await _controller!.next();
    } else {
      await _player.next();
    }
  }

  @override
  Future<void> skipToPrevious() async {
    if (_controller != null) {
      await _controller!.previous();
    } else {
      await _player.previous();
    }
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    if (_controller != null) {
      await _controller!.jumpToIndex(index);
    } else {
      await _player.jump(index);
    }
  }

  /// Releases resources and cancels active stream subscriptions.
  Future<void> dispose() async {
    for (final sub in _playerSubscriptions) {
      await sub.cancel();
    }
    _playerSubscriptions.clear();

    for (final sub in _controllerSubscriptions) {
      await sub.cancel();
    }
    _controllerSubscriptions.clear();

    await _fallbackPlaylistSubscription?.cancel();
    _fallbackPlaylistSubscription = null;
  }
}

/// Backward-compatible type alias for existing references.
typedef MediaKitAudioHandler = AppAudioHandler;

/// Riverpod provider for [AppAudioHandler] (can be overridden in [ProviderScope]).
final audioHandlerProvider = Provider<AppAudioHandler?>((ref) => null);
