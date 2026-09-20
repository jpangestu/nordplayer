import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nordplayer/core/models/selection_state.dart';
import 'package:nordplayer/features/queue/queue_viewmodel.dart';
import 'package:nordplayer/services/audio/player_service.dart';

class FakePlayerService extends Fake implements PlayerService {
  int moveOld = -1;
  int moveNew = -1;
  int removedIndex = -1;
  List<int> batchRemoved = [];
  bool cleared = false;
  int jumpedIndex = -1;

  @override
  Future<void> moveTrack(int from, int to) async {
    moveOld = from;
    moveNew = to;
  }

  @override
  Future<void> removeTrack(int index) async {
    removedIndex = index;
  }

  @override
  Future<void> removeTracks(List<int> indices) async {
    batchRemoved = List.from(indices);
  }

  @override
  Future<void> clearQueue() async {
    cleared = true;
  }

  @override
  Future<void> jumpToIndex(int index) async {
    jumpedIndex = index;
  }
}

void main() {
  group('QueueViewModel', () {
    late FakePlayerService fakePlayerService;
    late ProviderContainer container;

    setUp(() {
      fakePlayerService = FakePlayerService();
      container = ProviderContainer(
        overrides: [
          playerServiceProvider.overrideWithValue(fakePlayerService),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('moveTrack delegates to playerService and updates selection', () {
      final selectionNotifier = container.read(selectedTracksIndexProvider('queue_page').notifier);
      selectionNotifier.selectTrack(2, isCtrlSelect: false, isShiftSelect: false);

      final vm = container.read(queueViewModelProvider);
      vm.moveTrack(1, 3);

      expect(fakePlayerService.moveOld, equals(1));
      expect(fakePlayerService.moveNew, equals(3));
      // Index 2 shifts down to 1
      expect(container.read(selectedTracksIndexProvider('queue_page')), equals({1}));
    });

    test('removeTrack delegates to playerService and shifts downstream selection', () {
      final selectionNotifier = container.read(selectedTracksIndexProvider('queue_page').notifier);
      selectionNotifier.selectTrack(5, isCtrlSelect: false, isShiftSelect: false);

      final vm = container.read(queueViewModelProvider);
      vm.removeTrack(2);

      expect(fakePlayerService.removedIndex, equals(2));
      // Index 5 shifts down to 4
      expect(container.read(selectedTracksIndexProvider('queue_page')), equals({4}));
    });

    test('removeSelectedTracks batches removals and clears selection', () async {
      final selectionNotifier = container.read(selectedTracksIndexProvider('queue_page').notifier);
      selectionNotifier.selectTrack(1, isCtrlSelect: false, isShiftSelect: false);
      selectionNotifier.selectTrack(3, isCtrlSelect: true, isShiftSelect: false);

      final vm = container.read(queueViewModelProvider);
      await vm.removeSelectedTracks([1, 3]);

      expect(fakePlayerService.batchRemoved, equals([1, 3]));
      expect(container.read(selectedTracksIndexProvider('queue_page')), isEmpty);
    });

    test('clearQueue delegates to playerService and clears selection', () async {
      final selectionNotifier = container.read(selectedTracksIndexProvider('queue_page').notifier);
      selectionNotifier.selectTrack(1, isCtrlSelect: false, isShiftSelect: false);

      final vm = container.read(queueViewModelProvider);
      await vm.clearQueue();

      expect(fakePlayerService.cleared, isTrue);
      expect(container.read(selectedTracksIndexProvider('queue_page')), isEmpty);
    });

    test('jumpToTrack delegates to playerService.jumpToIndex', () {
      final vm = container.read(queueViewModelProvider);
      vm.jumpToTrack(5);

      expect(fakePlayerService.jumpedIndex, equals(5));
    });
  });
}
