import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final backgroundTaskServiceProvider = NotifierProvider<BackgroundTaskService, List<BackgroundTask>>(() {
  return BackgroundTaskService();
});

enum BackgroundTaskStatus { running, completed, failed }

class BackgroundTask({
  required final String id,
  required final String name,
  final int processed = 0,
  final int total = 0,
  final String message = '',
  final bool isIndeterminate = false,
  final BackgroundTaskStatus status = BackgroundTaskStatus.running,
  final String? error,
  DateTime? timestamp,
}) {
  final DateTime timestamp = timestamp ?? DateTime.now();

  double? get progress => (total > 0 && status == BackgroundTaskStatus.running)
      ? (processed / total).clamp(0.0, 1.0)
      : null;

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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BackgroundTask &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          processed == other.processed &&
          total == other.total &&
          message == other.message &&
          isIndeterminate == other.isIndeterminate &&
          status == other.status &&
          error == other.error &&
          timestamp == other.timestamp;

  @override
  int get hashCode => Object.hash(
        id,
        name,
        processed,
        total,
        message,
        isIndeterminate,
        status,
        error,
        timestamp,
      );

  @override
  String toString() {
    return 'BackgroundTask{id: $id, name: $name, processed: $processed/$total, status: $status}';
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
