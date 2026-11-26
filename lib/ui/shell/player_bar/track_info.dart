import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

class const TrackInfo({
  super.key,
  required final String title,
  required final String artist,
  final String? album,
  final ImageProvider? albumArt,
  final double albumArtSize = 56.0,
  final bool showAlbum = true,
  final bool isFavorite = false,
  final VoidCallback? onFavoriteTap,
  final VoidCallback? onAlbumArtTap,
  final VoidCallback? onTitleTap,
  final VoidCallback? onArtistTap,
  final VoidCallback? onAlbumTap,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final displayAlbum = showAlbum && album != null && album!.isNotEmpty;

    return Row(
      children: [
        _AlbumArt(size: albumArtSize, image: albumArt, onTap: onAlbumArtTap),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            mainAxisAlignment: .center,
            crossAxisAlignment: .start,
            mainAxisSize: .min,
            children: [
              _InteractiveLabel(
                text: title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                  height: 1.25,
                ),
                onTap: onTitleTap,
              ),
              const SizedBox(height: 2),
              _InteractiveLabel(
                text: artist,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.25,
                ),
                onTap: onArtistTap,
              ),
              if (displayAlbum) ...[
                const SizedBox(height: 1),
                _InteractiveLabel(
                  text: album!,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.72),
                    height: 1.2,
                  ),
                  onTap: onAlbumTap,
                ),
              ],
            ],
          ),
        ),
        if (onFavoriteTap != null) ...[
          const SizedBox(width: 4),
          IconButton(
            onPressed: onFavoriteTap,
            icon: Icon(
              LucideIcons.heart,
              size: 16,
              color: isFavorite ? colorScheme.primary : colorScheme.onSurfaceVariant,
            ),
            tooltip: isFavorite ? 'Remove from favorites' : 'Add to favorites',
            padding: const .all(4),
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            style: const ButtonStyle(tapTargetSize: .shrinkWrap),
          ),
        ],
      ],
    );
  }
}

class const _AlbumArt({
  required final double size,
  final ImageProvider? image,
  final VoidCallback? onTap,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final borderRadius = BorderRadius.circular(0);

    Widget placeholder() => ColoredBox(
      color: colorScheme.surfaceContainerHigh,
      child: Center(
        child: Icon(
          LucideIcons.music,
          size: (size * 0.42).clamp(16.0, 26.0),
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );

    final content = SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.35)),
        ),
        child: ClipRRect(
          borderRadius: borderRadius,
          child: image != null
              ? Image(
                  image: image!,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.medium,
                  errorBuilder: (_, _, _) => placeholder(),
                )
              : placeholder(),
        ),
      ),
    );

    if (onTap == null) return content;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(onTap: onTap, child: content),
    );
  }
}

class const _InteractiveLabel({
  required final String text,
  final TextStyle? style,
  final VoidCallback? onTap,
}) extends StatefulWidget {
  @override
  State<_InteractiveLabel> createState() => _InteractiveLabelState();
}

class _InteractiveLabelState extends State<_InteractiveLabel> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final effectiveStyle = _isHovered && widget.onTap != null
        ? widget.style?.copyWith(
            decoration: TextDecoration.underline,
            decorationColor: widget.style?.color,
          )
        : widget.style;

    final label = Text(widget.text, maxLines: 1, overflow: .ellipsis, style: effectiveStyle);

    if (widget.onTap == null) return label;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(onTap: widget.onTap, child: label),
    );
  }
}
