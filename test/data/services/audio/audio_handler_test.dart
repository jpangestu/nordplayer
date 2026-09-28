import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:media_kit/media_kit.dart' hide Track;
import 'package:nordplayer/data/services/audio/audio_handler.dart';
import 'package:nordplayer/domain/models/album.dart';
import 'package:nordplayer/domain/models/artist.dart';
import 'package:nordplayer/domain/models/composite_models.dart';
import 'package:nordplayer/domain/models/track.dart';

import '../../../../testing/fakes/fake_playback_controller.dart';

class _FakePlayerStream extends Fake implements PlayerStream {
  final playlistController = StreamController<Playlist>.broadcast();
  final positionController = StreamController<Duration>.broadcast();
  final playingController = StreamController<bool>.broadcast();
  final bufferingController = StreamController<bool>.broadcast();

  @override
  Stream<Playlist> get playlist => playlistController.stream;

  @override
  Stream<Duration> get position => positionController.stream;

  @override
  Stream<bool> get playing => playingController.stream;

  @override
  Stream<bool> get buffering => bufferingController.stream;

  void dispose() {
    playlistController.close();
    positionController.close();
    playingController.close();
    bufferingController.close();
  }
}

class _FakePlayerState extends Fake implements PlayerState {
  @override
  Playlist playlist = const Playlist([]);

  @override
  Duration position = Duration.zero;

  @override
  Duration buffer = Duration.zero;

  @override
  bool playing = false;

  @override
  bool buffering = false;
}

class _TestPlayer extends Fake implements Player {
  final fakeStreams = _FakePlayerStream();
  final fakeState = _FakePlayerState();

  int playCount = 0;
  int pauseCount = 0;
  int stopCount = 0;
  int nextCount = 0;
  int previousCount = 0;
  int jumpIndex = -1;
  Duration? seekPos;

  @override
  PlayerStream get stream => fakeStreams;

  @override
  PlayerState get state => fakeState;

  @override
  Future<void> play() async {
    playCount++;
    fakeState.playing = true;
    fakeStreams.playingController.add(true);
  }

  @override
  Future<void> pause() async {
    pauseCount++;
    fakeState.playing = false;
    fakeStreams.playingController.add(false);
  }

  @override
  Future<void> stop() async {
    stopCount++;
    fakeState.playing = false;
    fakeStreams.playingController.add(false);
  }

  @override
  Future<void> next() async {
    nextCount++;
  }

  @override
  Future<void> previous() async {
    previousCount++;
  }

  @override
  Future<void> jump(int index) async {
    jumpIndex = index;
  }

  @override
  Future<void> seek(Duration position) async {
    seekPos = position;
    fakeState.position = position;
    fakeStreams.positionController.add(position);
  }

  @override
  Future<void> dispose() async {
    fakeStreams.dispose();
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
  group('AppAudioHandler Unattached', () {
    late _TestPlayer player;
    late AppAudioHandler handler;

    setUp(() {
      player = _TestPlayer();
      handler = AppAudioHandler(player);
    });

    tearDown(() async {
      await handler.dispose();
      await player.dispose();
    });

    test('playbackState broadcasts playing and buffering state changes', () async {
      player.fakeState.playing = true;
      player.fakeStreams.playingController.add(true);
      await pumpEventQueue();

      expect(handler.playbackState.value.playing, isTrue);
      expect(handler.playbackState.value.controls, contains(MediaControl.pause));

      player.fakeState.playing = false;
      player.fakeStreams.playingController.add(false);
      await pumpEventQueue();

      expect(handler.playbackState.value.playing, isFalse);
      expect(handler.playbackState.value.controls, contains(MediaControl.play));
    });

    test('transport controls safely no-op when controller is not attached', () async {
      await handler.play();
      await handler.pause();
      await handler.skipToNext();
      await handler.skipToPrevious();
      await handler.seek(const Duration(seconds: 15));
      await handler.skipToQueueItem(3);

      expect(player.playCount, 0);
      expect(player.pauseCount, 0);
      expect(player.nextCount, 0);
      expect(player.previousCount, 0);
      expect(player.seekPos, isNull);
      expect(player.jumpIndex, -1);
    });
  });

  group('AppAudioHandler Attached to PlaybackController', () {
    late _TestPlayer player;
    late AppAudioHandler handler;
    late FakePlaybackController controller;

    final track1 = _makeTrack(1, 'Track One', path: '/music/t1.mp3', art: '/covers/c1.jpg');
    final track2 = _makeTrack(2, 'Track Two', path: '/music/t2.mp3');

    setUp(() {
      player = _TestPlayer();
      controller = FakePlaybackController(initialQueue: [track1, track2], initialIndex: 0);
      handler = AppAudioHandler(player);
      handler.attachController(controller);
    });

    tearDown(() async {
      await handler.dispose();
      await player.dispose();
    });

    test('syncs active track from controller to mediaItem', () async {
      await pumpEventQueue();

      expect(handler.mediaItem.value, isNotNull);
      expect(handler.mediaItem.value!.id, track1.track.filePath);
      expect(handler.mediaItem.value!.title, 'Track One');
      expect(handler.mediaItem.value!.artist, 'Test Artist');
      expect(handler.mediaItem.value!.album, 'Test Album');
      expect(handler.mediaItem.value!.artUri, Uri.file('/covers/c1.jpg'));
    });

    test('syncs full queue from controller to queue stream', () async {
      await pumpEventQueue();

      expect(handler.queue.value.length, 2);
      expect(handler.queue.value[0].title, 'Track One');
      expect(handler.queue.value[1].title, 'Track Two');
    });

    test('skipToNext delegates to PlaybackController.next()', () async {
      await handler.skipToNext();
      await pumpEventQueue();

      // FakePlaybackController advances index to 1
      expect(controller.currentIndex, 1);
      expect(player.nextCount, 0); // Player was not called directly
    });

    test('skipToPrevious delegates to PlaybackController.previous()', () async {
      controller.jumpToIndex(1);
      await handler.skipToPrevious();
      await pumpEventQueue();

      expect(controller.currentIndex, 0);
      expect(player.previousCount, 0);
    });

    test('play and pause delegate to PlaybackController', () async {
      await handler.play();
      expect(controller.isPlaying, isTrue);

      await handler.pause();
      expect(controller.isPlaying, isFalse);
    });

    test('seek delegates to PlaybackController.seek()', () async {
      await handler.seek(const Duration(seconds: 42));
      expect(controller.position, const Duration(seconds: 42));
    });

    test('skipToQueueItem delegates to PlaybackController.jumpToIndex()', () async {
      await handler.skipToQueueItem(1);
      expect(controller.jumpedIndex, 1);
    });
  });
}
