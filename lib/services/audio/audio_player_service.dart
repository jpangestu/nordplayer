import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:nordplayer/services/audio/player_service.dart' show audioPlayerProvider;

/// Stateless service wrapper around [media_kit.Player].
///
/// Encapsulates native audio playback operations and exposes clean Dart streams.
class AudioPlayerService(
  final Player _player,
) {

  /// Access to the underlying [Player] instance for native platform handlers.
  Player get rawPlayer => _player;

  // Playback Control Methods
  Future<void> open(Playable playable, {bool play = true}) => _player.open(playable, play: play);

  Future<void> play() => _player.play();

  Future<void> pause() => _player.pause();

  Future<void> playOrPause() => _player.playOrPause();

  Future<void> stop() => _player.stop();

  Future<void> seek(Duration position) => _player.seek(position);

  Future<void> setVolume(double volume) => _player.setVolume(volume);

  Future<void> setRate(double rate) => _player.setRate(rate);

  Future<void> setPlaylistMode(PlaylistMode mode) => _player.setPlaylistMode(mode);

  // Playback State Streams
  Stream<bool> get playingStream => _player.stream.playing;

  Stream<Duration> get positionStream => _player.stream.position;

  Stream<Duration> get durationStream => _player.stream.duration;

  Stream<Duration> get bufferStream => _player.stream.buffer;

  Stream<double> get volumeStream => _player.stream.volume;

  Stream<bool> get completedStream => _player.stream.completed;

  Stream<Playlist> get playlistStream => _player.stream.playlist;

  // Snapshot State
  bool get isPlaying => _player.state.playing;

  Duration get position => _player.state.position;

  Duration get duration => _player.state.duration;

  double get volume => _player.state.volume;

  Playlist get playlist => _player.state.playlist;

  Future<void> dispose() => _player.dispose();
}

/// Riverpod provider for [AudioPlayerService].
final audioPlayerServiceProvider = Provider<AudioPlayerService>((ref) {
  final player = ref.watch(audioPlayerProvider);
  return AudioPlayerService(player);
});
