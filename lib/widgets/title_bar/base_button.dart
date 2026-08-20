import 'package:flutter_svg/svg.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nordplayer/widgets/app_icon.dart';

/// For the icon itself, choose whether to use icon (IconData) or svgAssetPath or child widget
class const BaseButton({
  super.key,
  final IconData? icon,
  final String? svgAssetPath,
  required final double buttonHeight,
  required final double buttonWidth,
  final EdgeInsets padding = const EdgeInsets.all(0),

  /// Whether to enable inkwell splash effect or not
  final bool enableSplash = true,
  required final VoidCallback onClick,

  final double iconSize = 16,
  required final Color iconColor,
  final Color? iconColorOnHover,
  final Color? iconColorOnClick,

  /// Use alongside icon or svg (ignored when you use child) to show to the right of the icon
  final String? title,

  /// Shape of the hover overlay
  final BoxShape overlayShape = BoxShape.circle,
  required final Color overlayColor,
  final Color? overlayColorOnClick,

  final String? tooltip,
  final Widget? child,
}) extends StatefulWidget {
  this
    : assert(
        icon != null && svgAssetPath == null && child == null ||
            icon == null && svgAssetPath != null && child == null ||
            icon == null && svgAssetPath == null && child != null,
        'Provide exactly one of: icon, svgAssetPath, or child',
      );

  @override
  State<BaseButton> createState() => _BaseButtonState();
}

class _BaseButtonState extends State<BaseButton> {
  bool _isHovered = false;
  bool _isClicked = false;

  Color get _iconColor {
    if (widget.iconColorOnClick != null && _isClicked) {
      return widget.iconColorOnClick!;
    }
    if (widget.iconColorOnHover != null && _isHovered) {
      return widget.iconColorOnHover!;
    }
    return widget.iconColor;
  }

  Color get _overlayColor {
    if (widget.overlayColorOnClick != null && _isClicked) {
      return widget.overlayColorOnClick!;
    }
    return _isHovered ? widget.overlayColor : Colors.transparent;
  }

  Widget _buildIconOrChild() {
    if (widget.child != null) {
      return widget.child!;
    }

    final Widget iconWidget = widget.icon != null
        ? AppIcon(widget.icon!, size: widget.iconSize, color: _iconColor)
        : SvgPicture.asset(
            widget.svgAssetPath!,
            width: widget.iconSize,
            height: widget.iconSize,
            colorFilter: ColorFilter.mode(_iconColor, BlendMode.srcIn),
          );

    if (widget.title != null) {
      return Row(
        mainAxisAlignment: .center,
        children: [
          iconWidget,
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              widget.title!,
              maxLines: 1,
              overflow: .ellipsis,
              style: Theme.of(context).textTheme.labelLarge
                  ?.copyWith(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
            ),
          ),
        ],
      );
    }

    return Center(child: iconWidget);
  }

  @override
  Widget build(BuildContext context) {
    final button = MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: widget.enableSplash
          ? Material(
              color: Colors.transparent,
              child: InkWell(
                customBorder: widget.overlayShape == BoxShape.circle ? const CircleBorder() : null,
                onTapDown: (_) => setState(() => _isClicked = true),
                onTapUp: (_) => setState(() => _isClicked = false),
                onTapCancel: () => setState(() => _isClicked = false),
                onTap: widget.onClick,
                child: Container(
                  padding: widget.padding,
                  height: widget.buttonHeight,
                  width: widget.buttonWidth,
                  decoration: BoxDecoration(shape: widget.overlayShape, color: _overlayColor),
                  child: _buildIconOrChild(),
                ),
              ),
            )
          : GestureDetector(
              onTapDown: (_) => setState(() => _isClicked = true),
              onTapUp: (_) => setState(() => _isClicked = false),
              onTapCancel: () => setState(() => _isClicked = false),
              onTap: widget.onClick,
              child: Container(
                padding: widget.padding,
                height: widget.buttonHeight,
                width: widget.buttonWidth,
                decoration: BoxDecoration(shape: widget.overlayShape, color: _overlayColor),
                child: _buildIconOrChild(),
              ),
            ),
    );

    if (widget.tooltip != null) {
      return Tooltip(message: widget.tooltip!, waitDuration: const Duration(milliseconds: 500), child: button);
    }

    return button;
  }
}
