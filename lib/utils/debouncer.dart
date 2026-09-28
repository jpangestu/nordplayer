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
class Debouncer(final Duration duration) {
  Timer? _timer;
  bool _isDisposed = false;
  void Function()? _pendingAction;

  bool get isDisposed => _isDisposed;
  bool get isActive => _timer?.isActive ?? false;

  void call(void Function() action) {
    if (_isDisposed) return;
    _pendingAction = action;
    _timer?.cancel();
    if (duration == Duration.zero) {
      _pendingAction = null;
      action();
      return;
    }
    _timer = Timer(duration, () {
      if (_isDisposed) return;
      final act = _pendingAction;
      _pendingAction = null;
      act?.call();
    });
  }

  /// Cancels any currently pending debounced callback without disposing.
  void cancel() {
    _timer?.cancel();
    _timer = null;
    _pendingAction = null;
  }

  /// Immediately executes any pending action if one is scheduled, then cancels the timer.
  void flush() {
    if (_isDisposed || _pendingAction == null) return;
    final action = _pendingAction;
    cancel();
    action?.call();
  }

  /// Permanently disposes this debouncer and cancels any pending timers.
  void dispose() {
    _isDisposed = true;
    cancel();
  }
}
