import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nordplayer/services/logger.dart';
import 'package:nordplayer/theming/icon-sets/app_icon_set.dart';
import 'package:nordplayer/widgets/app_icon.dart';
import 'package:nordplayer/widgets/scrolling_text.dart';

class MusicTile extends ConsumerStatefulWidget {
  const MusicTile({
    super.key,
    required this.title,
    required this.artists,
    this.albumArtPath,
    this.albumArtSize,
    this.selected = false,
    this.onTap,
    this.padding = const EdgeInsets.only(left: 16),
    this.marqueeEffect = false,
  });

  final String title;
  final List<String> artists;
  final String? albumArtPath;

  /// If set, the art size will have fixed size
  final double? albumArtSize;
  final bool selected;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final bool marqueeEffect;

  /// Get the exact tile height for itemExtent
  static double tileHeight(TextScaler textScaler) {
    const double baseSize = 50.0;
    final double artSize = (baseSize * textScaler.scale(1)).clamp(40.0, 80.0);
    const double padding = 8 * 2; // .all(8) = 8 top + 8 bottom
    return artSize + padding;
  }

  @override
  ConsumerState<MusicTile> createState() => _MusicTileState();
}

class _MusicTileState extends ConsumerState<MusicTile> with LoggerMixin {
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
            if (!mounted) return;
            log.d('Navigate to Artist: $artist (from "${widget.title}")');
          },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appIconSet = ref.watch(appIconProvider);
    final theme = Theme.of(context);
    final listTileTheme = Theme.of(context).listTileTheme;
    final textScaler = MediaQuery.textScalerOf(context);
    final double baseSize = widget.albumArtSize ?? 50.0;
    final double responsiveSize = (baseSize * textScaler.scale(1)).clamp(40.0, 80.0);

    final double displaySize = widget.albumArtSize ?? responsiveSize;
    // Calculate the exact pixel size needed for the screen
    // Multiply by devicePixelRatio (e.g., x2 or x3) to keep it crisp on Retina screens
    final int pixelSize = (displaySize * MediaQuery.of(context).devicePixelRatio).toInt();

    final TextStyle titleStyle = listTileTheme.titleTextStyle ?? theme.textTheme.titleMedium!;
    final Color titleSelectedColor = widget.selected
        ? (listTileTheme.selectedColor ?? theme.colorScheme.primary)
        : (listTileTheme.textColor ?? theme.colorScheme.onSurface);
    final TextStyle subtitleStyle = listTileTheme.subtitleTextStyle ?? theme.textTheme.bodyMedium!;

    return SizedBox(
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            if (widget.onTap != null) Positioned.fill(child: InkWell(onTap: widget.onTap)),
            Padding(
              padding: widget.padding,
              child: Row(
                children: [
                  Align(
                    alignment: .center,
                    child: IgnorePointer(
                      child: widget.albumArtPath != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Image.file(
                                File(widget.albumArtPath!),
                                width: widget.albumArtSize ?? responsiveSize,
                                height: widget.albumArtSize ?? responsiveSize,
                                fit: BoxFit.cover,
                                cacheWidth: pixelSize,
                                gaplessPlayback: true,
                                errorBuilder: (_, _, _) =>
                                    AppIcon(appIconSet.musicTile, size: widget.albumArtSize ?? responsiveSize),
                              ),
                            )
                          : AppIcon(
                              appIconSet.musicTile,
                              size: widget.albumArtSize ?? responsiveSize,
                              color: listTileTheme.iconColor,
                            ),
                    ),
                  ),

                  SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      mainAxisSize: .min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.marqueeEffect) ...[
                          IgnorePointer(
                            child: ScrollingText(
                              textSpan: TextSpan(
                                text: widget.title,
                                style: titleStyle.copyWith(color: titleSelectedColor, height: 1.0),
                              ),
                            ),
                          ),
                          ScrollingText(textSpan: TextSpan(children: _buildArtistsSpan(subtitleStyle))),
                        ] else ...[
                          IgnorePointer(
                            child: RichText(
                              text: TextSpan(
                                text: widget.title,
                                style: titleStyle.copyWith(color: titleSelectedColor, height: 1.0),
                              ),
                              maxLines: 1,
                              overflow: .ellipsis,
                            ),
                          ),
                          RichText(
                            text: TextSpan(children: _buildArtistsSpan(subtitleStyle)),
                            maxLines: 1,
                            overflow: .ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<TextSpan> _buildArtistsSpan(TextStyle baseStyle) {
    final List<TextSpan> artistSpan = [];

    for (int i = 0; i < widget.artists.length; i++) {
      if (i >= _recognizers.length) break;
      if (i > 0) {
        artistSpan.add(TextSpan(text: ', ', style: baseStyle.copyWith(height: 1.0)));
      }

      artistSpan.add(
        TextSpan(
          text: widget.artists[i],
          style: baseStyle.copyWith(decoration: _hoveredIndex == i ? .underline : .none),
          onEnter: (_) {
            if (mounted) setState(() => _hoveredIndex = i);
          },
          onExit: (_) {
            if (mounted) setState(() => _hoveredIndex = -1);
          },
          recognizer: _recognizers[i],
        ),
      );
    }

    return artistSpan;
  }
}
