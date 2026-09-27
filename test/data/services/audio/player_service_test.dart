import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:media_kit/media_kit.dart' hide Track;
import 'package:nordplayer/data/services/audio/player_service.dart';
import 'package:nordplayer/data/services/system/preference_service.dart';
import 'package:nordplayer/ui/queue/queue_scroll_behavior.dart';
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;
  late FakePlayer fakePlayer;

  setUp(() async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    final prefs = await SharedPreferencesWithCache.create(cacheOptions: const SharedPreferencesWithCacheOptions());

    fakePlayer = FakePlayer();

    container = ProviderContainer(
      overrides: [sharedPrefsProvider.overrideWithValue(prefs), audioPlayerProvider.overrideWithValue(fakePlayer)],
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
  });

  group('PlayerService Shuffle Tests', () {
    test('toggleShuffle toggles preferences when queue is empty', () async {
      final service = container.read(playerServiceProvider);
      expect(container.read(preferenceServiceProvider).shuffleMode, isFalse);

      await service.toggleShuffle();
      expect(container.read(preferenceServiceProvider).shuffleMode, isTrue);

      await service.toggleShuffle();
      expect(container.read(preferenceServiceProvider).shuffleMode, isFalse);
    });
  });

  group('PlayerService Disposal', () {
    test('dispose does not dispose Player when disposePlayer is false', () async {
      final ref = container.read(Provider<Ref>((ref) => ref));
      final unownedPlayer = FakePlayer();
      final nonOwningService = PlayerService(ref, unownedPlayer, disposePlayer: false);

      await nonOwningService.dispose();
      expect(unownedPlayer.isDisposed, isFalse);
    });

    test('dispose disposes Player when disposePlayer is true', () async {
      final ref = container.read(Provider<Ref>((ref) => ref));
      final ownedPlayer = FakePlayer();
      final owningService = PlayerService(ref, ownedPlayer, disposePlayer: true);

      await owningService.dispose();
      expect(ownedPlayer.isDisposed, isTrue);
    });
  });
}
