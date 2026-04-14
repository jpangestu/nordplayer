import 'package:flutter/material.dart';

@immutable
class SidebarTheme extends ThemeExtension<SidebarTheme> {
  const SidebarTheme({
    this.backgroundColor,
    this.itemBackgroundColor,
    this.itemForegroundColor,
  });

  /// The background of the sidebar itself
  final Color? backgroundColor;

  /// The dynamic background of the individual items
  final WidgetStateProperty<Color?>? itemBackgroundColor;

  /// The dynamic text/icon color of the individual items
  final WidgetStateProperty<Color?>? itemForegroundColor;

  @override
  SidebarTheme copyWith({
    Color? backgroundColor,
    WidgetStateProperty<Color?>? itemBackgroundColor,
    WidgetStateProperty<Color?>? itemForegroundColor,
  }) {
    return SidebarTheme(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      itemBackgroundColor: itemBackgroundColor ?? this.itemBackgroundColor,
      itemForegroundColor: itemForegroundColor ?? this.itemForegroundColor,
    );
  }

  @override
  SidebarTheme lerp(SidebarTheme? other, double t) {
    if (other == null) {
      return this;
    }

    return SidebarTheme(
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
