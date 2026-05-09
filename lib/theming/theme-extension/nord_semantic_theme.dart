import 'package:flutter/material.dart';

class NordSemanticTheme extends ThemeExtension<NordSemanticTheme> {
  final Color? error;
  final Color? onError;
  final Color? success;
  final Color? onSuccess;
  final Color? warning;
  final Color? onWarning;
  final Color? info;
  final Color? onInfo;
  final Color? general;
  final Color? onGeneral;

  const NordSemanticTheme({
    this.error,
    this.onError,
    this.success,
    this.onSuccess,
    this.warning,
    this.onWarning,
    this.info,
    this.onInfo,
    this.general,
    this.onGeneral,
  });

  @override
  NordSemanticTheme copyWith({
    Color? error,
    Color? onError,
    Color? success,
    Color? onSuccess,
    Color? warning,
    Color? onWarning,
    Color? info,
    Color? onInfo,
    Color? general,
    Color? onGeneral,
  }) {
    return NordSemanticTheme(
      error: error ?? this.error,
      onError: onError ?? this.onError,
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      warning: warning ?? this.warning,
      onWarning: onWarning ?? this.onWarning,
      info: info ?? this.info,
      onInfo: onInfo ?? this.onInfo,
      general: general ?? this.general,
      onGeneral: onGeneral ?? this.onGeneral,
    );
  }

  @override
  NordSemanticTheme lerp(ThemeExtension<NordSemanticTheme>? other, double t) {
    if (other is! NordSemanticTheme) {
      return this;
    }
    return NordSemanticTheme(
      error: Color.lerp(error, other.error, t),
      onError: Color.lerp(onError, other.onError, t),
      success: Color.lerp(success, other.success, t),
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t),
      warning: Color.lerp(warning, other.warning, t),
      onWarning: Color.lerp(onWarning, other.onWarning, t),
      info: Color.lerp(info, other.info, t),
      onInfo: Color.lerp(onInfo, other.onInfo, t),
      general: Color.lerp(general, other.general, t),
      onGeneral: Color.lerp(onGeneral, other.onGeneral, t),
    );
  }
}
