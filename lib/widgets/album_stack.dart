import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';

class AlbumStack extends StatelessWidget {
  final List<String> imageUrls;
  final double size;
  final int maxLayers;

  /// Increased slice width for a "bigger" visible part on the right
  final double sliceWidth;

  const AlbumStack({
    super.key,
    required this.imageUrls,
    this.size = 180.0,
    this.maxLayers = 4,
    this.sliceWidth = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrls.isEmpty) {
      return Container(
        width: size,
        height: size,
        color: Colors.grey[850],
        child: const Icon(Icons.music_note, color: Colors.white24, size: 48),
      );
    }

    final int count = math.min(imageUrls.length, maxLayers);
    // Reverse the list so the first items are rendered LAST (on top)
    final List<String> displayUrls = imageUrls
        .take(count)
        .toList()
        .reversed
        .toList();

    final double totalWidth = size + ((count - 1) * sliceWidth);

    return SizedBox(
      width: totalWidth,
      height: size,
      child: Stack(
        children: List.generate(count, (index) {
          final double leftOffset = (count - 1 - index) * sliceWidth;

          return Positioned(
            top: 0,
            bottom: 0,
            left: leftOffset,
            width: size,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                image: DecorationImage(
                  image: FileImage(
                    File(Uri.parse(displayUrls[index]).toFilePath()),
                  ),
                  fit: BoxFit.cover,
                ),
                border: Border.all(
                  color: Colors.black.withValues(alpha: 0.5),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.6),
                    // Shadow cast to the right to define the slice edge
                    offset: const Offset(4, 0),
                    blurRadius: 8.0,
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
