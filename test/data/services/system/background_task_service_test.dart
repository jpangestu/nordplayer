import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nordplayer/data/services/system/background_task_service.dart';

void main() {
  group('BackgroundTask Tests', () {
    test('progress clamps between 0.0 and 1.0', () {
      final taskNormal = BackgroundTask(id: '1', name: 'test', processed: 5, total: 10);
      expect(taskNormal.progress, 0.5);

      final taskOverflow = BackgroundTask(id: '2', name: 'overflow', processed: 15, total: 10);
      expect(taskOverflow.progress, 1.0);
    });

    test('value equality works as expected', () {
      final timestamp = DateTime(2026, 1, 1);
      final taskA = BackgroundTask(id: '1', name: 'test', processed: 5, total: 10, timestamp: timestamp);
      final taskB = BackgroundTask(id: '1', name: 'test', processed: 5, total: 10, timestamp: timestamp);

      expect(taskA, equals(taskB));
      expect(taskA.hashCode, equals(taskB.hashCode));
    });
  });

  group('BackgroundTaskService Notifier Tests', () {
    test('starts, updates, completes, and cleans up tasks', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(backgroundTaskServiceProvider.notifier);

      notifier.startTask(id: 'sync', name: 'Syncing', total: 100);
      var state = container.read(backgroundTaskServiceProvider);
      expect(state.length, 1);
      expect(state.first.status, BackgroundTaskStatus.running);

      notifier.updateProgress('sync', processed: 50);
      state = container.read(backgroundTaskServiceProvider);
      expect(state.first.processed, 50);
      expect(state.first.progress, 0.5);

      notifier.completeTask('sync');
      state = container.read(backgroundTaskServiceProvider);
      expect(state.first.status, BackgroundTaskStatus.completed);
      expect(state.first.processed, 100);

      notifier.clearSuccessful();
      state = container.read(backgroundTaskServiceProvider);
      expect(state.isEmpty, isTrue);
    });
  });
}
