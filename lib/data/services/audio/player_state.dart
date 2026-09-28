import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:nordplayer/data/services/audio/playback_controller.dart';
import 'package:nordplayer/data/services/system/preference_service.dart';
import 'package:nordplayer/domain/models/composite_models.dart';
import 'package:nordplayer/domain/models/playback_context.dart';
import 'package:nordplayer/ui/queue/queue_scroll_behavior.dart';

// ========================================== Playback Streams ==========================================

/// Stream provider for current track playback position.
final positionStreamProvider = StreamProvider<Duration>((ref) {
  final controller = ref.watch(playbackControllerProvider);
  return controller.watchPosition();
});

/// Stream provider for active media duration.
final durationStreamProvider = StreamProvider<Duration>((ref) {
  final controller = ref.watch(playbackControllerProvider);
  return controller.watchDuration();
});

// ========================================== Playing State ============================================

/// Returns whether the audio player is currently playing a track.
final isPlayingProvider = NotifierProvider<IsPlayingNotifier, bool>(IsPlayingNotifier.new);

class IsPlayingNotifier extends Notifier<bool> {
  @override
  bool build() {
    final controller = ref.watch(playbackControllerProvider);

    final subscription = controller.watchIsPlaying().listen((playing) {
      state = playing;
    });

    ref.onDispose(subscription.cancel);
    return controller.isPlaying;
  }
}

// ======================================= Playback Context ============================================

/// Tracks the active collection/navigation context from which playback was initiated.
final playbackContextProvider = NotifierProvider<PlaybackContextNotifier, PlaybackContext?>(
  PlaybackContextNotifier.new,
);

class PlaybackContextNotifier extends Notifier<PlaybackContext?> {
  @override
  PlaybackContext? build() {
    final controller = ref.watch(playbackControllerProvider);

    final subscription = controller.watchPlaybackContext().listen((ctx) {
      state = ctx;
    });

    ref.onDispose(subscription.cancel);
    return controller.playbackContext;
  }

  void setContext(String type, int? id) {
    state = PlaybackContext(type: type, id: id);
  }
}

// ========================================= Current Track =============================================

/// Emits the currently playing track metadata with artist details.
final currentTrackProvider = NotifierProvider<CurrentTrackNotifier, TrackWithArtists?>(CurrentTrackNotifier.new);

class CurrentTrackNotifier extends Notifier<TrackWithArtists?> {
  @override
  TrackWithArtists? build() {
    final controller = ref.watch(playbackControllerProvider);

    final subscription = controller.watchCurrentTrack().listen((currentTrack) {
      state = currentTrack;
      final artPath = currentTrack?.album.albumArtPath;
      if (artPath != null && artPath.isNotEmpty) {
        ref.read(preferenceServiceProvider.notifier).setCachedAlbumArtPath(artPath);
      }
    });

    ref.onDispose(subscription.cancel);

    final initialTrack = controller.currentTrack;
    final artPath = initialTrack?.album.albumArtPath;
    if (artPath != null && artPath.isNotEmpty) {
      Future.microtask(() {
        ref.read(preferenceServiceProvider.notifier).setCachedAlbumArtPath(artPath);
      });
    }

    return initialTrack;
  }
}

// ====================================== Current Track Index ==========================================

/// Emits the active playlist index and coordinates queue scroll intents.
final currentTrackIndexProvider = NotifierProvider<CurrentTrackIndexNotifier, int>(CurrentTrackIndexNotifier.new);

class CurrentTrackIndexNotifier extends Notifier<int> {
  @override
  int build() {
    final controller = ref.watch(playbackControllerProvider);

    final subscription = controller.watchCurrentIndex().listen((index) {
      if (state != index) {
        final currentIntent = ref.read(queueScrollBehaviorProvider);
        if (currentIntent == QueueScrollBehavior.none) {
          ref.read(queueScrollBehaviorProvider.notifier).setIntent(QueueScrollBehavior.animate);
        }
        state = index;
      }
    });

    ref.onDispose(subscription.cancel);
    return controller.currentIndex;
  }
}

// ======================================= Queue Track List ============================================

/// Emits the list of tracks currently queued in the playback engine.
final currentTracksInQueueProvider = NotifierProvider<CurrentTracksInQueueNotifier, List<TrackWithArtists>>(
  CurrentTracksInQueueNotifier.new,
);

class CurrentTracksInQueueNotifier extends Notifier<List<TrackWithArtists>> {
  @override
  List<TrackWithArtists> build() {
    final controller = ref.watch(playbackControllerProvider);

    final subscription = controller.watchQueue().listen((tracks) {
      state = tracks;
    });

    ref.onDispose(subscription.cancel);
    return controller.currentQueue;
  }

  void moveTrackOptimistically(int oldIndex, int newIndex) {
    final list = List<TrackWithArtists>.from(state);
    if (oldIndex >= 0 && oldIndex < list.length && newIndex >= 0 && newIndex <= list.length) {
      final item = list.removeAt(oldIndex);
      final targetIndex = newIndex.clamp(0, list.length);
      list.insert(targetIndex, item);
      state = list;
    }
  }
}

// ======================================= Upcoming Album Art ==========================================

/// Emits album art paths for the active track and up to 4 upcoming tracks in queue.
final current5TracksAlbumArtInQueueProvider = NotifierProvider<Current5TracksAlbumArtNotifier, List<String>>(
  Current5TracksAlbumArtNotifier.new,
);

class Current5TracksAlbumArtNotifier extends Notifier<List<String>> {
  @override
  List<String> build() {
    final controller = ref.watch(playbackControllerProvider);

    final subscription = controller.watchQueueCoverArt().listen((covers) {
      state = covers;
    });

    ref.onDispose(subscription.cancel);
    return controller.currentQueueCoverArt;
  }

  /// Pure computation for upcoming artwork paths given a playlist and loop configuration.
  /// Maintained for unit test compatibility.
  static List<String> calculateCovers(Playlist playlist, PlaylistMode loopMode) {
    if (playlist.medias.isEmpty || playlist.index < 0) {
      return const [];
    }

    final int currentIndex = playlist.index;
    final List<Media> allMedia = playlist.medias;
    final List<String> stackCovers = [];

    for (int count = 0; count < allMedia.length && stackCovers.length < 5; count++) {
      int targetIndex = currentIndex + count;

      if (targetIndex >= allMedia.length) {
        if (loopMode == PlaylistMode.loop) {
          targetIndex = targetIndex % allMedia.length;
        } else {
          break;
        }
      }

      final track = allMedia[targetIndex].extras?['data'] as TrackWithArtists?;
      if (track != null) {
        final artPath = (track.album.albumArtPath?.isNotEmpty ?? false) ? track.album.albumArtPath! : '';
        stackCovers.add(artPath);
      }
    }

    return stackCovers;
  }
}
