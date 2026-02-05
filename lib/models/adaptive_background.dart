import 'package:flutter/rendering.dart';

class AdaptiveBackground {
  static const bool defaultEnabled = true;
  static const double defaultBlur = 40;
  static const BoxFit defaultFit = BoxFit.cover;

  final bool isEnabled;
  final double blur;
  final BoxFit fit;

  const AdaptiveBackground({
    this.isEnabled = defaultEnabled,
    this.blur = defaultBlur,
    this.fit = defaultFit,
  });

  AdaptiveBackground copyWith({bool? isEnabled, double? blur, BoxFit? fit}) {
    return AdaptiveBackground(
      isEnabled: isEnabled ?? this.isEnabled,
      blur: blur ?? this.blur,
      fit: fit ?? this.fit,
    );
  }

  factory AdaptiveBackground.fromMap(Map<String, dynamic> map) {
    return AdaptiveBackground(
      isEnabled: map['isEnabled'] ?? defaultEnabled,
      blur: (map['blur'] as num?)?.toDouble() ?? defaultBlur,
      fit: BoxFit.values.firstWhere(
        (e) => e.name == map['fit'],
        orElse: () => defaultFit,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {'isEnabled': isEnabled, 'blur': blur, 'fit': fit.name};
  }
}
