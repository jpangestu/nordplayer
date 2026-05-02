import 'package:flutter/material.dart';

@immutable
class NordSidebarTheme extends ThemeExtension<NordSidebarTheme> {
  const NordSidebarTheme({this.backgroundColor, this.itemBackgroundColor, this.itemForegroundColor});

  /// The background of the sidebar itself
  final Color? backgroundColor;

  /// The dynamic background of the individual items
  final WidgetStateProperty<Color?>? itemBackgroundColor;

  /// The dynamic text/icon color of the individual items
  final WidgetStateProperty<Color?>? itemForegroundColor;

  @override
  NordSidebarTheme copyWith({
    Color? backgroundColor,
    WidgetStateProperty<Color?>? itemBackgroundColor,
    WidgetStateProperty<Color?>? itemForegroundColor,
  }) {
    return NordSidebarTheme(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      itemBackgroundColor: itemBackgroundColor ?? this.itemBackgroundColor,
      itemForegroundColor: itemForegroundColor ?? this.itemForegroundColor,
    );
  }

  @override
  NordSidebarTheme lerp(NordSidebarTheme? other, double t) {
    if (other == null) {
      return this;
    }

    return NordSidebarTheme(
      backgroundColor: Color.lerp(backgroundColor, other.backgroundColor, t),
      itemBackgroundColor: WidgetStateProperty.lerp<Color?>(
        itemBackgroundColor,
        other.itemBackgroundColor,
        t,
        Color.lerp,
      ),
      itemForegroundColor: WidgetStateProperty.lerp<Color?>(
        itemForegroundColor,
        other.itemForegroundColor,
        t,
        Color.lerp,
      ),
    );
  }
}
