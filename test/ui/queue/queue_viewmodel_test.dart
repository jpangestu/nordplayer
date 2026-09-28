import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nordplayer/data/repositories/config_repository.dart';
import 'package:nordplayer/data/repositories/ui_preferences_repository.dart';
import 'package:nordplayer/data/services/audio/playback_controller.dart';
import 'package:nordplayer/domain/models/album.dart';
import 'package:nordplayer/domain/models/artist.dart';
import 'package:nordplayer/domain/models/composite_models.dart';
import 'package:nordplayer/domain/models/track.dart';
import 'package:nordplayer/ui/queue/queue_scroll_behavior.dart';
import 'package:nordplayer/ui/queue/queue_ui_state.dart';
import 'package:nordplayer/ui/queue/queue_viewmodel.dart';

import '../../../testing/fakes/fake_config_repository.dart';
import '../../../testing/fakes/fake_playback_controller.dart';
import '../../../testing/fakes/fake_ui_preferences_repository.dart';

TrackWithArtists _makeTrack(int id, String title, String path) {
  return TrackWithArtists(
    track: Track(
      id: id,
      title: title,
      filePath: path,
      durationMs: 200000,
      albumId: 1,
      artistId: 1,
      fileHash: 'hash_$id',
      dateAdded: DateTime.fromMillisecondsSinceEpoch(0),
    ),
    album: const Album(id: 1, title: 'Album 1'),
    artists: [const Artist(id: 1, name: 'Artist 1')],
  );
}

void main() {
  group('QueueViewModel & QueueUiState', () {
    late FakePlaybackController fakePlaybackController;
    late FakeConfigRepository fakeConfigRepo;
    late FakeUiPreferencesRepository fakeUiPreferencesRepo;
    late ProviderContainer container;

    setUp(() {
      fakePlaybackController = FakePlaybackController();
      fakeConfigRepo = FakeConfigRepository();
      fakeUiPreferencesRepo = FakeUiPreferencesRepository();

      container = ProviderContainer(
        overrides: [
          playbackControllerProvider.overrideWithValue(fakePlaybackController),
          configRepositoryProvider.overrideWithValue(fakeConfigRepo),
          uiPreferencesRepositoryProvider.overrideWithValue(fakeUiPreferencesRepo),
        ],
      );
    });

    tearDown(() {
      container.dispose();
      fakePlaybackController.dispose();
      fakeConfigRepo.dispose();
      fakeUiPreferencesRepo.dispose();
    });

    test('initial state and reactive stream updates', () async {
      final sub = container.listen(queueViewModelProvider, (_, _) {});
      addTearDown(sub.close);

      final initialState = container.read(queueViewModelProvider);
      expect(initialState.isEmpty, isTrue);
      expect(initialState.trackCount, equals(0));
      expect(initialState.currentTrack, isNull);
      expect(initialState.currentIndex, equals(-1));
      expect(initialState.isDragging, isFalse);

      final track1 = _makeTrack(1, 'Song 1', '/music/1.mp3');
      final track2 = _makeTrack(2, 'Song 2', '/music/2.mp3');

      fakePlaybackController.emitQueue([track1, track2]);
      fakePlaybackController.emitCurrentTrack(track1);
      fakePlaybackController.emitCurrentIndex(0);
      await pumpEventQueue();

      final state = container.read(queueViewModelProvider);
      expect(state.isEmpty, isFalse);
      expect(state.trackCount, equals(2));
      expect(state.currentTrack, equals(track1));
      expect(state.currentIndex, equals(0));
      expect(state.isCurrentlyPlaying(track1), isTrue);
      expect(state.isCurrentlyPlaying(track2), isFalse);
    });

    test('moveTrack updates state optimistically, delegates to repo, and shifts selection', () async {
      final sub = container.listen(queueViewModelProvider, (_, _) {});
      addTearDown(sub.close);

      final track1 = _makeTrack(1, 'Song 1', '/music/1.mp3');
      final track2 = _makeTrack(2, 'Song 2', '/music/2.mp3');
      final track3 = _makeTrack(3, 'Song 3', '/music/3.mp3');
      fakePlaybackController.emitQueue([track1, track2, track3]);
      await pumpEventQueue();

      // Select track 2 (index 1)
      final vm = container.read(queueViewModelProvider.notifier);
      vm.selectTrack(1, isCtrl: false, isShift: false);
      expect(container.read(queueViewModelProvider).selectedIndices, equals({1}));

      // Move track 0 to index 2
      vm.moveTrack(0, 2);

      // Verify repository was called
      expect(fakePlaybackController.moveOld, equals(0));
      expect(fakePlaybackController.moveNew, equals(2));

      // Verify optimistic reorder in state: track1 moved to index 2
      final state = container.read(queueViewModelProvider);
      expect(state.tracks[0], equals(track2));
      expect(state.tracks[1], equals(track3));
      expect(state.tracks[2], equals(track1));

      // Selection on former index 1 shifts up to 0
      expect(state.selectedIndices, equals({0}));
    });

    test('removeTrack delegates to repository and shifts downstream selection', () async {
      final sub = container.listen(queueViewModelProvider, (_, _) {});
      addTearDown(sub.close);

      final vm = container.read(queueViewModelProvider.notifier);
      vm.selectTrack(5, isCtrl: false, isShift: false);

      vm.removeTrack(2);

      expect(fakePlaybackController.removedIndex, equals(2));
      // Index 5 shifts down to 4
      expect(container.read(queueViewModelProvider).selectedIndices, equals({4}));
    });

    test('removeSelectedTracks batches removals and clears selection', () async {
      final sub = container.listen(queueViewModelProvider, (_, _) {});
      addTearDown(sub.close);

      final vm = container.read(queueViewModelProvider.notifier);
      vm.selectTrack(1, isCtrl: false, isShift: false);
      vm.selectTrack(3, isCtrl: true, isShift: false);

      await vm.removeSelectedTracks([1, 3]);

      expect(fakePlaybackController.batchRemoved, equals([1, 3]));
      expect(container.read(queueViewModelProvider).selectedIndices, isEmpty);
    });

    test('clearQueue delegates to repository and clears selection', () async {
      final sub = container.listen(queueViewModelProvider, (_, _) {});
      addTearDown(sub.close);

      final vm = container.read(queueViewModelProvider.notifier);
      vm.selectTrack(1, isCtrl: false, isShift: false);

      await vm.clearQueue();

      expect(fakePlaybackController.cleared, isTrue);
      expect(container.read(queueViewModelProvider).selectedIndices, isEmpty);
    });

    test('jumpToTrack suppresses next scroll and delegates to jumpToIndex', () {
      final sub = container.listen(queueViewModelProvider, (_, _) {});
      addTearDown(sub.close);

      final vm = container.read(queueViewModelProvider.notifier);
      vm.jumpToTrack(4);

      expect(container.read(queueScrollBehaviorProvider), equals(QueueScrollBehavior.none));
      expect(fakePlaybackController.jumpedIndex, equals(4));
    });

    test('setDragging and closeQueue operate correctly', () async {
      final sub = container.listen(queueViewModelProvider, (_, _) {});
      addTearDown(sub.close);

      final vm = container.read(queueViewModelProvider.notifier);
      expect(container.read(queueViewModelProvider).isDragging, isFalse);

      vm.setDragging(true);
      expect(container.read(queueViewModelProvider).isDragging, isTrue);

      vm.setDragging(false);
      expect(container.read(queueViewModelProvider).isDragging, isFalse);

      await vm.closeQueue();
      expect(fakeUiPreferencesRepo.showQueue, isFalse);
    });

    test('scroll behavior intent can be listened and reset', () async {
      final sub = container.listen(queueViewModelProvider, (_, _) {});
      addTearDown(sub.close);

      final vm = container.read(queueViewModelProvider.notifier);
      expect(container.read(queueViewModelProvider).scrollBehavior, equals(QueueScrollBehavior.none));

      container.read(queueScrollBehaviorProvider.notifier).setIntent(QueueScrollBehavior.jump);
      await pumpEventQueue();

      expect(container.read(queueViewModelProvider).scrollBehavior, equals(QueueScrollBehavior.jump));

      vm.resetScrollBehavior();
      expect(container.read(queueViewModelProvider).scrollBehavior, equals(QueueScrollBehavior.none));
      expect(container.read(queueScrollBehaviorProvider), equals(QueueScrollBehavior.none));
    });

    test('QueueUiState equality and copyWith work as expected', () {
      final track1 = _makeTrack(1, 'A', '/a.mp3');
      const state1 = QueueUiState(tracks: [], isDragging: false, isAdaptiveBg: false);
      final state2 = state1.copyWith(tracks: [track1], isDragging: true);

      expect(state1 == state2, isFalse);
      expect(state2.isDragging, isTrue);
      expect(state2.tracks.length, equals(1));
      expect(state2.isEmpty, isFalse);
      expect(state1.hashCode != state2.hashCode, isTrue);
    });
  });
}
