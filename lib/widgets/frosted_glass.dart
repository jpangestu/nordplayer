import 'dart:ui';
import 'package:flutter/material.dart';

class FrostedGlass extends StatelessWidget {
  final double blurSigma;
  final Color backgroundColor;
  final Widget child;

  const FrostedGlass({
    super.key,
    this.blurSigma = 5.0,
    this.backgroundColor = Colors.transparent,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      // Keeps the blur inside this widget's bounds
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: blurSigma,
          sigmaY: blurSigma,
          tileMode: TileMode.mirror,
        ),
        child: Container(
          // Your semi-transparent color goes here!
          color: backgroundColor,
          child: child,
        ),
      ),
    );
  }
}
