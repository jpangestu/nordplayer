import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:media_kit/media_kit.dart';
import 'package:nordplayer/domain/models/models.dart';

/// Bridges [Player] playback events to the host operating system
/// (Windows System Media Transport Controls / Linux MPRIS / Android notification).
class MediaKitAudioHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  final Player _player;
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  int _lastSyncedQueueLength = -1;
  String _lastSyncedQueueSignature = '';
  DateTime? _lastPositionBroadcast;

  MediaKitAudioHandler(this._player) {
    _listenToPlayerStreams();
  }

  void _listenToPlayerStreams() {
    // Sync playing state and buffering immediately
    _subscriptions.add(
      _player.stream.playing.listen((_) => _broadcastState()),
    );
    _subscriptions.add(
      _player.stream.buffering.listen((_) => _broadcastState()),
    );

    // Throttle periodic position broadcasts to once every second.
    // The OS automatically interpolates playback position between updates.
    _subscriptions.add(
      _player.stream.position.listen((_) {
        final now = DateTime.now();
        if (_lastPositionBroadcast == null ||
            now.difference(_lastPositionBroadcast!) >= const Duration(seconds: 1)) {
          _lastPositionBroadcast = now;
          _broadcastState();
        }
      }),
    );

    // Sync active track and queue
    _subscriptions.add(
      _player.stream.playlist.listen((playlist) {
        if (playlist.medias.isEmpty ||
            playlist.index < 0 ||
            playlist.index >= playlist.medias.length) {
          mediaItem.add(null);
          return;
        }

        final media = playlist.medias[playlist.index];
        final data = media.extras?['data'] as TrackWithArtists?;
        if (data != null) {
          final artPath = data.album.albumArtPath;
          final artUri = (artPath != null && artPath.isNotEmpty)
              ? Uri.file(artPath)
              : null;

          mediaItem.add(
            MediaItem(
              id: media.uri,
              title: data.track.title,
              artist: data.artists.map((a) => a.name).join(', '),
              album: data.album.title,
              duration: Duration(milliseconds: data.track.durationMs),
              artUri: artUri,
            ),
          );
        }

        // Sync queue only when queue structure/order actually changes
        final signature = playlist.medias.isEmpty
            ? ''
            : '${playlist.medias.length}:${playlist.medias.first.uri}:${playlist.medias.last.uri}';

        if (playlist.medias.length != _lastSyncedQueueLength ||
            signature != _lastSyncedQueueSignature) {
          _lastSyncedQueueLength = playlist.medias.length;
          _lastSyncedQueueSignature = signature;

          queue.add(
            playlist.medias.map((m) {
              final d = m.extras?['data'] as TrackWithArtists?;
              return MediaItem(
                id: m.uri,
                title: d?.track.title ?? m.uri,
                artist: d?.artists.map((a) => a.name).join(', ') ?? '',
                album: d?.album.title,
                duration: d != null ? Duration(milliseconds: d.track.durationMs) : null,
              );
            }).toList(),
          );
        }
      }),
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

  // --- Playback controls (media keys / OS transport controls) ---

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() async {
    await _player.stop();
    playbackState.add(
      playbackState.value.copyWith(
        processingState: AudioProcessingState.idle,
        playing: false,
      ),
    );
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) async {
    await _player.seek(position);
    _lastPositionBroadcast = DateTime.now();
    _broadcastState();
  }

  @override
  Future<void> skipToNext() => _player.next();

  @override
  Future<void> skipToPrevious() => _player.previous();

  @override
  Future<void> skipToQueueItem(int index) => _player.jump(index);

  /// Releases resources and cancels active stream subscriptions.
  Future<void> dispose() async {
    for (final sub in _subscriptions) {
      await sub.cancel();
    }
    _subscriptions.clear();
  }
}
