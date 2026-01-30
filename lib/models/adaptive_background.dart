import 'package:flutter/rendering.dart';

class AdaptiveBackground {
  static const double defaultBlur = 50.0;
  static const double defaultOpacity = 0.5;
  static const BoxFit defaultFit = BoxFit.cover;

  final bool isEnabled;
  final double blur;
  final double opacity;
  final BoxFit fit;

  const AdaptiveBackground({
    this.isEnabled = true,
    this.blur = defaultBlur,
    this.opacity = defaultOpacity,
    this.fit = defaultFit,
  });

  AdaptiveBackground copyWith({
    bool? isEnabled,
    double? blur,
    double? opacity,
    BoxFit? fit,
  }) {
    return AdaptiveBackground(
      isEnabled: isEnabled ?? this.isEnabled,
      blur: blur ?? this.blur,
      opacity: opacity ?? this.opacity,
      fit: fit ?? this.fit,
    );
  }
}
