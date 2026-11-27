import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nordplayer/core/window/native_window.dart';

/// A widget that initiates native window dragging when a pan gesture begins.
class DragToMoveArea extends ConsumerWidget {
  final Widget child;
  final VoidCallback? onDoubleTap;
  final GestureTapUpCallback? onSecondaryTapUp;

  const DragToMoveArea({super.key, required this.child, this.onDoubleTap, this.onSecondaryTapUp});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nativeWindow = ref.read(nativeWindowProvider);

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onPanStart: (_) => nativeWindow.startDragging(),
      onDoubleTap: onDoubleTap ?? nativeWindow.toggleMaximize,
      onSecondaryTapUp:
          onSecondaryTapUp ?? (details) => nativeWindow.popUpWindowMenu(details.globalPosition),
      child: child,
    );
  }
}
