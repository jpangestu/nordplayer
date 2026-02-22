import 'package:media_kit/media_kit.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nordplayer/database/app_database.dart';
import 'package:nordplayer/services/logger.dart';
import 'package:nordplayer/services/preference_service.dart';

final playerServiceProvider = Provider<PlayerService>((ref) {
  final service = PlayerService(ref);

  // 2. Riverpod automatically calls dispose when the app closes!
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
final isPlayingProvider = StreamProvider<bool>((ref) {
  final player = ref.watch(playerServiceProvider).mkPlayer;
  return player.stream.playing;
});

final currentSongProvider = StreamProvider<SongWithArtists?>((ref) {
  final player = ref.watch(playerServiceProvider).mkPlayer;

  return player.stream.playlist.map((playlist) {
    if (playlist.medias.isEmpty ||
        playlist.index < 0 ||
        playlist.index >= playlist.medias.length) {
      return null;
    }

    final currentMedia = playlist.medias[playlist.index];
    return currentMedia.extras?['data'] as SongWithArtists?;
  });
});

class PlayerService with LoggerMixin {
  final Ref ref;

  PlayerService(this.ref);

  final Player _mkPlayer = Player();
  Player get mkPlayer => _mkPlayer;

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

  /// Opens a list of songs as a Playlist and play the given index
  Future<void> setPlaylist(
    List<SongWithArtists> songs,
    int initialIndex,
  ) async {
    final bool shouldShuffle = ref.read(preferenceServiceProvider).shuffleMode;

    final playableMedia = songs.map((song) {
      return Media(
        song.track.filePath,
        extras: {
          'title': song.track.title,
          'artists': song.artists,
          'data': song,
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
