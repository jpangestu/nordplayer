import 'dart:async';

/// A utility class to limit the rate at which a function is triggered.
///
/// **Usage:**
/// ```dart
/// final _debouncer = Debouncer(const Duration(milliseconds: 500));
///
/// _debouncer.call(() {
///   // do stuff here (will only execute after 500ms of silence)
/// });
/// ```
class Debouncer {
  Debouncer(this.duration);

  final Duration duration;
  Timer? _timer;
  bool _isDisposed = false;

  bool get isDisposed => _isDisposed;
  bool get isActive => _timer?.isActive ?? false;

  void call(void Function() action) {
    if (_isDisposed) return;
    _timer?.cancel();
    _timer = Timer(duration, () {
      if (_isDisposed) return;
      action();
    });
  }

  /// Cancels any currently pending debounced callback without disposing.
  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  /// Permanently disposes this debouncer and cancels any pending timers.
  void dispose() {
    _isDisposed = true;
    cancel();
  }
}
