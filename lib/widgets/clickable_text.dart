import 'package:flutter/material.dart';

class ClickableText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final VoidCallback onTap;

  const ClickableText({super.key, required this.text, this.style, required this.onTap});

  @override
  State<ClickableText> createState() => _ClickableTextState();
}

class _ClickableTextState extends State<ClickableText> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Text(
          widget.text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: widget.style != null
              ? widget.style?.copyWith(
                  decoration: _isHovering ? TextDecoration.underline : TextDecoration.none,
                  decorationColor: widget.style?.color,
                )
              : theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  decoration: _isHovering ? TextDecoration.underline : TextDecoration.none,
                ),
        ),
      ),
    );
  }
}
