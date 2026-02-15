import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:nordplayer/services/logger.dart';

class MusicTile extends StatefulWidget {
  final String title;
  final List<String> artists;
  final String? artPath;
  final double? artSize;
  final bool selected;
  final VoidCallback? onTap;

  const MusicTile({
    super.key,
    required this.title,
    required this.artists,
    this.artPath,
    this.artSize,
    this.selected = false,
    required this.onTap,
  });

  @override
  State<MusicTile> createState() => _MusicTileState();
}

class _MusicTileState extends State<MusicTile> with LoggerMixin {
  int _hoveredIndex = -1;
  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void initState() {
    super.initState();
    _updateRecognizers();
  }

  @override
  void didUpdateWidget(MusicTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only recreate if the artist list actually changes
    if (widget.artists != oldWidget.artists) {
      _disposeRecognizers();
      _updateRecognizers();
    }
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _disposeRecognizers() {
    for (var r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
  }

  void _updateRecognizers() {
    for (var artist in widget.artists) {
      _recognizers.add(
        TapGestureRecognizer()
          ..onTap = () {
            log.d('Navigate to Artist: "$artist" (from "${widget.title}")');
          },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final listTileTheme = Theme.of(context).listTileTheme;
    // ListTileTheme.of(context)

    final TextStyle titleStyle =
        listTileTheme.titleTextStyle ?? theme.textTheme.titleMedium!;
    final TextStyle artistStyle =
        listTileTheme.subtitleTextStyle ?? theme.textTheme.bodyMedium!;
    final Color contentColor = widget.selected
        ? (listTileTheme.selectedColor ?? theme.colorScheme.primary)
        : (listTileTheme.textColor ?? theme.colorScheme.onSurface);
    final Color tileColor = widget.selected
        ? (listTileTheme.selectedTileColor ??
              theme.colorScheme.secondaryContainer)
        : (listTileTheme.tileColor ?? Colors.transparent);

    return Material(
      color: tileColor,
      borderRadius: .circular(8),
      child: Stack(
        children: [
          Positioned.fill(
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: .circular(6),
              splashColor: widget.selected
                  ? theme.colorScheme.primary.withValues(alpha: 0.1)
                  : null,
            ),
          ),
          Padding(
            padding: .all(8),
            child: Row(
              children: [
                IgnorePointer(
                  child: widget.artPath != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.asset(
                            widget.artPath!,
                            width: widget.artSize ?? 45,
                            height: widget.artSize ?? 45,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Icon(
                          Icons.music_note,
                          size: 45,
                          color: listTileTheme.iconColor,
                        ),
                ),

                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisAlignment: .center,
                    crossAxisAlignment: .start,
                    children: [
                      IgnorePointer(
                        child: Text(
                          widget.title,
                          style: titleStyle.copyWith(color: contentColor),
                          textAlign: .start,
                          overflow: .ellipsis,
                        ),
                      ),
                      // const SizedBox(height: 2),
                      RichText(
                        overflow: .ellipsis,
                        text: TextSpan(
                          children: _buildArtistsSpan(
                            artistStyle,
                            contentColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<TextSpan> _buildArtistsSpan(TextStyle baseStyle, Color baseColor) {
    final List<TextSpan> artistSpan = [];

    final effectiveColor = widget.selected ? baseColor : baseStyle.color;

    for (int i = 0; i < widget.artists.length; i++) {
      if (i >= _recognizers.length) break;
      if (i > 0) {
        artistSpan.add(
          TextSpan(
            text: ', ',
            style: baseStyle.copyWith(color: effectiveColor),
          ),
        );
      }

      artistSpan.add(
        TextSpan(
          text: widget.artists[i],
          style: baseStyle.copyWith(
            color: effectiveColor,
            decoration: _hoveredIndex == i ? .underline : .none,
          ),
          onEnter: (_) => setState(() => _hoveredIndex = i),
          onExit: (_) => setState(() => _hoveredIndex = -1),
          recognizer: _recognizers[i],
        ),
      );
    }

    return artistSpan;
  }
}
