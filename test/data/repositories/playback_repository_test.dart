import 'package:flutter_test/flutter_test.dart';
import 'package:media_kit/media_kit.dart' hide Track;
import 'package:nordplayer/data/repositories/playback_repository.dart';
import 'package:nordplayer/data/repositories/queue_repository.dart';
import 'package:nordplayer/domain/models/album.dart';
import 'package:nordplayer/domain/models/artist.dart';
import 'package:nordplayer/domain/models/composite_models.dart';
import 'package:nordplayer/domain/models/playback_context.dart';
import 'package:nordplayer/domain/models/track.dart';
import 'package:nordplayer/domain/queue/queue_models.dart';

import '../../../testing/fakes/fake_audio_player_engine.dart';
import '../../../testing/fakes/fake_settings_repository.dart';

class _FakeQueueRepository implements QueueRepository {
  List<TrackWithArtists> savedQueue = [];
  String? savedCurrentTrackPath;
  Duration savedPosition = Duration.zero;
  String savedContextType = '';
  int? savedContextId;
  int? updatedPositionMs;
  QueueState? savedQueueState;
  int? updatedActiveIndex;
  String? updatedActiveTrackPath;
  int? updatedActiveTrackId;
  bool? updatedIsShuffle;
  List<int>? updatedShuffleIndices;
  String? updatedLoopMode;

  @override
  Future<void> saveQueue(
    List<TrackWithArtists> originalQueue,
    String? currentlyPlayedTrackPath,
    Duration resumePositionMs,
    String playbackContextType,
    int? playbackContextId,
  ) async {
    savedQueue = List.from(originalQueue);
    savedCurrentTrackPath = currentlyPlayedTrackPath;
    savedPosition = resumePositionMs;
    savedContextType = playbackContextType;
    savedContextId = playbackContextId;
  }

  @override
  Future<void> saveQueueState(QueueState state, Duration resumePosition) async {
    savedQueueState = state;
    savedQueue = state.tracks;
    savedCurrentTrackPath = state.currentItem?.track.track.filePath;
    savedPosition = resumePosition;
    savedContextType = state.context.type;
    savedContextId = state.context.id;
  }

  @override
  Future<void> updateActiveTrack(int activeIndex, String? activeTrackPath, {int? activeTrackId}) async {
    updatedActiveIndex = activeIndex;
    updatedActiveTrackPath = activeTrackPath;
    updatedActiveTrackId = activeTrackId;
  }

  @override
  Future<void> updateCurrentPosition(int positionInMs) async {
    updatedPositionMs = positionInMs;
  }

  @override
  Future<void> updateShuffleMode({
    required bool isShuffle,
    required List<int> shuffleIndices,
    required int activeIndex,
    String? activeTrackPath,
    int? activeTrackId,
  }) async {
    updatedIsShuffle = isShuffle;
    updatedShuffleIndices = List.from(shuffleIndices);
    updatedActiveIndex = activeIndex;
    updatedActiveTrackPath = activeTrackPath;
    updatedActiveTrackId = activeTrackId;
  }

  @override
  Future<void> updateLoopMode(String loopMode) async {
    updatedLoopMode = loopMode;
  }

  @override
  Future<RestoredQueueState?> restoreQueueState() async {
    if (savedQueueState != null) {
      return RestoredQueueState(state: savedQueueState!, resumePosition: savedPosition);
    }
    if (savedQueue.isNotEmpty) {
      final items = [
        for (var i = 0; i < savedQueue.length; i++)
          QueueItem.create(track: savedQueue[i], originalOrder: i),
      ];
      return RestoredQueueState(
        state: QueueState(
          items: items,
          shuffleIndices: List.generate(items.length, (i) => i),
          activeIndex: 0,
          isShuffle: false,
          loopMode: LoopMode.off,
          context: PlaybackContext(type: savedContextType, id: savedContextId),
        ),
        resumePosition: savedPosition,
      );
    }
    return null;
  }

  @override
  Future<(List<TrackWithArtists>, int, Duration, String, int?)> loadQueue() async {
    return (savedQueue, 0, savedPosition, savedContextType, savedContextId);
  }
}

TrackWithArtists _makeTrack(int id, String title, {String path = '/music/test.mp3', String? art}) {
  return TrackWithArtists(
    track: Track(
      id: id,
      title: title,
      filePath: path,
      fileHash: 'hash_$id',
      durationMs: 180000,
      fileSize: 1024,
      artistId: 1,
      albumId: 1,
      dateAdded: DateTime.now(),
    ),
    album: Album(id: 1, title: 'Test Album', albumArtPath: art),
    artists: [const Artist(id: 1, name: 'Test Artist')],
  );
}

void main() {
  group('DefaultPlaybackRepository', () {
    late FakeAudioPlayerEngine engine;
    late _FakeQueueRepository queueRepo;
    late FakeSettingsRepository settingsRepo;
    late DefaultPlaybackRepository repo;

    final track1 = _makeTrack(1, 'Song Alpha', path: '/music/alpha.mp3', art: '/covers/alpha.jpg');
    final track2 = _makeTrack(2, 'Song Beta', path: '/music/beta.mp3', art: '/covers/beta.jpg');
    final track3 = _makeTrack(3, 'Song Gamma', path: '/music/gamma.mp3', art: '/covers/gamma.jpg');

    setUp(() {
      engine = FakeAudioPlayerEngine();
      queueRepo = _FakeQueueRepository();
      settingsRepo = FakeSettingsRepository();

      repo = DefaultPlaybackRepository(engine, queueRepo, settingsRepo);
    });

    tearDown(() async {
      repo.dispose();
      await engine.dispose();
    });

    test('initial state when uninitialized', () {
      expect(repo.currentQueue, isEmpty);
      expect(repo.currentTrack, isNull);
      expect(repo.currentIndex, -1);
      expect(repo.currentQueueCoverArt, isEmpty);
      expect(repo.isShuffle, isFalse);
      expect(repo.loopMode, PlaylistMode.none);
    });

    test('setPlaylist initializes queue, loads current track, and preloads next track for gapless', () async {
      await repo.setPlaylist(
        tracksToPlay: [track1, track2, track3],
        initialIndex: 0,
        playbackContextType: 'album',
        playbackContextId: 1,
      );

      expect(repo.currentQueue.length, 3);
      expect(repo.currentIndex, 0);
      expect(repo.currentTrack?.track.title, 'Song Alpha');
      expect(engine.currentUri, track1.track.filePath);
      expect(engine.nextUri, track2.track.filePath);
      expect(engine.isPlaying, isTrue);

      // Verify covers
      expect(repo.currentQueueCoverArt, ['/covers/alpha.jpg', '/covers/beta.jpg', '/covers/gamma.jpg']);
    });

    test('next advances queue, opens next track, and updates next media', () async {
      await repo.setPlaylist(tracksToPlay: [track1, track2, track3], initialIndex: 0, playbackContextType: 'album');

      await repo.next();

      expect(repo.currentIndex, 1);
      expect(repo.currentTrack?.track.title, 'Song Beta');
      expect(engine.currentUri, track2.track.filePath);
      expect(engine.nextUri, track3.track.filePath);
      expect(queueRepo.updatedActiveIndex, 1);
      expect(queueRepo.updatedActiveTrackPath, track2.track.filePath);
    });

    test('previous restarts active track if position >= 3s, or steps back if < 3s', () async {
      await repo.setPlaylist(tracksToPlay: [track1, track2, track3], initialIndex: 1, playbackContextType: 'album');

      // Past 3 seconds -> restarts current track
      engine.updatePosition(const Duration(seconds: 5));
      await repo.previous();
      expect(repo.currentIndex, 1);

      // Under 3 seconds -> steps back to previous track
      engine.updatePosition(const Duration(seconds: 1));
      await repo.previous();
      expect(repo.currentIndex, 0);
      expect(repo.currentTrack?.track.title, 'Song Alpha');
      expect(queueRepo.updatedActiveIndex, 0);
      expect(queueRepo.updatedActiveTrackPath, track1.track.filePath);
    });

    test('jumpToIndex sets target track and pre-buffers subsequent track', () async {
      await repo.setPlaylist(tracksToPlay: [track1, track2, track3], initialIndex: 0, playbackContextType: 'album');

      await repo.jumpToIndex(2);

      expect(repo.currentIndex, 2);
      expect(repo.currentTrack?.track.title, 'Song Gamma');
      expect(engine.currentUri, track3.track.filePath);
      expect(engine.nextUri, isNull); // Reached end with loopMode off
      expect(queueRepo.updatedActiveIndex, 2);
      expect(queueRepo.updatedActiveTrackPath, track3.track.filePath);
    });

    test('seek immediately updates active position via delta', () async {
      await repo.setPlaylist(tracksToPlay: [track1, track2], initialIndex: 0, playbackContextType: 'album');

      await repo.seek(const Duration(seconds: 42));

      expect(engine.position, const Duration(seconds: 42));
      expect(queueRepo.updatedPositionMs, 42000);
    });

    test('completedStream triggers gapless auto-advance without reopening when engine already transitioned', () async {
      await repo.setPlaylist(tracksToPlay: [track1, track2, track3], initialIndex: 0, playbackContextType: 'album');

      expect(engine.nextUri, track2.track.filePath);

      // Simulate native gapless transition in engine
      await engine.simulateGaplessTransition();

      // Ensure completedStream handler ran
      await pumpEventQueue();

      expect(repo.currentIndex, 1);
      expect(repo.currentTrack?.track.title, 'Song Beta');
      // Next track Gamma is now pre-buffered into the 2-track window
      expect(engine.nextUri, track3.track.filePath);
    });

    test('completedStream in LoopMode.single naturally loops and re-opens current track', () async {
      await repo.setPlaylist(
        tracksToPlay: [track1, track2],
        initialIndex: 0,
        playbackContextType: 'album',
      );
      await repo.toggleLoop(); // Changes to PlaylistMode.single (LoopMode.single)

      expect(repo.loopMode, PlaylistMode.single);
      expect(engine.nextUri, track1.track.filePath);

      // Simulate natural EOF completion (isPlaying becomes false)
      engine.simulateTrackCompleted();
      await pumpEventQueue();

      expect(repo.currentIndex, 0);
      expect(repo.currentTrack?.track.title, 'Song Alpha');
      expect(engine.currentUri, track1.track.filePath);
      expect(engine.isPlaying, isTrue);
    });

    test('playNext inserts tracks immediately after active track as userNext', () async {
      await repo.setPlaylist(tracksToPlay: [track1, track3], initialIndex: 0, playbackContextType: 'album');

      await repo.playNext([track2]);

      expect(repo.currentQueue.length, 3);
      expect(repo.currentQueue[1].track.title, 'Song Beta');
      expect(repo.currentQueueItems[1].source, QueueSource.userNext);
      expect(engine.nextUri, track2.track.filePath);
    });

    test('addToQueue appends tracks to end of queue as userQueue', () async {
      await repo.setPlaylist(tracksToPlay: [track1], initialIndex: 0, playbackContextType: 'album');

      await repo.addToQueue([track2]);

      expect(repo.currentQueue.length, 2);
      expect(repo.currentQueue[1].track.title, 'Song Beta');
      expect(repo.currentQueueItems[1].source, QueueSource.userQueue);
      expect(engine.nextUri, track2.track.filePath);
    });

    test('removeQueueItem removes track and keeps active track aligned', () async {
      await repo.setPlaylist(tracksToPlay: [track1, track2, track3], initialIndex: 0, playbackContextType: 'album');

      await repo.removeQueueItem(1); // Remove Song Beta

      expect(repo.currentQueue.length, 2);
      expect(repo.currentQueue.map((t) => t.track.title).toList(), ['Song Alpha', 'Song Gamma']);
      expect(engine.nextUri, track3.track.filePath);
    });

    test('removeTrackByPath and removeTracksByPaths purge tracks by file path', () async {
      await repo.setPlaylist(tracksToPlay: [track1, track2, track3], initialIndex: 0, playbackContextType: 'album');

      await repo.removeTrackByPath(track2.track.filePath);
      expect(repo.currentQueue.length, 2);

      await repo.removeTracksByPaths({track3.track.filePath});
      expect(repo.currentQueue.length, 1);
      expect(repo.currentQueue.first.track.title, 'Song Alpha');
    });

    test('reorderQueue moves track position and updates streams', () async {
      await repo.setPlaylist(tracksToPlay: [track1, track2, track3], initialIndex: 0, playbackContextType: 'album');

      await repo.reorderQueue(0, 2); // Move Alpha to index 2

      expect(repo.currentQueue[0].track.title, 'Song Beta');
      expect(repo.currentQueue[2].track.title, 'Song Alpha');
      expect(repo.currentIndex, 2); // Active track tracking preserved
    });

    test('sortBy sorts queue and anchors active track, revertSort restores original context order', () async {
      await repo.setPlaylist(
        tracksToPlay: [track3, track1, track2], // Gamma, Alpha, Beta
        initialIndex: 0, // Playing Gamma
        playbackContextType: 'album',
      );

      await repo.sortBy(QueueSortCriteria.title, ascending: true);

      // Alphabetical: Alpha, Beta, Gamma
      expect(repo.currentQueue.map((t) => t.track.title).toList(), ['Song Alpha', 'Song Beta', 'Song Gamma']);
      // Gamma was active and should be anchored at index 2
      expect(repo.currentIndex, 2);
      expect(repo.currentTrack?.track.title, 'Song Gamma');

      // Revert to original order
      await repo.revertSort();
      expect(repo.currentQueue.map((t) => t.track.title).toList(), ['Song Gamma', 'Song Alpha', 'Song Beta']);
      expect(repo.currentIndex, 0);
    });

    test('toggleShuffle enables non-destructive shuffle and updates next media', () async {
      await repo.setPlaylist(
        tracksToPlay: [track1, track2, track3],
        initialIndex: 1, // Playing Beta
        playbackContextType: 'album',
      );

      await repo.toggleShuffle();

      expect(repo.isShuffle, isTrue);
      expect(settingsRepo.currentSettings.shuffleMode, isTrue);
      // In shuffle mode, current active track is pinned to display index 0
      expect(repo.currentIndex, 0);
      expect(repo.currentTrack?.track.title, 'Song Beta');
      expect(queueRepo.updatedIsShuffle, isTrue);
      expect(queueRepo.updatedActiveIndex, 0);
      expect(queueRepo.updatedActiveTrackPath, track2.track.filePath);

      // Toggling off restores original sequence
      await repo.toggleShuffle();
      expect(repo.isShuffle, isFalse);
      expect(repo.currentQueue.map((t) => t.track.title).toList(), ['Song Alpha', 'Song Beta', 'Song Gamma']);
      expect(repo.currentIndex, 1);
      expect(queueRepo.updatedIsShuffle, isFalse);
      expect(queueRepo.updatedActiveIndex, 1);
    });

    test('toggleLoop cycles through LoopMode.off -> single -> all -> off', () async {
      await repo.setPlaylist(tracksToPlay: [track1, track2], initialIndex: 0, playbackContextType: 'album');

      expect(repo.loopMode, PlaylistMode.none);

      await repo.toggleLoop();
      expect(repo.loopMode, PlaylistMode.single);
      expect(settingsRepo.currentSettings.loopMode, PlaylistMode.single);
      expect(queueRepo.updatedLoopMode, 'single');

      await repo.toggleLoop();
      expect(repo.loopMode, PlaylistMode.loop);
      expect(settingsRepo.currentSettings.loopMode, PlaylistMode.loop);

      await repo.toggleLoop();
      expect(repo.loopMode, PlaylistMode.none);
      expect(settingsRepo.currentSettings.loopMode, PlaylistMode.none);
    });

    test('clearQueue pauses playback and resets all queue state', () async {
      await repo.setPlaylist(tracksToPlay: [track1, track2], initialIndex: 0, playbackContextType: 'album');

      await repo.clearQueue();

      expect(repo.currentQueue, isEmpty);
      expect(repo.currentTrack, isNull);
      expect(repo.currentIndex, -1);
      expect(engine.isPlaying, isFalse);
      expect(engine.nextUri, isNull);
    });

    test('restoreQueue loads saved queue from persistence and restores state with autoplay false', () async {
      queueRepo.savedQueue = [track1, track2];
      queueRepo.savedPosition = const Duration(seconds: 45);
      queueRepo.savedContextType = 'album';
      queueRepo.savedContextId = 1;

      await repo.restoreQueue();

      expect(repo.currentQueue.length, 2);
      expect(repo.currentTrack?.track.title, 'Song Alpha');
      expect(engine.currentUri, track1.track.filePath);
      expect(engine.position, const Duration(seconds: 45));
      expect(engine.isPlaying, isFalse); // restoreQueue should not autoplay
      expect(engine.nextUri, track2.track.filePath);
    });

    test('volume and mute controls delegate to engine and settings repository', () async {
      await repo.setVolume(75.0);
      expect(engine.volume, 75.0);
      expect(settingsRepo.currentSettings.volume, 75.0);

      await repo.setVolumeUp(10.0);
      expect(engine.volume, 85.0);

      await repo.setVolumeDown(20.0);
      expect(engine.volume, 65.0);

      await repo.toggleMute();
      expect(repo.isMuted, isTrue);
      expect(engine.volume, 0.0);

      await repo.toggleMute();
      expect(repo.isMuted, isFalse);
      expect(engine.volume, 65.0);
    });

    test('dispose immediately flushes any pending debounced queue state save', () async {
      await repo.setPlaylist(tracksToPlay: [track1, track2], initialIndex: 0, playbackContextType: 'album');
      expect(queueRepo.savedQueueState, isNull);

      await repo.addToQueue([track3]);
      expect(queueRepo.savedQueueState, isNull);

      repo.dispose();
      expect(queueRepo.savedQueueState, isNotNull);
      expect(queueRepo.savedQueueState?.items.length, 3);
    });

    test('setPlaylist with typed PlaybackContext preserves type, id, and title', () async {
      const context = PlaybackContext.album(id: 42, title: 'Abbey Road');
      await repo.setPlaylist(
        tracksToPlay: [track1, track2],
        initialIndex: 0,
        context: context,
      );

      expect(repo.playbackContext, equals(context));
      expect(repo.playbackContext.type, 'album');
      expect(repo.playbackContext.id, 42);
      expect(repo.playbackContext.title, 'Abbey Road');
      expect(repo.playbackContextType, 'album');
      expect(repo.playbackContextId, 42);
    });

    test('setPlaylist with backward-compatible primitives resolves and preserves title', () async {
      await repo.setPlaylist(
        tracksToPlay: [track1, track2],
        initialIndex: 0,
        playbackContextType: 'playlist',
        playbackContextId: 99,
        playbackContextTitle: 'Favorites',
      );

      expect(repo.playbackContext.type, 'playlist');
      expect(repo.playbackContext.id, 99);
      expect(repo.playbackContext.title, 'Favorites');
    });

    test('watchPlaybackContext and watchCurrentTrack immediately emit current state on subscription', () async {
      const context = PlaybackContext.album(id: 12, title: 'Dark Side');
      await repo.setPlaylist(
        tracksToPlay: [track1, track2],
        initialIndex: 1,
        context: context,
      );

      final emittedContext = await repo.watchPlaybackContext().first;
      expect(emittedContext, equals(context));

      final emittedTrack = await repo.watchCurrentTrack().first;
      expect(emittedTrack?.track.id, equals(track2.track.id));

      final emittedIndex = await repo.watchCurrentIndex().first;
      expect(emittedIndex, equals(1));

      final emittedQueue = await repo.watchQueue().first;
      expect(emittedQueue.length, equals(2));
    });

    test('watchQueueState emits latest QueueState and derived streams deduplicate redundant events', () async {
      final stateEvents = <QueueState>[];
      final trackEvents = <TrackWithArtists?>[];
      final indexEvents = <int>[];
      final queueEvents = <List<TrackWithArtists>>[];

      final stateSub = repo.watchQueueState().listen(stateEvents.add);
      final trackSub = repo.watchCurrentTrack().listen(trackEvents.add);
      final indexSub = repo.watchCurrentIndex().listen(indexEvents.add);
      final queueSub = repo.watchQueue().listen(queueEvents.add);

      // Initial empty state emitted on subscription
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(stateEvents.length, equals(1));
      expect(trackEvents.length, equals(1));
      expect(indexEvents.length, equals(1));
      expect(queueEvents.length, equals(1));

      // 1. setPlaylist emits new state to all streams
      await repo.setPlaylist(
        tracksToPlay: [track1, track2],
        initialIndex: 0,
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(stateEvents.length, equals(2));
      expect(trackEvents.length, equals(2));
      expect(indexEvents.length, equals(2)); // from -1 to 0
      expect(queueEvents.length, equals(2)); // from [] to [track1, track2]
      expect(trackEvents.last?.track.id, equals(track1.track.id));

      // 2. addToQueue modifies queue, but active track and active index do NOT change.
      // watchCurrentTrack and watchCurrentIndex must NOT emit redundant duplicate events!
      await repo.addToQueue([track3]);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(stateEvents.length, equals(3));
      expect(queueEvents.length, equals(3)); // Queue changed from 2 to 3 items
      expect(trackEvents.length, equals(2)); // Deduplicated! Still track1
      expect(indexEvents.length, equals(2)); // Deduplicated! Still index 0

      // 3. Advancing to next track changes active track and index, but queue list does NOT change!
      // watchQueue must NOT emit redundant duplicate list event!
      await repo.next();
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(stateEvents.length, equals(4));
      expect(trackEvents.length, equals(3)); // Emits track2
      expect(indexEvents.length, equals(3)); // Emits index 1
      expect(queueEvents.length, equals(3)); // Deduplicated! Queue content is still [track1, track2, track3]

      await stateSub.cancel();
      await trackSub.cancel();
      await indexSub.cancel();
      await queueSub.cancel();
    });
  });
}
