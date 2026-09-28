import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:media_kit/media_kit.dart' hide Track;
import 'package:nordplayer/data/services/audio/audio_player_engine.dart';

import '../../../../testing/fakes/fake_audio_player_engine.dart';

class _FakePlayerStream extends Fake implements PlayerStream {
  final playlistController = StreamController<Playlist>.broadcast();
  final positionController = StreamController<Duration>.broadcast();
  final durationController = StreamController<Duration>.broadcast();
  final bufferController = StreamController<Duration>.broadcast();
  final playingController = StreamController<bool>.broadcast();
  final completedController = StreamController<bool>.broadcast();

  @override
  Stream<Playlist> get playlist => playlistController.stream;

  @override
  Stream<Duration> get position => positionController.stream;

  @override
  Stream<Duration> get duration => durationController.stream;

  @override
  Stream<Duration> get buffer => bufferController.stream;

  @override
  Stream<bool> get playing => playingController.stream;

  @override
  Stream<bool> get completed => completedController.stream;

  void dispose() {
    playlistController.close();
    positionController.close();
    durationController.close();
    bufferController.close();
    playingController.close();
    completedController.close();
  }
}

class _FakePlayerState extends Fake implements PlayerState {
  @override
  Playlist playlist = const Playlist([]);

  @override
  Duration position = Duration.zero;

  @override
  Duration duration = Duration.zero;

  @override
  bool playing = false;

  @override
  double volume = 100.0;
}

class _TestPlayer extends Fake implements Player {
  final fakeStreams = _FakePlayerStream();
  final fakeState = _FakePlayerState();

  Duration? lastSeekPosition;
  bool isDisposed = false;
  int playCount = 0;
  int pauseCount = 0;
  int playOrPauseCount = 0;
  int stopCount = 0;

  @override
  PlayerStream get stream => fakeStreams;

  @override
  PlayerState get state => fakeState;

  @override
  Future<void> open(Playable playable, {bool play = true}) async {
    if (playable is Playlist) {
      fakeState.playlist = playable;
      fakeStreams.playlistController.add(playable);
    }
    fakeState.playing = play;
    fakeStreams.playingController.add(play);
  }

  @override
  Future<void> add(Media media) async {
    final updated = List<Media>.from(fakeState.playlist.medias)..add(media);
    fakeState.playlist = Playlist(updated, index: fakeState.playlist.index);
    fakeStreams.playlistController.add(fakeState.playlist);
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
    fakeStreams.playlistController.add(fakeState.playlist);
  }

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
  Future<void> playOrPause() async {
    playOrPauseCount++;
    fakeState.playing = !fakeState.playing;
    fakeStreams.playingController.add(fakeState.playing);
  }

  @override
  Future<void> stop() async {
    stopCount++;
    fakeState.playing = false;
    fakeStreams.playingController.add(false);
  }

  @override
  Future<void> seek(Duration position) async {
    lastSeekPosition = position;
    fakeState.position = position;
    fakeStreams.positionController.add(position);
  }

  @override
  Future<void> setVolume(double value) async {
    fakeState.volume = value;
  }

  @override
  Future<void> dispose() async {
    isDisposed = true;
    fakeStreams.dispose();
  }
}

void main() {
  group('MediaKitAudioPlayerEngine', () {
    late _TestPlayer player;
    late MediaKitAudioPlayerEngine engine;

    setUp(() {
      player = _TestPlayer();
      engine = MediaKitAudioPlayerEngine(player);
    });

    tearDown(() async {
      await engine.dispose();
    });

    test('open sets initial single-track playlist and starts playback', () async {
      await engine.open('file:///music/song1.mp3', autoplay: true);

      expect(engine.currentUri, 'file:///music/song1.mp3');
      expect(engine.nextUri, isNull);
      expect(player.state.playlist.medias.length, 1);
      expect(player.state.playlist.medias.first.uri, Media('file:///music/song1.mp3').uri);
      expect(player.state.playing, isTrue);
    });

    test('open with startPosition seeks to given position', () async {
      await engine.open('file:///music/song1.mp3', startPosition: const Duration(seconds: 45), autoplay: false);

      expect(player.lastSeekPosition, const Duration(seconds: 45));
      expect(player.state.playing, isFalse);
    });

    test('setNextMedia adds upcoming track to native playlist', () async {
      await engine.open('file:///music/song1.mp3');
      await engine.setNextMedia('file:///music/song2.mp3');

      expect(engine.nextUri, 'file:///music/song2.mp3');
      expect(player.state.playlist.medias.length, 2);
      expect(player.state.playlist.medias[1].uri, Media('file:///music/song2.mp3').uri);
    });

    test('setNextMedia replaces next track when URI changes', () async {
      await engine.open('file:///music/song1.mp3');
      await engine.setNextMedia('file:///music/song2.mp3');
      expect(player.state.playlist.medias[1].uri, Media('file:///music/song2.mp3').uri);

      await engine.setNextMedia('file:///music/song3.mp3');
      expect(engine.nextUri, 'file:///music/song3.mp3');
      expect(player.state.playlist.medias.length, 2);
      expect(player.state.playlist.medias[1].uri, Media('file:///music/song3.mp3').uri);
    });

    test('setNextMedia null removes upcoming track from native playlist', () async {
      await engine.open('file:///music/song1.mp3');
      await engine.setNextMedia('file:///music/song2.mp3');
      expect(player.state.playlist.medias.length, 2);

      await engine.setNextMedia(null);
      expect(engine.nextUri, isNull);
      expect(player.state.playlist.medias.length, 1);
    });

    test('rolling 2-track window gapless transition triggers completedStream and drops index 0', () async {
      await engine.open('file:///music/song1.mp3');
      await engine.setNextMedia('file:///music/song2.mp3');

      var completedFired = false;
      final sub = engine.completedStream.listen((_) => completedFired = true);

      // Simulate native player seamlessly transitioning to index 1
      player.fakeState.playlist = Playlist(player.fakeState.playlist.medias, index: 1);
      player.fakeStreams.playlistController.add(player.fakeState.playlist);

      await pumpEventQueue();

      expect(completedFired, isTrue);
      expect(engine.currentUri, 'file:///music/song2.mp3');
      expect(engine.nextUri, isNull);
      // Index 0 was dropped, leaving only song2
      expect(player.state.playlist.medias.length, 1);
      expect(player.state.playlist.medias.first.uri, Media('file:///music/song2.mp3').uri);

      await sub.cancel();
    });

    test('natural track end triggers completedStream when no next track queued', () async {
      await engine.open('file:///music/song1.mp3');

      var completedFired = false;
      final sub = engine.completedStream.listen((_) => completedFired = true);

      player.fakeStreams.completedController.add(true);

      await pumpEventQueue();

      expect(completedFired, isTrue);
      await sub.cancel();
    });

    test('basic transport controls delegate to Player', () async {
      await engine.play();
      expect(player.playCount, 1);

      await engine.pause();
      expect(player.pauseCount, 1);

      await engine.playOrPause();
      expect(player.playOrPauseCount, 1);

      await engine.stop();
      expect(player.stopCount, 1);
      expect(engine.currentUri, isNull);
      expect(engine.nextUri, isNull);

      await engine.seek(const Duration(seconds: 12));
      expect(player.lastSeekPosition, const Duration(seconds: 12));

      await engine.setVolume(75.0);
      expect(player.state.volume, 75.0);
    });

    test('dispose does not dispose Player when disposePlayer is false', () async {
      final unownedPlayer = _TestPlayer();
      final nonOwningEngine = MediaKitAudioPlayerEngine(unownedPlayer, disposePlayer: false);

      await nonOwningEngine.dispose();
      expect(unownedPlayer.isDisposed, isFalse);
    });

    test('dispose disposes Player when disposePlayer is true', () async {
      final ownedPlayer = _TestPlayer();
      final owningEngine = MediaKitAudioPlayerEngine(ownedPlayer, disposePlayer: true);

      await owningEngine.dispose();
      expect(ownedPlayer.isDisposed, isTrue);
    });
  });

  group('FakeAudioPlayerEngine', () {
    late FakeAudioPlayerEngine fake;

    setUp(() {
      fake = FakeAudioPlayerEngine();
    });

    tearDown(() async {
      await fake.dispose();
    });

    test('open sets state and emits to positionStream', () async {
      await fake.open('file:///test.mp3', startPosition: const Duration(seconds: 10), autoplay: true);

      expect(fake.currentUri, 'file:///test.mp3');
      expect(fake.position, const Duration(seconds: 10));
      expect(fake.isPlaying, isTrue);
    });

    test('setNextMedia stores next uri', () async {
      await fake.setNextMedia('file:///next.mp3');
      expect(fake.nextUri, 'file:///next.mp3');
    });

    test('play, pause, playOrPause toggle playing state', () async {
      await fake.play();
      expect(fake.isPlaying, isTrue);

      await fake.pause();
      expect(fake.isPlaying, isFalse);

      await fake.playOrPause();
      expect(fake.isPlaying, isTrue);
    });

    test('test helpers simulate completion and state changes', () async {
      var completed = false;
      final sub = fake.completedStream.listen((_) => completed = true);

      fake.simulateTrackCompleted();
      await pumpEventQueue();
      expect(completed, isTrue);

      fake.setTrackDuration(const Duration(minutes: 5));
      expect(fake.duration, const Duration(minutes: 5));

      fake.updatePosition(const Duration(seconds: 30));
      expect(fake.position, const Duration(seconds: 30));

      fake.updateBuffer(const Duration(seconds: 60));
      expect(fake.buffer, const Duration(seconds: 60));

      await sub.cancel();
    });
  });

  group('AudioPlayerEngine Providers', () {
    test('audioPlayerEngineProvider creates MediaKitAudioPlayerEngine wrapping audioPlayerProvider', () {
      final fakePlayer = _TestPlayer();
      final container = ProviderContainer(
        overrides: [
          audioPlayerProvider.overrideWithValue(fakePlayer),
        ],
      );
      addTearDown(container.dispose);

      final engine = container.read(audioPlayerEngineProvider);
      expect(engine, isA<MediaKitAudioPlayerEngine>());
    });
  });
}
