import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nordplayer/services/config_service.dart';
import 'package:nordplayer/widgets/frosted_glass.dart';

/// Shows a popover panel anchored to the widget referenced by [anchorKey].
Future<T?> showPopover<T>({
  required BuildContext context,
  required GlobalKey anchorKey,
  required double width,
  required Widget child,
  EdgeInsets padding = const .symmetric(vertical: 8.0, horizontal: 24.0),
  Duration transitionDuration = const Duration(milliseconds: 150),
}) {
  final renderBox = anchorKey.currentContext?.findRenderObject() as RenderBox?;
  if (renderBox == null) return Future.value(null);
  final offset = renderBox.localToGlobal(Offset.zero);

  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss',
    barrierColor: Colors.transparent,
    transitionDuration: transitionDuration,
    pageBuilder: (context, animation, secondaryAnimation) {
      final screenSize = MediaQuery.sizeOf(context);

      // Center the panel horizontally relative to the anchor widget
      final anchorCenterX = offset.dx + (renderBox.size.width / 2);
      double left = anchorCenterX - (width / 2);

      // Clamp horizontally so it stays within screen boundaries with padding
      final minLeft = padding.left;
      final maxLeft = screenSize.width - width - padding.right;
      if (maxLeft >= minLeft) {
        left = left.clamp(minLeft, maxLeft);
      } else {
        left = minLeft;
      }

      final top = offset.dy + renderBox.size.height + padding.top;

      return Stack(
        children: [
          Positioned(
            top: top,
            left: left,
            child: FadeTransition(opacity: animation, child: child),
          ),
        ],
      );
    },
  );
}

/// A standard styled popover panel container with frosted glass effect, adaptive styling, and borders.
class const PopoverPanel({
  super.key,
  final double? width,
  final BoxConstraints? constraints,
  final EdgeInsetsGeometry? padding,
  final double? blurSigma,
  final double borderRadius = 12.0,
  required final Widget child,
}) extends ConsumerWidget {
  /// Shows a popover panel anchored to the widget referenced by [anchorKey].
  static Future<T?> show<T>({
    required BuildContext context,
    required GlobalKey anchorKey,
    required double width,
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(8.0),
    Duration transitionDuration = const Duration(milliseconds: 150),
  }) {
    return showPopover<T>(
      context: context,
      anchorKey: anchorKey,
      width: width,
      padding: padding,
      transitionDuration: transitionDuration,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final appConfig = ref.watch(configServiceProvider).requireValue;

    return Material(
      type: MaterialType.transparency, // Required for text rendering inside a Stack
      child: FrostedGlass(
        backgroundColor: appConfig.adaptiveBg
            ? theme.colorScheme.surfaceContainerHigh.withValues(alpha: appConfig.adaptiveBgThemeOverlay)
            : theme.colorScheme.surfaceContainerHigh,
        blurSigma: blurSigma ?? (appConfig.adaptiveBgPanelBlur + 10),
        borderRadius: borderRadius,
        child: Container(
          width: width,
          constraints: constraints,
          padding: padding,
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.outlineVariant, width: appConfig.adaptiveBg ? 0 : 2),
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          child: child,
        ),
      ),
    );
  }
}
