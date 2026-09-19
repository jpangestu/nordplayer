import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Defines how the queue view should scroll when the currently playing track changes.
enum QueueScrollBehavior { animate, jump, none }

/// Riverpod provider managing the active scroll intent for the queue page.
final queueScrollBehaviorProvider =
    NotifierProvider<QueueScrollBehaviorNotifier, QueueScrollBehavior>(
      QueueScrollBehaviorNotifier.new,
    );

/// Notifier that manages transient [QueueScrollBehavior] state.
class QueueScrollBehaviorNotifier extends Notifier<QueueScrollBehavior> {
  @override
  QueueScrollBehavior build() => QueueScrollBehavior.none;

  /// Sets the next scroll intent.
  void setIntent(QueueScrollBehavior intent) {
    state = intent;
  }
}
