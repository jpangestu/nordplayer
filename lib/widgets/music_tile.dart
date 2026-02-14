import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:nordplayer/services/logger.dart';
import 'package:nordplayer/theme/nord_theme.dart';

class MusicTile extends StatefulWidget {
  final String title;
  final List<String> artists;
  final String? artPath;
  final double? artSize;

  const MusicTile({
    super.key,
    required this.title,
    required this.artists,
    this.artPath,
    this.artSize,
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
    // Generate a permanent recognizer for each artist
    for (var artist in widget.artists) {
      _recognizers.add(
        TapGestureRecognizer()
          ..onTap = () {
            log.d('$artist is tapped');
          },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned.fill(
            child: InkWell(
              onTap: () {
                log.d('${widget.title} is tapped');
              },
              borderRadius: .circular(8),
            ),
          ),
          Padding(
            padding: .all(8),
            child: Row(
              children: [
                IgnorePointer(
                  child: widget.artPath != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.asset(
                            widget.artPath!,
                            width: widget.artSize ?? 45,
                            height: widget.artSize ?? 45,
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Icon(Icons.music_note, size: 50),
                ),

                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisAlignment: .center,
                    crossAxisAlignment: .start,
                    children: [
                      IgnorePointer(
                        child: DefaultTextStyle(
                          style: theme.textTheme.titleMedium!,
                          textAlign: .start,
                          overflow: .ellipsis,
                          child: Text(widget.title),
                        ),
                      ),
                      RichText(
                        overflow: .ellipsis,
                        text: TextSpan(children: _buildArtistsSpan()),
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

  List<TextSpan> _buildArtistsSpan() {
    final List<TextSpan> artistSpan = [];

    for (int i = 0; i < widget.artists.length; i++) {
      if (i >= _recognizers.length) break;
      if (i > 0) {
        artistSpan.add(
          TextSpan(
            text: ', ',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: NordColors.nord5,
            ),
          ),
        );
      }

      artistSpan.add(
        TextSpan(
          text: widget.artists[i],
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: NordColors.nord5,
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
