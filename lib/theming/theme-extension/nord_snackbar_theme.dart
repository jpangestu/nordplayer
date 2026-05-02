import 'package:flutter/material.dart';

@immutable
class NordSnackBarTheme extends ThemeExtension<NordSnackBarTheme> {
  const NordSnackBarTheme({this.generalColor, this.infoColor, this.successColor, this.warningColor, this.errorColor});

  final Color? generalColor;
  final Color? infoColor;
  final Color? warningColor;
  final Color? successColor;
  final Color? errorColor;

  @override
  NordSnackBarTheme copyWith({
    Color? generalColor,
    Color? infoColor,
    Color? warningColor,
    Color? successColor,
    Color? errorColor,
  }) {
    return NordSnackBarTheme(
      generalColor: generalColor ?? this.generalColor,
      infoColor: infoColor ?? this.infoColor,
      warningColor: warningColor ?? this.warningColor,
      successColor: successColor ?? this.successColor,
      errorColor: errorColor ?? this.errorColor,
    );
  }

  @override
  NordSnackBarTheme lerp(NordSnackBarTheme? other, double t) {
    if (other == null) {
      return this;
    }

    return NordSnackBarTheme(
      generalColor: Color.lerp(generalColor, other.generalColor, t),
      infoColor: Color.lerp(infoColor, other.infoColor, t),
      warningColor: Color.lerp(warningColor, other.warningColor, t),
      successColor: Color.lerp(successColor, other.successColor, t),
      errorColor: Color.lerp(errorColor, other.errorColor, t),
    );
  }
}
