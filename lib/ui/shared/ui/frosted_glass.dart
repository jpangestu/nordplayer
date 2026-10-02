import 'dart:ui';

import 'package:material_ui/material_ui.dart';

class const FrostedGlass({
  super.key,
  final double blurSigma = 5.0,
  final Color backgroundColor = Colors.transparent,
  final double borderRadius = 0.0,
  required final Widget child,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final clipRadius = BorderRadius.circular(borderRadius);

    final content = Material(color: backgroundColor, borderRadius: clipRadius, child: child);

    if (blurSigma <= 0) {
      if (borderRadius > 0) {
        return ClipRRect(borderRadius: clipRadius, child: content);
      }
      return content;
    }

    return ClipRRect(
      borderRadius: clipRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma, tileMode: TileMode.mirror),
        child: content,
      ),
    );
  }
}
