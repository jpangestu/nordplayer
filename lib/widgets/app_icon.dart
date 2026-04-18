import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nordplayer/theming/icon-sets/app_icon_set.dart';

/// Wrapper for the Icon() widget to calculate consistent icon sizing across different icon set
class AppIcon extends ConsumerWidget {
  const AppIcon(this.icon, {super.key, this.size, this.color, this.semanticLabel});

  final IconData icon;
  final double? size;
  final Color? color;

  /// Semantic label for the icon.
  ///
  /// Announced by assistive technologies (e.g TalkBack/VoiceOver).
  /// This label does not show in the UI.
  ///
  ///  * [SemanticsProperties.label], which is set to [semanticLabel] in the
  ///    underlying	 [Semantics] widget.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scale = ref.watch(appIconProvider).opticalScale;
    final layoutSize = size ?? IconTheme.of(context).size ?? 24.0;
    final iconSize = layoutSize * scale;

    return SizedBox(
      width: layoutSize,
      height: layoutSize,
      child: Center(
        child: Icon(icon, size: iconSize, color: color, semanticLabel: semanticLabel),
      ),
    );
  }
}
