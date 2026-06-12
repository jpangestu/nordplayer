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

  void call(void Function() action) {
    _timer?.cancel();
    _timer = Timer(duration, action);
  }

  void dispose() {
    _timer?.cancel();
  }
}
