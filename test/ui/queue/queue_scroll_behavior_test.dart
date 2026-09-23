import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nordplayer/ui/queue/queue_scroll_behavior.dart';

void main() {
  group('QueueScrollBehavior Tests', () {
    test('initial state defaults to QueueScrollBehavior.none', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(queueScrollBehaviorProvider), equals(QueueScrollBehavior.none));
    });

    test('setIntent updates active scroll intent correctly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(queueScrollBehaviorProvider.notifier);

      notifier.setIntent(QueueScrollBehavior.animate);
      expect(container.read(queueScrollBehaviorProvider), equals(QueueScrollBehavior.animate));

      notifier.setIntent(QueueScrollBehavior.jump);
      expect(container.read(queueScrollBehaviorProvider), equals(QueueScrollBehavior.jump));

      notifier.setIntent(QueueScrollBehavior.none);
      expect(container.read(queueScrollBehaviorProvider), equals(QueueScrollBehavior.none));
    });
  });
}
