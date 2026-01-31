import 'package:flutter/rendering.dart';
import 'package:suara/models/texture_profile';

class TexturedLayer {
  static const double defaultOpacity = 0.5;
  static const BoxFit defaultFit = BoxFit.fill;

  final bool isEnabled;
  final double opacity;
  final BoxFit fit;
  final TextureProfile? activeTexture;

  const TexturedLayer({
    this.isEnabled = false,
    this.opacity = defaultOpacity,
    this.fit = defaultFit,
    this.activeTexture,
  });

  TexturedLayer copyWith({
    bool? isEnabled,
    double? opacity,
    BoxFit? fit,
    TextureProfile? activeTexture,
  }) {
    return TexturedLayer(
      isEnabled: isEnabled ?? this.isEnabled,
      opacity: opacity ?? this.opacity,
      fit: fit ?? this.fit,
      activeTexture: activeTexture ?? this.activeTexture,
    );
  }
}
