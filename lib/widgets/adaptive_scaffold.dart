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
    final adaptiveBg = appConfig.adaptiveBg;
    final blur = appConfig.blur;
    final dimmer = appConfig.dimmer;
    final boxFit = appConfig.boxFit;
    final currentTrack = ref.watch(currentTrackProvider);
    final currentAlbumArtPath = currentTrack?.album.albumArtPath;

    final cacheW = _getCacheWidth(blur);

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          // LAYER 1: The Album Artwork
          if (adaptiveBg) ...[
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
                            sigmaX: blur,
                            sigmaY: blur,
                            // tileMode: TileMode.clamp,
                          ),
                          child: Image.file(
                            File(currentAlbumArtPath),
                            fit: boxFit,
                            cacheWidth: cacheW,
                            colorBlendMode: BlendMode.darken,
                            errorBuilder: (_, _, _) =>
                                getFallbackBackground(context),
                          ),
                        ),
                      )
                    : getFallbackBackground(context),
              ),
            ),

            // LAYER 3: The Dimmer
            Positioned.fill(
              child: Container(
                color:
                    (Theme.of(context).brightness == Brightness.dark
                            ? Theme.of(context).colorScheme.surface
                            : Colors.white)
                        .withValues(alpha: dimmer),
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
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
            Theme.of(context).scaffoldBackgroundColor,
          ],
        ),
      ),
    );
  }

  int? _getCacheWidth(double blur) {
    if (blur <= 10) return null;
    final int calculatedWidth = (300 - (blur * 5)).round();
    return calculatedWidth.clamp(50, 300);
  }
}
