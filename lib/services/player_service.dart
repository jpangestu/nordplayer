import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:nordplayer/database/app_database.dart';
import 'package:nordplayer/services/logger.dart';
import 'package:nordplayer/services/preference_service.dart';

class PlayerService with LoggerMixin {
  PlayerService._instance();
  static final PlayerService _singleton = PlayerService._instance();
  factory PlayerService() => _singleton;

  final Player _player = Player();
  Player get player => _player;

  final _prefs = PreferenceService();

  /// Initialize with saved preferences
  Future<void> init() async {
    // try {
    //   await _player.setVolume(_prefs.volume);
    //   await _player.setPlaylistMode(_prefs.loopMode);
    //   log.i(
    //     "PlayerService initialized:\n"
    //     "Vol ${_prefs.volume},\n"
    //     "Loop ${_prefs.loopMode}",
    //   );
    // } catch (e) {
    //   log.e("Error during PlayerService init: $e");
    // }
  }

  /// Use value notifier instead of media kit stream to avoid flicker
  /// while switching to new playlist (new player)
  final ValueNotifier<bool> isPlaying = ValueNotifier<bool>(false);

  /// Opens a list of songs as a Playlist and play the given index
  Future<void> setPlaylist(
    List<SongWithArtists> songs,
    int initialIndex,
  ) async {
    final bool shouldShuffle = _prefs.shuffleMode;
    isPlaying.value = true;

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
      await _player.open(
        Playlist(playableMedia, index: initialIndex),
        play: true,
      );
    } catch (e) {
      log.e("Error loading media_kit playlist: $e");
    }

    if (shouldShuffle) {
      await Future.delayed(const Duration(milliseconds: 100));
      await _player.setShuffle(true);
    }
  }

  Future<void> playOrPause() async {
    if (_player.state.playlist.medias.isEmpty) return;
    await _player.playOrPause();
    isPlaying.value = _player.state.playing;
  }

  Future<void> next() async => await _player.next();
  Future<void> previous() async => await _player.previous();

  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume);
    _prefs.setVolume(volume);
  }

  Future<void> toggleShuffle() async {
    if (_player.state.playlist.medias.isEmpty) {
      final newState = !_prefs.shuffleMode;
      _prefs.setShuffleMode(newState);
      log.w("Shuffle toggled while playlist is empty. Saving preference only.");
      return;
    }

    final bool newState = !_player.state.shuffle;
    await _player.setShuffle(newState);
    _prefs.setShuffleMode(newState);
  }

  /// Cycle through Loop Modes. logic: Off -> All -> Single -> Off
  Future<void> cycleLoopMode() async {
    final current = _prefs.loopMode;

    final next = switch (current) {
      PlaylistMode.none => PlaylistMode.loop,
      PlaylistMode.loop => PlaylistMode.single,
      PlaylistMode.single => PlaylistMode.none,
    };

    await _player.setPlaylistMode(next);
    _prefs.setLoopMode(next);
  }

  /// Dispose when the app closes
  Future<void> dispose() async {
    await _player.dispose();
  }
}
