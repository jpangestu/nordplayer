import 'dart:async';

extension StreamExtension<T> on Stream<T> {
  /// Emits an item from the stream only after a specified [duration] has passed
  /// without the stream emitting any other items.
  Stream<T> debounceTime(Duration duration) {
    StreamController<T>? controller;
    StreamSubscription<T>? subscription;
    Timer? timer;

    void onListen() {
      subscription = listen(
        (data) {
          timer?.cancel();
          timer = Timer(duration, () {
            if (controller?.isClosed == false) {
              controller?.add(data);
            }
          });
        },
        onError: (Object error, StackTrace stackTrace) {
          controller?.addError(error, stackTrace);
        },
        onDone: () {
          timer?.cancel();
          controller?.close();
        },
      );
    }

    void onCancel() {
      timer?.cancel();
      subscription?.cancel();
      subscription = null;
    }

    void onPause() {
      subscription?.pause();
    }

    void onResume() {
      subscription?.resume();
    }

    if (isBroadcast) {
      controller = StreamController<T>.broadcast(
        sync: true,
        onListen: onListen,
        onCancel: onCancel,
      );
    } else {
      controller = StreamController<T>(
        sync: true,
        onListen: onListen,
        onCancel: onCancel,
        onPause: onPause,
        onResume: onResume,
      );
    }

    return controller.stream;
  }
}
