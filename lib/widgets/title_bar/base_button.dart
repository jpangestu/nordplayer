import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:nordplayer/widgets/app_icon.dart';

/// For the icon itself, choose whether to use icon (IconData) or svgAssetPath or child widget
class BaseButton extends StatefulWidget {
  final IconData? icon;
  final String? svgAssetPath;
  final double buttonHeight;
  final double buttonWidth;
  final VoidCallback onClick;

  final double iconSize;
  final Color iconColor;
  final Color? iconColorOnHover;
  final Color? iconColorOnClick;

  /// Shape of the hover overlay
  final BoxShape overlayShape;
  final Color overlayColor;
  final Color? overlayColorOnClick;

  final String? tooltip;
  final Widget? child;

  const BaseButton({
    super.key,
    this.icon,
    this.svgAssetPath,
    required this.buttonHeight,
    required this.buttonWidth,
    required this.onClick,
    this.iconSize = 16,
    required this.iconColor,
    this.iconColorOnHover,
    this.iconColorOnClick,
    this.overlayShape = BoxShape.circle,
    required this.overlayColor,
    this.overlayColorOnClick,
    this.tooltip,
    this.child,
  }) : assert(
         icon != null && svgAssetPath == null && child == null ||
             icon == null && svgAssetPath != null && child == null ||
             icon == null && svgAssetPath == null && child != null,
         'Provide either icon or svgPath',
       );

  @override
  State<BaseButton> createState() => _BaseButtonState();
}

class _BaseButtonState extends State<BaseButton> {
  bool _isHovered = false;
  bool _isClicked = false;

  @override
  Widget build(BuildContext context) {
    final Color iconColor;
    if (widget.iconColorOnHover != null && _isHovered) {
      iconColor = widget.iconColorOnHover!;
    } else if (widget.iconColorOnClick != null && _isClicked) {
      iconColor = widget.iconColorOnClick!;
    } else {
      iconColor = widget.iconColor;
    }

    final Color overlayColor;
    if (widget.overlayColorOnClick != null && _isClicked) {
      overlayColor = widget.overlayColorOnClick!;
    } else {
      overlayColor = widget.overlayColor;
    }

    Widget button = MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isClicked = true),
        onTapUp: (_) => setState(() => _isClicked = false),
        onTapCancel: () => setState(() => _isClicked = false),
        onTap: widget.onClick,
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: Container(
            height: widget.buttonHeight,
            width: widget.buttonWidth,
            decoration: BoxDecoration(
              shape: widget.overlayShape,
              color: _isHovered ? overlayColor : Colors.transparent,
            ),
            child:
                widget.child ??
                (widget.icon != null
                    ? AppIcon(widget.icon!, size: widget.iconSize, color: iconColor)
                    : Center(
                        child: SvgPicture.asset(
                          widget.svgAssetPath!,
                          width: widget.iconSize,
                          height: widget.iconSize,
                          colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
                        ),
                      )),
          ),
        ),
      ),
    );

    if (widget.tooltip != null) {
      return Tooltip(message: widget.tooltip!, waitDuration: const Duration(milliseconds: 500), child: button);
    }

    return button;
  }
}
