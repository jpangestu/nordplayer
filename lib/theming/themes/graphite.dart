import 'package:flutter/material.dart';
import 'package:nordplayer/theming/theme_builder.dart';

class GraphiteColorScheme extends AppColorScheme {
  @override
  Brightness get brightness => Brightness.dark;

  @override
  Color get primary => const Color(0xFF7491ae);
  @override
  Color get onPrimary => const Color(0xFF101418);

  @override
  Color get secondary => const Color(0xFFA0AAB2);
  @override
  Color get onSecondary => const Color(0xFF101418);

  @override
  Color get surfaceContainerLowest => const Color(0xFF0D0F12);
  @override
  Color get surface => const Color(0xFF14161A);
  @override
  Color get surfaceContainerLow => const Color(0xFF191C20);
  @override
  Color get surfaceContainer => const Color(0xFF1E2227);
  @override
  Color get surfaceContainerHigh => const Color(0xFF262A31);
  @override
  Color get surfaceContainerHighest => const Color(0xFF30353E);

  @override
  Color get onSurface => const Color(0xFFE0E3E8);
  @override
  Color get onSurfaceVariant => const Color(0xFFB3B6BA);

  @override
  Color get outline => const Color(0xFF707780);
  @override
  Color get outlineVariant => const Color(0xFF3A414A);

  @override
  Color get error => const Color(0xFFE57373);
  @override
  Color get onError => const Color(0xFFE0E3E8);

  @override
  Color get success => const Color(0xFF81C784);
  @override
  Color get onSuccess => const Color(0xFF14161A);

  @override
  Color get warning => const Color(0xFFe6c047);
  @override
  Color get onWarning => const Color(0xFF14161A);

  @override
  Color get info => const Color(0xFF5aa3dd);
  @override
  Color get onInfo => const Color(0xFF14161A);

  @override
  Color get general => const Color(0xFF9EA4AC);
  @override
  Color get onGeneral => const Color(0xFF14161A);
}
