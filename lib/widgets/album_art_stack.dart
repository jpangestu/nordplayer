import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';

class AlbumArtStack extends StatelessWidget {
  final List<String> imageUrls;

  // 1. Make size optional. If null, it adapts dynamically.
  final double? size;
  final int maxLayers;
  final double sliceWidth;

  const AlbumArtStack({
    super.key,
    required this.imageUrls,
    this.size, // Defaults to null for dynamic scaling
    this.maxLayers = 5,
    this.sliceWidth = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate layer count and the extra width they take up
        final int count = imageUrls.isEmpty
            ? 1
            : math.min(imageUrls.length, maxLayers);
        final double extraWidth = (count - 1) * sliceWidth;

        // Find the largest square that fits in BOTH the height and width limits.
        double squareSize =
            size ??
            math.min(constraints.maxHeight, constraints.maxWidth - extraWidth);

        if (squareSize < 0) squareSize = 0;

        final double totalWidth = squareSize + extraWidth;

        // -- EMPTY STATE --
        if (imageUrls.isEmpty) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [theme.colorScheme.primary, theme.colorScheme.tertiary],
              ),
            ),
            child: Icon(
              Icons.queue_music,
              color: theme.colorScheme.onPrimary,
              size: squareSize * 0.25, // Dynamically scale the icon
            ),
          );
        }

        // -- POPULATED STATE --
        final List<String> displayUrls = imageUrls
            .take(count)
            .toList()
            .reversed
            .toList();

        return Center(
          // Center the entire stack within the Expanded card bounds
          child: SizedBox(
            width: totalWidth,
            height: squareSize,
            child: Stack(
              children: List.generate(count, (index) {
                final double leftOffset = (count - 1 - index) * sliceWidth;

                final imageUrl = displayUrls[index];
                final file = File(Uri.parse(imageUrl).toFilePath());
                final hasImage = imageUrl.isNotEmpty && file.existsSync();

                return AnimatedPositioned(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.linear,
                  top: 0,
                  bottom: 0,
                  left: leftOffset,
                  // Force the width to perfectly match the height
                  width: squareSize,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      image: hasImage
                          ? DecorationImage(
                              image: FileImage(file),
                              fit: BoxFit.cover,
                            )
                          : null,
                      gradient: !hasImage
                          ? LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                theme.colorScheme.primary,
                                theme.colorScheme.tertiary,
                              ],
                            )
                          : null,
                    ),
                    child: !hasImage
                        ? Icon(
                            Icons.music_note,
                            color: theme.colorScheme.onPrimary,
                            size: squareSize * 0.3,
                          )
                        : null,
                  ),
                );
              }),
            ),
          ),
        );
      },
    );
  }
}
