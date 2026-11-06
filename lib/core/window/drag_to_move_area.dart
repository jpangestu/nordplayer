import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:nordplayer/core/window/native_window.dart';

/// A widget that initiates native window dragging when a pan gesture begins.
class DragToMoveArea extends StatelessWidget {
  final Widget child;
  final VoidCallback? onDoubleTap;
  final GestureTapDownCallback? onSecondaryTapDown;

  const DragToMoveArea({super.key, required this.child, this.onDoubleTap, this.onSecondaryTapDown});

  @override
  Widget build(BuildContext context) {
    if (!Platform.isWindows) {
      return child;
    }

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onPanStart: (_) {
        NativeWindow.instance.startDragging();
      },
      onDoubleTap: onDoubleTap ?? NativeWindow.instance.toggleMaximize,
      onSecondaryTapDown:
          onSecondaryTapDown ??
          (details) => NativeWindow.instance.popUpWindowMenu(details.globalPosition),
      child: child,
    );
  }
}
