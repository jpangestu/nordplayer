import 'package:flutter_svg/svg.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nordplayer/widgets/app_icon.dart';

/// For the icon itself, choose whether to use icon (IconData) or svgAssetPath or child widget
class BaseButton extends StatefulWidget {
  final IconData? icon;
  final String? svgAssetPath;
  final double buttonHeight;
  final double buttonWidth;
  final EdgeInsets padding;
  final VoidCallback onClick;

  final double iconSize;
  final Color iconColor;
  final Color? iconColorOnHover;
  final Color? iconColorOnClick;

  final String? title;

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
    this.padding = const EdgeInsets.all(0),
    required this.onClick,
    this.iconSize = 16,
    required this.iconColor,
    this.iconColorOnHover,
    this.iconColorOnClick,
    this.title,
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

  Widget _buildChild() {
    if (widget.child != null) {
      return widget.child!;
    }

    if (widget.icon != null) {
      final iconWidget = AppIcon(widget.icon!, size: widget.iconSize, color: _iconColor);

      if (widget.title != null) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            iconWidget,
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                widget.title!,
                maxLines: 1,
                overflow: .ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ],
        );
      }

      return iconWidget;
    }

    return Center(
      child: SvgPicture.asset(
        widget.svgAssetPath!,
        width: widget.iconSize,
        height: widget.iconSize,
        colorFilter: ColorFilter.mode(_iconColor, BlendMode.srcIn),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final button = Center(
      child: Container(
        clipBehavior: .antiAlias,
        height: widget.buttonHeight,
        width: widget.buttonWidth,
        decoration: BoxDecoration(shape: widget.overlayShape, color: _isHovered ? _overlayColor : Colors.transparent),
        child: MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: InkWell(
            customBorder: widget.overlayShape == BoxShape.circle ? const CircleBorder() : null,
            onTapDown: (_) => setState(() => _isClicked = true),
            onTapUp: (_) => setState(() => _isClicked = false),
            onTapCancel: () => setState(() => _isClicked = false),
            onTap: widget.onClick,
            child: Padding(padding: widget.padding, child: _buildChild()),
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
