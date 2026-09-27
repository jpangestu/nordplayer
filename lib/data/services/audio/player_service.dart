import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:nordplayer/data/services/system/preference_service.dart';
import 'package:nordplayer/ui/queue/queue_scroll_behavior.dart';
import 'package:nordplayer/utils/logger.dart';

/// Audio player service managing transport volume, mute, and playback triggers.
class PlayerService(
  final Ref _ref,
  final Player _mkPlayer, {
  final bool disposePlayer = true,
}) with LoggerMixin {
  final bool _disposePlayer = disposePlayer;
  Player get mkPlayer => _mkPlayer;

  bool _shouldSuppressNextScroll = false;
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  /// Backward-compatible named constructor for test or legacy callers.
  new withPlayer(Ref ref, Player player, {bool disposePlayer = true})
      : this(ref, player, disposePlayer: disposePlayer);

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

  // ============================================= Playback ===========================================================

  Future<void> playOrPause() async {
    if (_mkPlayer.state.playlist.medias.isEmpty) return;
    await _mkPlayer.playOrPause();
  }

  Future<void> next() async {
    _ref.read(queueScrollBehaviorProvider.notifier).setIntent(QueueScrollBehavior.animate);
    await _mkPlayer.next();
  }

  Future<void> previous() async {
    _ref.read(queueScrollBehaviorProvider.notifier).setIntent(QueueScrollBehavior.animate);
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
      await _mkPlayer.setShuffle(false);
    }

    _ref.read(queueScrollBehaviorProvider.notifier).setIntent(QueueScrollBehavior.jump);
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
    if (_disposePlayer) {
      await _mkPlayer.dispose();
    }
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
  final service = PlayerService(ref, player, disposePlayer: false);
  ref.onDispose(() => service.dispose());
  return service;
});
