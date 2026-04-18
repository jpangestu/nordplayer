import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nordplayer/theming/icon-sets/app_icon_set.dart';
import 'package:nordplayer/widgets/app_icon.dart';

class AlbumArtWall extends ConsumerWidget {
  final List<String> imageUrls;

  const AlbumArtWall({super.key, required this.imageUrls});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final appIconSet = ref.watch(appIconProvider);

    if (imageUrls.isEmpty) {
      return Container(color: theme.colorScheme.surface);
    }

    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            // Make the container much taller/wider than the header itself
            // to ensure the empty corners are hidden off-screen.
            top: -300,
            bottom: -300,
            left: -200,
            right: -200,
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(0, 1, -0.1)
                ..rotateZ(-0.12),
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 120,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                // Render a ton of items to fill the massive hidden overflow area
                itemCount: 300,
                itemBuilder: (context, index) {
                  final imageUrl = imageUrls[index % imageUrls.length];
                  final file = File(Uri.parse(imageUrl).toFilePath());

                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: theme.colorScheme.surfaceContainerHigh,
                      image: file.existsSync() ? DecorationImage(image: FileImage(file), fit: BoxFit.cover) : null,
                    ),
                    child: !file.existsSync() ? AppIcon(appIconSet.musicTile, color: Colors.white24) : null,
                  );
                },
              ),
            ),
          ),

          // Vertical Fade
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.0, 0.4, 0.8, 1.0],
                colors: [
                  theme.colorScheme.surface.withValues(alpha: 0.3),
                  theme.colorScheme.surface.withValues(alpha: 0.7),
                  theme.colorScheme.surface.withValues(alpha: 0.95),
                  theme.colorScheme.surface,
                ],
              ),
            ),
          ),

          // Horizontal Fade (Darkens the left side for readability)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                stops: const [0.0, 0.4, 1.0],
                colors: [
                  theme.colorScheme.surface.withValues(alpha: 0.95),
                  theme.colorScheme.surface.withValues(alpha: 0.5),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
