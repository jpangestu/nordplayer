import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class TitleBarButton extends StatefulWidget {
  final IconData? icon;
  final String? svgPath;
  final VoidCallback onTap;
  final bool isClose;
  final double buttonSize;
  final double iconSize;

  /// Leave it null if icon color should be dynamic
  final Color? fixedIconColor;
  final double hoverOverlaySize;
  final double hoverOverlayOpacity;
  final String? tooltip;

  const TitleBarButton({
    super.key,
    this.icon,
    this.svgPath,
    required this.onTap,
    this.isClose = false,
    this.buttonSize = 32,
    this.iconSize = 16,
    this.fixedIconColor,
    this.hoverOverlaySize = 28,
    this.hoverOverlayOpacity = 1,
    this.tooltip,
  });

  @override
  State<TitleBarButton> createState() => _TitleBarButtonState();
}

class _TitleBarButtonState extends State<TitleBarButton> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final baseIconColor = (widget.fixedIconColor != null)
        ? widget.fixedIconColor!
        : colorScheme.surface;

    Widget button = MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        // Ensures the whole rectangle is clickable
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: widget.buttonSize,
          height: widget.buttonSize,
          color: Colors.transparent,
          child: Center(
            child: Container(
              width: widget.hoverOverlaySize,
              height: widget.hoverOverlaySize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isHovering
                    ? (widget.isClose
                          ? colorScheme.error.withValues(alpha: 0.9)
                          : colorScheme.onSurface.withValues(
                              alpha: widget.hoverOverlayOpacity,
                            ))
                    : Colors.transparent,
              ),
              child: widget.icon != null
                  ? Icon(
                      widget.icon,
                      size: widget.iconSize,
                      color: _isHovering
                          ? widget.isClose
                                ? colorScheme.onError
                                : baseIconColor
                          : colorScheme.onSurface,
                    )
                  : Center(
                      child: SvgPicture.asset(
                        widget.svgPath!,
                        width: widget.iconSize,
                        height: widget.iconSize,
                        colorFilter: ColorFilter.mode(
                          _isHovering
                              ? widget.isClose
                                    ? colorScheme.onError
                                    : baseIconColor
                              : colorScheme.onSurface,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );

    if (widget.tooltip != null) {
      return Tooltip(
        message: widget.tooltip!,
        waitDuration: const Duration(milliseconds: 500),
        child: button,
      );
    }

    return button;
  }
}
