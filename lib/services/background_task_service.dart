import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final backgroundTaskServiceProvider = NotifierProvider<BackgroundTaskService, List<BackgroundTask>>(() {
  return BackgroundTaskService();
});

enum BackgroundTaskStatus { running, completed, failed }

class BackgroundTask {
  final String id;
  final String name;
  final int processed;
  final int total;
  final String message;
  final bool isIndeterminate;
  final BackgroundTaskStatus status;
  final String? error;
  final DateTime timestamp;

  BackgroundTask({
    required this.id,
    required this.name,
    this.processed = 0,
    this.total = 0,
    this.message = '',
    this.isIndeterminate = false,
    this.status = BackgroundTaskStatus.running,
    this.error,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  double? get progress => (total > 0 && status == BackgroundTaskStatus.running) ? processed / total : null;

  BackgroundTask copyWith({
    String? name,
    int? processed,
    int? total,
    String? message,
    bool? isIndeterminate,
    BackgroundTaskStatus? status,
    String? error,
  }) {
    return BackgroundTask(
      id: id,
      name: name ?? this.name,
      processed: processed ?? this.processed,
      total: total ?? this.total,
      message: message ?? this.message,
      isIndeterminate: isIndeterminate ?? this.isIndeterminate,
      status: status ?? this.status,
      error: error ?? this.error,
      timestamp: timestamp,
    );
  }
}

class BackgroundTaskService extends Notifier<List<BackgroundTask>> {
  Timer? _cleanupTimer;

  @override
  List<BackgroundTask> build() {
    ref.onDispose(() {
      _cleanupTimer?.cancel();
    });
    return [];
  }

  void startTask({
    required String id,
    required String name,
    String message = '',
    bool isIndeterminate = false,
    int total = 0,
  }) {
    _cleanupTimer?.cancel();
    state = [
      BackgroundTask(id: id, name: name, message: message, isIndeterminate: isIndeterminate, total: total),
      ...state.where((t) => t.id != id),
    ];
  }

  void updateProgress(String id, {int? processed, int? total, String? message, bool? isIndeterminate}) {
    state = [
      for (final t in state)
        if (t.id == id)
          t.copyWith(processed: processed, total: total, message: message, isIndeterminate: isIndeterminate)
        else
          t,
    ];
  }

  void completeTask(String id) {
    state = [
      for (final t in state)
        if (t.id == id)
          t.copyWith(
            status: BackgroundTaskStatus.completed,
            message: 'Completed',
            processed: t.total > 0 ? t.total : t.processed,
          )
        else
          t,
    ];
    _checkAndScheduleCleanup();
  }

  void failTask(String id, String error) {
    state = [
      for (final t in state)
        if (t.id == id) t.copyWith(status: BackgroundTaskStatus.failed, error: error, message: 'Failed: $error') else t,
    ];
    _checkAndScheduleCleanup();
  }

  void clearSuccessful() {
    _cleanupTimer?.cancel();
    state = state.where((t) => t.status != BackgroundTaskStatus.completed).toList();
  }

  void removeTask(String id) {
    state = state.where((t) => t.id != id).toList();
    _checkAndScheduleCleanup();
  }

  void _checkAndScheduleCleanup() {
    _cleanupTimer?.cancel();
    final hasRunning = state.any((t) => t.status == BackgroundTaskStatus.running);
    final hasCompleted = state.any((t) => t.status == BackgroundTaskStatus.completed);
    if (!hasRunning && hasCompleted) {
      _cleanupTimer = Timer(const Duration(seconds: 5), () {
        clearSuccessful();
      });
    }
  }
}
