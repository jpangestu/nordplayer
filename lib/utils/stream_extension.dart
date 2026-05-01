import 'dart:async';

extension StreamExtension<T> on Stream<T> {
  /// Emits an item from the stream only after a specified [duration] has passed
  /// without the stream emitting any other items.
  Stream<T> debounceTime(Duration duration) {
    StreamController<T>? controller;
    StreamSubscription<T>? subscription;
    Timer? timer;

    controller = StreamController<T>(
      sync: true,
      onListen: () {
        subscription = listen(
          (data) {
            timer?.cancel();
            timer = Timer(duration, () {
              if (controller?.isClosed == false) {
                controller?.add(data);
              }
            });
          },
          onError: controller?.addError,
          onDone: () {
            timer?.cancel();
            controller?.close();
          },
        );
      },
      onCancel: () {
        timer?.cancel();
        subscription?.cancel();
      },
    );

    return controller.stream;
  }
}
