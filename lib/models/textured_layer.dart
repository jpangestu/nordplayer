import 'package:flutter/rendering.dart';
import 'package:suara/models/texture_profile.dart';

class TexturedLayer {
  static const bool defaultEnabled = false;
  static const double defaultOpacity = 0.5;
  static const BoxFit defaultFit = BoxFit.fill;

  final bool isEnabled;
  final double opacity;
  final BoxFit fit;
  final TextureProfile? activeTexture;

  const TexturedLayer({
    this.isEnabled = defaultEnabled,
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

  factory TexturedLayer.fromMap(Map<String, dynamic> map) {
    return TexturedLayer(
      isEnabled: map['isEnabled'] ?? defaultEnabled,
      opacity: (map['opacity'] as num?)?.toDouble() ?? defaultOpacity,
      fit: BoxFit.values.firstWhere(
        (e) => e.name == map['fit'],
        orElse: () => defaultFit,
      ),
      activeTexture: map['activeTexture'] != null
          ? TextureProfile.fromMap(map['activeTexture'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isEnabled': isEnabled,
      'opacity': opacity,
      'fit': fit.name,
      'activeTexture': activeTexture?.toMap(),
    };
  }
}
