import 'package:flutter/rendering.dart';

class AdaptiveBackground {
  static const double defaultBlur = 50.0;
  static const BoxFit defaultFit = BoxFit.cover;

  final bool isEnabled;
  final double blur;
  final BoxFit fit;

  const AdaptiveBackground({
    this.isEnabled = true,
    this.blur = defaultBlur,
    this.fit = defaultFit,
  });

  AdaptiveBackground copyWith({
    bool? isEnabled,
    double? blur,
    BoxFit? fit,
  }) {
    return AdaptiveBackground(
      isEnabled: isEnabled ?? this.isEnabled,
      blur: blur ?? this.blur,
      fit: fit ?? this.fit,
    );
  }
}
