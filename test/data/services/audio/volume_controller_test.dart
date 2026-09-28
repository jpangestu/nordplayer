import 'package:flutter_test/flutter_test.dart';
import 'package:nordplayer/data/services/audio/volume_controller.dart';

import '../../../../testing/fakes/fake_audio_player_engine.dart';
import '../../../../testing/fakes/fake_queue_repository.dart';

void main() {
  group('VolumeController', () {
    late FakeAudioPlayerEngine engine;
    late FakeQueueRepository queueRepo;
    late VolumeController controller;

    setUp(() {
      engine = FakeAudioPlayerEngine();
      queueRepo = FakeQueueRepository();
      controller = VolumeController(engine, queueRepo, persistDebounce: Duration.zero);
    });

    test('initial volume and isMuted reflect defaults', () {
      expect(controller.volume, 100.0);
      expect(controller.isMuted, isFalse);
    });

    test('initialize restores volume and isMuted', () {
      controller.initialize(volume: 75.0, isMuted: true);
      expect(controller.volume, 75.0);
      expect(controller.isMuted, isTrue);
      expect(engine.volume, 0.0);
    });

    group('setVolume', () {
      test('sets volume on both engine and queue repository', () async {
        await controller.setVolume(65.0);

        expect(controller.volume, 65.0);
        expect(engine.volume, 65.0);
        expect(queueRepo.savedVolume, 65.0);
      });

      test('clamps volume between 0.0 and 100.0', () async {
        await controller.setVolume(150.0);
        expect(engine.volume, 100.0);
        expect(queueRepo.savedVolume, 100.0);

        await controller.setVolume(-20.0);
        expect(engine.volume, 0.0);
        expect(queueRepo.savedVolume, 0.0);
      });
    });

    group('setVolumeUp', () {
      test('increments volume by default step of 5.0', () async {
        await controller.setVolume(50.0);

        await controller.setVolumeUp();
        expect(engine.volume, 55.0);
        expect(queueRepo.savedVolume, 55.0);
      });

      test('increments volume by custom step', () async {
        await controller.setVolume(50.0);

        await controller.setVolumeUp(15.0);
        expect(engine.volume, 65.0);
        expect(queueRepo.savedVolume, 65.0);
      });

      test('unmutes if currently muted when increasing volume', () async {
        await controller.setVolume(50.0);
        await controller.toggleMute();
        expect(controller.isMuted, isTrue);

        await controller.setVolumeUp(10.0);
        expect(controller.isMuted, isFalse);
        expect(engine.volume, 60.0);
        expect(queueRepo.savedIsMuted, isFalse);
      });

      test('clamps volume to 100.0 maximum', () async {
        await controller.setVolume(98.0);

        await controller.setVolumeUp(10.0);
        expect(engine.volume, 100.0);
        expect(queueRepo.savedVolume, 100.0);
      });
    });

    group('setVolumeDown', () {
      test('decrements volume by default step of 5.0', () async {
        await controller.setVolume(50.0);

        await controller.setVolumeDown();
        expect(engine.volume, 45.0);
        expect(queueRepo.savedVolume, 45.0);
      });

      test('decrements volume by custom step', () async {
        await controller.setVolume(50.0);

        await controller.setVolumeDown(20.0);
        expect(engine.volume, 30.0);
        expect(queueRepo.savedVolume, 30.0);
      });

      test('automatically sets isMuted to true if volume reaches 0.0', () async {
        await controller.setVolume(10.0);
        expect(controller.isMuted, isFalse);

        await controller.setVolumeDown(10.0);
        expect(engine.volume, 0.0);
        expect(controller.isMuted, isTrue);
        expect(queueRepo.savedIsMuted, isTrue);
      });

      test('clamps volume to 0.0 minimum', () async {
        await controller.setVolume(5.0);

        await controller.setVolumeDown(15.0);
        expect(engine.volume, 0.0);
        expect(controller.isMuted, isTrue);
      });
    });

    group('toggleMute', () {
      test('mutes and sets engine volume to 0 while preserving repository volume', () async {
        await controller.setVolume(70.0);

        await controller.toggleMute();
        expect(controller.isMuted, isTrue);
        expect(engine.volume, 0.0);
        expect(queueRepo.savedVolume, 70.0);
        expect(queueRepo.savedIsMuted, isTrue);
      });

      test('unmutes and restores engine volume from repository', () async {
        await controller.setVolume(70.0);
        await controller.toggleMute();
        expect(engine.volume, 0.0);

        await controller.toggleMute();
        expect(controller.isMuted, isFalse);
        expect(engine.volume, 70.0);
        expect(queueRepo.savedVolume, 70.0);
        expect(queueRepo.savedIsMuted, isFalse);
      });
    });

    group('watchVolume', () {
      test('yields current volume initially and emits updates', () async {
        await controller.setVolume(80.0);

        final volumes = <double>[];
        final sub = controller.watchVolume().listen(volumes.add);

        await pumpEventQueue();
        expect(volumes, [80.0]);

        await controller.setVolume(45.0);
        await pumpEventQueue();
        expect(volumes, [80.0, 45.0]);

        await sub.cancel();
      });
    });

    group('watchIsMuted', () {
      test('yields current isMuted initially and emits updates', () async {
        final mutedStates = <bool>[];
        final sub = controller.watchIsMuted().listen(mutedStates.add);

        await pumpEventQueue();
        expect(mutedStates, [false]);

        await controller.toggleMute();
        await pumpEventQueue();
        expect(mutedStates, [false, true]);

        await sub.cancel();
      });
    });
  });
}
