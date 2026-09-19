import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:media_kit/media_kit.dart' hide Track;
import 'package:nordplayer/core/database/app_database.dart';
import 'package:nordplayer/core/services/preference_service.dart';
import 'package:nordplayer/data/repositories/queue_repository.dart';
import 'package:nordplayer/services/player_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

class FakePlayerStream extends Fake implements PlayerStream {
  final _playlistController = StreamController<Playlist>.broadcast();
  final _positionController = StreamController<Duration>.broadcast();

  @override
  Stream<Playlist> get playlist => _playlistController.stream;

  @override
  Stream<Duration> get position => _positionController.stream;

  void dispose() {
    _playlistController.close();
    _positionController.close();
  }
}

class FakePlayerState extends Fake implements PlayerState {
  @override
  Playlist playlist = const Playlist([]);

  @override
  Duration position = Duration.zero;

  @override
  bool playing = false;

  @override
  bool shuffle = false;

  @override
  Duration duration = Duration.zero;
}

class FakePlayer extends Fake implements Player {
  final fakeStreams = FakePlayerStream();
  final fakeState = FakePlayerState();

  double volume = 100.0;
  PlaylistMode playlistMode = PlaylistMode.none;
  bool isDisposed = false;
  int playCallCount = 0;
  int pauseCallCount = 0;
  int playOrPauseCallCount = 0;
  int nextCallCount = 0;
  int previousCallCount = 0;

  @override
  PlayerStream get stream => fakeStreams;

  @override
  PlayerState get state => fakeState;

  @override
  Future<void> setVolume(double value) async {
    volume = value;
  }

  @override
  Future<void> setPlaylistMode(PlaylistMode mode) async {
    playlistMode = mode;
  }

  @override
  Future<void> setShuffle(bool value) async {
    fakeState.shuffle = value;
  }

  @override
  Future<void> play() async {
    playCallCount++;
    fakeState.playing = true;
  }

  @override
  Future<void> pause() async {
    pauseCallCount++;
    fakeState.playing = false;
  }

  @override
  Future<void> playOrPause() async {
    playOrPauseCallCount++;
    fakeState.playing = !fakeState.playing;
  }

  @override
  Future<void> next() async {
    nextCallCount++;
  }

  @override
  Future<void> previous() async {
    previousCallCount++;
  }

  @override
  Future<void> stop() async {
    fakeState.playing = false;
  }

  @override
  Future<void> open(Playable playable, {bool play = true}) async {
    if (playable is Playlist) {
      fakeState.playlist = playable;
    }
    if (play) fakeState.playing = true;
  }

  @override
  Future<void> add(Media media) async {
    final updated = List<Media>.from(fakeState.playlist.medias)..add(media);
    fakeState.playlist = Playlist(updated, index: fakeState.playlist.index);
  }

  @override
  Future<void> remove(int index) async {
    final updated = List<Media>.from(fakeState.playlist.medias);
    if (index >= 0 && index < updated.length) {
      updated.removeAt(index);
    }
    fakeState.playlist = Playlist(
      updated,
      index: fakeState.playlist.index.clamp(0, updated.isEmpty ? 0 : updated.length - 1),
    );
  }

  @override
  Future<void> move(int from, int to) async {
    final updated = List<Media>.from(fakeState.playlist.medias);
    if (from >= 0 && from < updated.length) {
      final item = updated.removeAt(from);
      final dest = to.clamp(0, updated.length);
      updated.insert(dest, item);
    }
    fakeState.playlist = Playlist(updated, index: fakeState.playlist.index);
  }

  @override
  Future<void> jump(int index) async {
    fakeState.playlist = Playlist(fakeState.playlist.medias, index: index);
  }

  @override
  Future<void> dispose() async {
    isDisposed = true;
    fakeStreams.dispose();
  }
}

class FakeQueueRepository extends Fake implements QueueRepository {
  List<dynamic> savedOriginalQueue = [];
  String? savedCurrentlyPlayedPath;
  Duration savedResumePosition = Duration.zero;
  String savedContextType = '';
  int? savedContextId;

  @override
  Future<void> saveQueue(
    List<dynamic> originalQueue,
    String? currentlyPlayedTrackPath,
    Duration resumePositionMs,
    String playbackContextType,
    int? playbackContextId,
  ) async {
    savedOriginalQueue = List.from(originalQueue);
    savedCurrentlyPlayedPath = currentlyPlayedTrackPath;
    savedResumePosition = resumePositionMs;
    savedContextType = playbackContextType;
    savedContextId = playbackContextId;
  }

  @override
  Future<void> updateCurrentPosition(int positionInMs) async {
    savedResumePosition = Duration(milliseconds: positionInMs);
  }
}

TrackWithArtists createTrack(int id) {
  return TrackWithArtists(
    track: Track(
      id: id,
      title: 'Track $id',
      trackNumber: 1,
      trackTotal: 10,
      discNumber: 1,
      discTotal: 1,
      durationMs: 180000,
      fileHash: 'hash_$id',
      isMissing: false,
      filePath: '/music/track_$id.mp3',
      fileSize: 1024,
      artistId: 1,
      albumId: 1,
      dateAdded: DateTime.now(),
    ),
    album: const Album(id: 1, title: 'Album 1', albumArtPath: '/art.jpg', year: 2024),
    artists: const [],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;
  late FakePlayer fakePlayer;
  late FakeQueueRepository fakeQueueRepo;

  setUp(() async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    final prefs = await SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(),
    );

    fakePlayer = FakePlayer();
    fakeQueueRepo = FakeQueueRepository();

    container = ProviderContainer(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
        queueRepositoryProvider.overrideWithValue(fakeQueueRepo),
        audioPlayerProvider.overrideWithValue(fakePlayer),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('PlayerService Scroll Suppression Tests', () {
    test('suppressNextScroll and consumeSuppressNextScroll toggle correctly', () {
      final service = container.read(playerServiceProvider);

      expect(service.consumeSuppressNextScroll(), isFalse);

      service.suppressNextScroll();
      expect(service.consumeSuppressNextScroll(), isTrue);
      expect(service.consumeSuppressNextScroll(), isFalse);
    });
  });

  group('PlayerService Volume & Mute Controls', () {
    test('setVolume clamps volume between 0 and 100 and updates preferences', () async {
      final service = container.read(playerServiceProvider);

      await service.setVolume(120.0);
      expect(fakePlayer.volume, equals(100.0));
      expect(container.read(preferenceServiceProvider).volume, equals(100.0));
      expect(container.read(preferenceServiceProvider).isMuted, isFalse);

      await service.setVolume(-15.0);
      expect(fakePlayer.volume, equals(0.0));
      expect(container.read(preferenceServiceProvider).volume, equals(0.0));
      expect(container.read(preferenceServiceProvider).isMuted, isTrue);

      await service.setVolume(65.0);
      expect(fakePlayer.volume, equals(65.0));
      expect(container.read(preferenceServiceProvider).volume, equals(65.0));
      expect(container.read(preferenceServiceProvider).isMuted, isFalse);
    });

    test('setVolumeUp and setVolumeDown increment and decrement within bounds', () async {
      final service = container.read(playerServiceProvider);
      await service.setVolume(50.0);

      await service.setVolumeUp(10.0);
      expect(fakePlayer.volume, equals(60.0));
      expect(container.read(preferenceServiceProvider).volume, equals(60.0));

      await service.setVolumeDown(25.0);
      expect(fakePlayer.volume, equals(35.0));
      expect(container.read(preferenceServiceProvider).volume, equals(35.0));
    });

    test('toggleMute silences player and restores previous volume upon unmuting', () async {
      final service = container.read(playerServiceProvider);
      await service.setVolume(75.0);

      await service.toggleMute();
      expect(fakePlayer.volume, equals(0.0));
      expect(container.read(preferenceServiceProvider).isMuted, isTrue);
      expect(container.read(preferenceServiceProvider).volume, equals(75.0));

      await service.toggleMute();
      expect(fakePlayer.volume, equals(75.0));
      expect(container.read(preferenceServiceProvider).isMuted, isFalse);
    });
  });

  group('PlayerService Loop Mode Transitions', () {
    test('cycleLoopMode cycles none -> loop -> single -> none', () async {
      final service = container.read(playerServiceProvider);

      container.read(preferenceServiceProvider.notifier).setLoopMode(PlaylistMode.none);

      await service.cycleLoopMode();
      expect(fakePlayer.playlistMode, equals(PlaylistMode.loop));
      expect(container.read(preferenceServiceProvider).loopMode, equals(PlaylistMode.loop));

      await service.cycleLoopMode();
      expect(fakePlayer.playlistMode, equals(PlaylistMode.single));
      expect(container.read(preferenceServiceProvider).loopMode, equals(PlaylistMode.single));

      await service.cycleLoopMode();
      expect(fakePlayer.playlistMode, equals(PlaylistMode.none));
      expect(container.read(preferenceServiceProvider).loopMode, equals(PlaylistMode.none));
    });
  });

  group('PlayerService Navigation & Playback Triggers', () {
    test('next and previous set animate scroll intent and trigger engine calls', () async {
      final service = container.read(playerServiceProvider);

      await service.next();
      expect(fakePlayer.nextCallCount, equals(1));
      expect(container.read(queueScrollBehaviorProvider), equals(QueueScrollBehavior.animate));

      container.read(queueScrollBehaviorProvider.notifier).setIntent(QueueScrollBehavior.none);

      await service.previous();
      expect(fakePlayer.previousCallCount, equals(1));
      expect(container.read(queueScrollBehaviorProvider), equals(QueueScrollBehavior.animate));
    });

    test('clearQueue stops playback and wipes repository queue', () async {
      final service = container.read(playerServiceProvider);

      await service.clearQueue();
      expect(fakePlayer.state.playlist.medias, isEmpty);
      expect(fakeQueueRepo.savedOriginalQueue, isEmpty);
      expect(container.read(playbackContextProvider)?.type, isEmpty);
    });
  });

  group('PlayerService Queue Management & Shuffle', () {
    test('toggleShuffle toggles preferences when queue is empty', () async {
      final service = container.read(playerServiceProvider);
      expect(container.read(preferenceServiceProvider).shuffleMode, isFalse);

      await service.toggleShuffle();
      expect(container.read(preferenceServiceProvider).shuffleMode, isTrue);

      await service.toggleShuffle();
      expect(container.read(preferenceServiceProvider).shuffleMode, isFalse);
    });

    test('setPlaylist initializes engine playlist and updates context', () async {
      final service = container.read(playerServiceProvider);
      final tracks = [createTrack(1), createTrack(2), createTrack(3)];

      await service.setPlaylist(
        tracksToPlay: tracks,
        initialIndex: 0,
        playbackContextType: 'album',
        playbackContextId: 1,
      );

      expect(fakePlayer.state.playlist.medias.length, equals(3));
      expect(container.read(playbackContextProvider)?.type, equals('album'));
      expect(container.read(playbackContextProvider)?.id, equals(1));
    });

    test('addToQueue appends tracks to active engine playlist', () async {
      final service = container.read(playerServiceProvider);
      final initialTracks = [createTrack(1), createTrack(2)];

      await service.setPlaylist(
        tracksToPlay: initialTracks,
        initialIndex: 0,
        playbackContextType: 'playlist',
        playbackContextId: 5,
      );
      expect(fakePlayer.state.playlist.medias.length, equals(2));

      await service.addToQueue([createTrack(3), createTrack(4)], 'playlist', 5);
      expect(fakePlayer.state.playlist.medias.length, equals(4));
    });

    test('playNext inserts tracks after the active engine index', () async {
      final service = container.read(playerServiceProvider);
      final initialTracks = [createTrack(1), createTrack(2)];

      await service.setPlaylist(
        tracksToPlay: initialTracks,
        initialIndex: 0,
        playbackContextType: 'album',
        playbackContextId: 10,
      );

      await service.playNext([createTrack(99)], 'album', 10);
      expect(fakePlayer.state.playlist.medias.length, equals(3));
      expect(fakePlayer.state.playlist.medias[1].uri, equals(Media('/music/track_99.mp3').uri));
    });

    test('removeTrack removes media at specified index', () async {
      final service = container.read(playerServiceProvider);
      final initialTracks = [createTrack(1), createTrack(2), createTrack(3)];

      await service.setPlaylist(
        tracksToPlay: initialTracks,
        initialIndex: 0,
        playbackContextType: 'all_tracks',
      );

      await service.removeTrack(1);
      expect(fakePlayer.state.playlist.medias.length, equals(2));
      expect(fakePlayer.state.playlist.medias[0].uri, equals(Media('/music/track_1.mp3').uri));
      expect(fakePlayer.state.playlist.medias[1].uri, equals(Media('/music/track_3.mp3').uri));
    });

    test('removeTracks removes multiple indices correctly', () async {
      final service = container.read(playerServiceProvider);
      final initialTracks = [createTrack(1), createTrack(2), createTrack(3), createTrack(4)];

      await service.setPlaylist(
        tracksToPlay: initialTracks,
        initialIndex: 0,
        playbackContextType: 'all_tracks',
      );

      await service.removeTracks([1, 2]);
      expect(fakePlayer.state.playlist.medias.length, equals(2));
      expect(fakePlayer.state.playlist.medias[0].uri, equals(Media('/music/track_1.mp3').uri));
      expect(fakePlayer.state.playlist.medias[1].uri, equals(Media('/music/track_4.mp3').uri));
    });
  });
}
