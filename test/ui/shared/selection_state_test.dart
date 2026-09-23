import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nordplayer/ui/shared/ui/selection_state.dart';

void main() {
  group('SelectedTracksIndex', () {
    late ProviderContainer container;
    const tableId = 'test_table';

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state is empty set', () {
      final selection = container.read(selectedTracksIndexProvider(tableId));
      expect(selection, isEmpty);
    });

    test('single click selects single track', () {
      final notifier = container.read(selectedTracksIndexProvider(tableId).notifier);
      notifier.selectTrack(3, isCtrlSelect: false, isShiftSelect: false);

      expect(container.read(selectedTracksIndexProvider(tableId)), equals({3}));
    });

    test('repeated normal click replaces selection', () {
      final notifier = container.read(selectedTracksIndexProvider(tableId).notifier);
      notifier.selectTrack(3, isCtrlSelect: false, isShiftSelect: false);
      notifier.selectTrack(7, isCtrlSelect: false, isShiftSelect: false);

      expect(container.read(selectedTracksIndexProvider(tableId)), equals({7}));
    });

    test('ctrl-click toggles indices in selection', () {
      final notifier = container.read(selectedTracksIndexProvider(tableId).notifier);
      notifier.selectTrack(2, isCtrlSelect: false, isShiftSelect: false);
      notifier.selectTrack(5, isCtrlSelect: true, isShiftSelect: false);
      notifier.selectTrack(8, isCtrlSelect: true, isShiftSelect: false);

      expect(container.read(selectedTracksIndexProvider(tableId)), equals({2, 5, 8}));

      // Toggle 5 off
      notifier.selectTrack(5, isCtrlSelect: true, isShiftSelect: false);
      expect(container.read(selectedTracksIndexProvider(tableId)), equals({2, 8}));
    });

    test('shift-click selects contiguous range from anchor', () {
      final notifier = container.read(selectedTracksIndexProvider(tableId).notifier);
      notifier.selectTrack(2, isCtrlSelect: false, isShiftSelect: false); // anchor = 2
      notifier.selectTrack(6, isCtrlSelect: false, isShiftSelect: true);

      expect(container.read(selectedTracksIndexProvider(tableId)), equals({2, 3, 4, 5, 6}));

      // Shift click backwards
      notifier.selectTrack(4, isCtrlSelect: false, isShiftSelect: false); // anchor = 4
      notifier.selectTrack(1, isCtrlSelect: false, isShiftSelect: true);
      expect(container.read(selectedTracksIndexProvider(tableId)), equals({1, 2, 3, 4}));
    });

    test('ctrl+shift-click unions range with existing selection', () {
      final notifier = container.read(selectedTracksIndexProvider(tableId).notifier);
      notifier.selectTrack(10, isCtrlSelect: false, isShiftSelect: false);
      notifier.selectTrack(2, isCtrlSelect: true, isShiftSelect: false); // anchor = 2
      notifier.selectTrack(4, isCtrlSelect: true, isShiftSelect: true);

      expect(container.read(selectedTracksIndexProvider(tableId)), equals({2, 3, 4, 10}));
    });

    test('selectAll selects range [0, totalCount)', () {
      final notifier = container.read(selectedTracksIndexProvider(tableId).notifier);
      notifier.selectAll(5);
      expect(container.read(selectedTracksIndexProvider(tableId)), equals({0, 1, 2, 3, 4}));

      notifier.selectAll(0);
      expect(container.read(selectedTracksIndexProvider(tableId)), isEmpty);
    });

    test('clear resets selection', () {
      final notifier = container.read(selectedTracksIndexProvider(tableId).notifier);
      notifier.selectAll(5);
      notifier.clear();
      expect(container.read(selectedTracksIndexProvider(tableId)), isEmpty);
    });

    test('updateIndicesOnReorder shifts indices accurately', () {
      final notifier = container.read(selectedTracksIndexProvider(tableId).notifier);
      // Items 2 and 4 are selected
      notifier.selectTrack(2, isCtrlSelect: false, isShiftSelect: false);
      notifier.selectTrack(4, isCtrlSelect: true, isShiftSelect: false);

      // Move item 1 to 3: items between 1 and 3 shift up by 1 (2 becomes 1)
      notifier.updateIndicesOnReorder(1, 3);
      expect(container.read(selectedTracksIndexProvider(tableId)), equals({1, 4}));

      // Move item 4 to 0: items between 0 and 4 shift down by 1 (1 becomes 2, 4 becomes 0)
      notifier.updateIndicesOnReorder(4, 0);
      expect(container.read(selectedTracksIndexProvider(tableId)), equals({0, 2}));
    });

    test('updateIndicesOnRemove shifts downstream indices', () {
      final notifier = container.read(selectedTracksIndexProvider(tableId).notifier);
      notifier.selectTrack(1, isCtrlSelect: false, isShiftSelect: false);
      notifier.selectTrack(4, isCtrlSelect: true, isShiftSelect: false);
      notifier.selectTrack(7, isCtrlSelect: true, isShiftSelect: false);

      // Remove item 4 (selected): item 4 is removed, item 7 becomes 6
      notifier.updateIndicesOnRemove(4);
      expect(container.read(selectedTracksIndexProvider(tableId)), equals({1, 6}));
    });

    test('updateIndicesOnBatchRemove shifts and prunes multiple indices', () {
      final notifier = container.read(selectedTracksIndexProvider(tableId).notifier);
      // Selection: {1, 3, 5, 8}
      notifier.selectTrack(1, isCtrlSelect: false, isShiftSelect: false);
      notifier.selectTrack(3, isCtrlSelect: true, isShiftSelect: false);
      notifier.selectTrack(5, isCtrlSelect: true, isShiftSelect: false);
      notifier.selectTrack(8, isCtrlSelect: true, isShiftSelect: false);

      // Batch remove {3, 5}
      notifier.updateIndicesOnBatchRemove([3, 5]);
      // 1 remains 1. 8 shifts down by 2 -> 6.
      expect(container.read(selectedTracksIndexProvider(tableId)), equals({1, 6}));
    });
  });
}
