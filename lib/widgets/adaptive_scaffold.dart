import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nordplayer/services/config_service.dart';
import 'package:nordplayer/services/player_service.dart';

class AdaptiveScaffold extends ConsumerWidget {
  const AdaptiveScaffold({super.key, required this.body});

  final Widget body;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appConfig = ref.watch(configServiceProvider).requireValue;
    final currentTrack = ref.watch(currentTrackProvider);
    final currentAlbumArtPath = currentTrack?.album.albumArtPath;

    final cacheW = _getCacheWidth(appConfig.adaptiveBgBlur);

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          // LAYER 1: The Album Artwork
          if (appConfig.adaptiveBg) ...[
            RepaintBoundary(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 600),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: currentAlbumArtPath != null
                    ? SizedBox.expand(
                        key: ValueKey(currentAlbumArtPath),
                        child: ImageFiltered(
                          imageFilter: ImageFilter.blur(
                            sigmaX: appConfig.adaptiveBgBlur,
                            sigmaY: appConfig.adaptiveBgBlur,
                            // tileMode: TileMode.clamp,
                          ),
                          child: Image.file(
                            File(currentAlbumArtPath),
                            fit: appConfig.adaptiveBgBoxFit,
                            cacheWidth: cacheW,
                            // colorBlendMode: BlendMode.darken,
                            gaplessPlayback: true,
                            errorBuilder: (_, _, _) =>
                                getFallbackBackground(context),
                          ),
                        ),
                      )
                    : getFallbackBackground(context),
              ),
            ),

            // LAYER 2: Textured Layer
            // if (appConfig.textureLayer)
            //   Positioned.fill(
            //     child: IgnorePointer(
            //       child: Container(
            //         decoration: BoxDecoration(
            //           gradient: RadialGradient(
            //             center: Alignment.center,
            //             radius: 1.5,
            //             colors: [
            //               Colors.transparent,
            //               Colors.black.withValues(alpha: 0.3),
            //             ],
            //           ),
            //         ),
            //         child: Opacity(
            //           opacity: texturedLayer.opacity,
            //           child: _buildTextureImage(
            //             activeTexture,
            //             texturedLayer.fit,
            //           ),
            //         ),
            //       ),
            //     ),
            //   ),

            // LAYER 3: The Dimmer
            Positioned.fill(
              child: Container(
                color:
                    // (dominantColorAsync.value != null
                    //         ? dominantColorAsync.value!
                    //         : Theme.of(context).colorScheme.surface)
                    //     .withValues(alpha: appConfig.adaptiveBgDimmer),
                    Theme.of(context).colorScheme.surface.withValues(
                      alpha: appConfig.adaptiveBgDimmer,
                    ),
              ),
            ),
          ],

          // LAYER 4: Content
          body,
        ],
      ),
    );
  }

  Widget getFallbackBackground(BuildContext context) {
    return Container(
      key: const ValueKey('empty'),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
            // Colors.transparent,
            // Theme.of(context).scaffoldBackgroundColor,
          ],
        ),
      ),
    );
  }

  int? _getCacheWidth(double blur) {
    // If it's barely blurred, we need full resolution to avoid pixelation
    if (blur <= 10) return null;

    // If it's heavily blurred, squash it down to 50px.
    // It's so blurry no one will see the pixels anyway!
    if (blur >= 50) return 100;

    // For the middle ground, use a moderate 150px resolution.
    return 150;
  }
}
