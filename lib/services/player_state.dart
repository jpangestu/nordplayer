import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:nordplayer/core/database/app_database.dart';
import 'package:nordplayer/core/services/preference_service.dart';
import 'package:nordplayer/core/utils/debouncer.dart';
import 'package:nordplayer/core/utils/stream_extension.dart';
import 'package:nordplayer/services/player_service.dart';

// ========================================== Playback Streams ==========================================

/// Stream provider for current track playback position.
final positionStreamProvider = StreamProvider<Duration>((ref) async* {
  final player = ref.watch(playerServiceProvider).mkPlayer;
  yield player.state.position;
  yield* player.stream.position;
});

/// Stream provider for audio playback buffer position.
final bufferStreamProvider = StreamProvider<Duration>((ref) async* {
  final player = ref.watch(playerServiceProvider).mkPlayer;
  yield player.state.buffer;
  yield* player.stream.buffer;
});

/// Stream provider for active media duration.
final durationStreamProvider = StreamProvider<Duration>((ref) async* {
  final player = ref.watch(playerServiceProvider).mkPlayer;
  yield player.state.duration;
  yield* player.stream.duration;
});

// ========================================== Playing State ============================================

/// Returns whether the audio player is currently playing a track.
final isPlayingProvider = NotifierProvider<IsPlayingNotifier, bool>(
  IsPlayingNotifier.new,
);

class IsPlayingNotifier extends Notifier<bool> {
  Timer? _debounceTimer;

  @override
  bool build() {
    final player = ref.watch(playerServiceProvider).mkPlayer;

    final playingSub = player.stream.playing.listen((isPlaying) {
      if (isPlaying) {
        _debounceTimer?.cancel();
        state = true;
      } else {
        _debounceTimer?.cancel();
        _debounceTimer = Timer(const Duration(milliseconds: 150), () {
          state = false;
        });
      }
    });

    ref.onDispose(() {
      playingSub.cancel();
      _debounceTimer?.cancel();
    });

    // Initial synchronous return for instant UI painting
    return player.state.playing;
  }
}

// ======================================= Playback Context ============================================

/// Tracks the active collection/navigation context from which playback was initiated.
final playbackContextProvider =
    NotifierProvider<PlaybackContextNotifier, PlaybackContext?>(
      PlaybackContextNotifier.new,
    );

class PlaybackContextNotifier extends Notifier<PlaybackContext?> {
  @override
  PlaybackContext? build() => null;

  void setContext(String type, int? id) {
    state = PlaybackContext(type: type, id: id);
  }
}

// ========================================= Current Track =============================================

/// Emits the currently playing track metadata with artist details.
final currentTrackProvider =
    NotifierProvider<CurrentTrackNotifier, TrackWithArtists?>(
      CurrentTrackNotifier.new,
    );

class CurrentTrackNotifier extends Notifier<TrackWithArtists?> {
  @override
  TrackWithArtists? build() {
    final player = ref.watch(playerServiceProvider).mkPlayer;

    final trackStream = player.stream.playlist
        .map((playlist) {
          if (playlist.medias.isEmpty ||
              playlist.index < 0 ||
              playlist.index >= playlist.medias.length) {
            return null;
          }
          return playlist.medias[playlist.index].extras?['data']
              as TrackWithArtists?;
        })
        .distinct((prev, next) {
          return prev?.track.filePath == next?.track.filePath;
        })
        .debounceTime(const Duration(milliseconds: 50));

    final subscription = trackStream.listen((currentTrack) {
      state = currentTrack;
      ref
          .read(preferenceServiceProvider.notifier)
          .setCachedAlbumArtPath(currentTrack?.album.albumArtPath);
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

    return initialPlaylist.medias[initialPlaylist.index].extras?['data']
        as TrackWithArtists?;
  }
}

// ====================================== Current Track Index ==========================================

/// Emits the active playlist index and coordinates queue scroll intents.
final currentTrackIndexProvider =
    NotifierProvider<CurrentTrackIndexNotifier, int>(
      CurrentTrackIndexNotifier.new,
    );

class CurrentTrackIndexNotifier extends Notifier<int> {
  @override
  int build() {
    final playerService = ref.watch(playerServiceProvider);
    final player = playerService.mkPlayer;
    final debouncer = Debouncer(const Duration(milliseconds: 50));

    final subscription = player.stream.playlist.listen((playlist) {
      debouncer(() {
        if (state != playlist.index) {
          if (!playerService.consumeSuppressNextScroll()) {
            final currentIntent = ref.read(queueScrollBehaviorProvider);
            if (currentIntent == QueueScrollBehavior.none) {
              ref
                  .read(queueScrollBehaviorProvider.notifier)
                  .setIntent(QueueScrollBehavior.animate);
            }
          }
          state = playlist.index;
        }
      });
    });

    ref.onDispose(() {
      debouncer.dispose();
      subscription.cancel();
    });

    return player.state.playlist.index;
  }
}

// ======================================= Queue Track List ============================================

/// Emits the list of tracks currently queued in the playback engine.
final currentTracksInQueueProvider =
    NotifierProvider<CurrentTracksInQueueNotifier, List<TrackWithArtists>>(
      CurrentTracksInQueueNotifier.new,
    );

class CurrentTracksInQueueNotifier extends Notifier<List<TrackWithArtists>> {
  @override
  List<TrackWithArtists> build() {
    final player = ref.watch(playerServiceProvider).mkPlayer;
    final debouncer = Debouncer(const Duration(milliseconds: 50));

    final subscription = player.stream.playlist.listen((playlist) {
      debouncer(() {
        state = playlist.medias
            .map((media) => media.extras?['data'])
            .whereType<TrackWithArtists>()
            .toList();
      });
    });

    ref.onDispose(() {
      debouncer.dispose();
      subscription.cancel();
    });

    return player.state.playlist.medias
        .map((media) => media.extras?['data'])
        .whereType<TrackWithArtists>()
        .toList();
  }

  void moveTrackOptimistically(int oldIndex, int newIndex) {
    final list = List<TrackWithArtists>.from(state);
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    state = list;
  }
}

// ======================================= Upcoming Album Art ==========================================

/// Emits album art paths for the active track and up to 4 upcoming tracks in queue.
final current5TracksAlbumArtInQueueProvider =
    NotifierProvider<Current5TracksAlbumArtNotifier, List<String>>(
      Current5TracksAlbumArtNotifier.new,
    );

class Current5TracksAlbumArtNotifier extends Notifier<List<String>> {
  @override
  List<String> build() {
    final player = ref.watch(playerServiceProvider).mkPlayer;
    final loopMode = ref.watch(
      preferenceServiceProvider.select((prefs) => prefs.loopMode),
    );
    final debouncer = Debouncer(const Duration(milliseconds: 150));

    final subscription = player.stream.playlist.listen((playlist) {
      debouncer(() {
        state = calculateCovers(playlist, loopMode);
      });
    });

    ref.onDispose(() {
      debouncer.dispose();
      subscription.cancel();
    });

    return calculateCovers(player.state.playlist, loopMode);
  }

  /// Pure computation for upcoming artwork paths given a playlist and loop configuration.
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
        final artPath = (track.album.albumArtPath?.isNotEmpty ?? false)
            ? track.album.albumArtPath!
            : '';
        stackCovers.add(artPath);
      }
    }

    return stackCovers;
  }
}
