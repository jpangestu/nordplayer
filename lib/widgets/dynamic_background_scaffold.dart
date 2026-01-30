import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:suara/models/adaptive_background.dart';
import 'package:suara/models/song.dart';
import 'package:suara/services/audio_service.dart';
import 'package:suara/services/theme_service.dart';

class DynamicBackgroundScaffold extends StatelessWidget {
  final Widget body;
  final Widget? bottomNavigationBar;

  const DynamicBackgroundScaffold({
    super.key,
    required this.body,
    this.bottomNavigationBar,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: ThemeService().adaptiveBackgroundStream,
      initialData: ThemeService().adaptiveBackground,
      builder: (context, snapshot) {
        // Default values if data is missing
        final adaptiveBackground = snapshot.data ?? const AdaptiveBackground();
        final bool isEnabled = adaptiveBackground.isEnabled;
        final double blur = adaptiveBackground.blur;
        final double opacity = adaptiveBackground.opacity;
        final BoxFit fit = adaptiveBackground.fit;

        return Stack(
          children: [
            // LAYER 1: The Album Artwork
            // Use RepaintBoundary to separate this heavy layer from the UI updates.
            if (isEnabled)
              RepaintBoundary(
                child: StreamBuilder<Song?>(
                  stream: AudioService().currentSongStream,
                  initialData: AudioService().currentSong,
                  builder: (context, snapshot) {
                    final artPath = snapshot.data?.artPath;

                    return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 600),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,

                      // CRITICAL: The child must change its KEY for animation to trigger
                      child: artPath != null
                          ? SizedBox.expand(
                              key: ValueKey(artPath), // <--- THE KEY
                              child: ImageFiltered(
                                imageFilter: ImageFilter.blur(
                                  sigmaX: blur,
                                  sigmaY: blur,
                                ),
                                child: Image.file(
                                  File(artPath),
                                  fit: fit,
                                  cacheHeight: _getCacheWidth(blur),
                                  cacheWidth: _getCacheWidth(blur),
                                  colorBlendMode: BlendMode.darken,
                                  errorBuilder: (_, _, _) =>
                                      getFallbackBackground(context),
                                ),
                              ),
                            )
                          : getFallbackBackground(context),
                    );
                  },
                ),
              ),

            // LAYER 2: The Dimmer (Extra Contrast)
            Positioned.fill(
              child: Container(
                // FIX: Check the actual brightness of the active theme
                // This works for System, Dark, AND Light modes instantly.
                color:
                    (Theme.of(context).brightness == Brightness.dark
                            ? Colors.black
                            : Colors.white)
                        .withValues(alpha: opacity),
              ),
            ),
            // LAYER 3: The Actual App Content
            Scaffold(
              // Important: Transparent so we see the layers below
              backgroundColor: Colors.transparent,
              body: body,
              bottomNavigationBar: bottomNavigationBar,
            ),
          ],
        );
      },
    );
  }

  Widget getFallbackBackground(BuildContext context) {
    return Container(
      key: const ValueKey('empty'), // Key for AnimatedSwitcher
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            // A hint of color in the top-left
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
            // Fading into the standard background
            Theme.of(context).scaffoldBackgroundColor,
          ],
        ),
      ),
    );
  }

  /// Don't limit max album art resolution if blur is 0. Otherwise, started from 5px blur
  /// keep lowering the resolution for the cache to reduce gpu cost
  int? _getCacheWidth(double blur) {
    if (blur == 0) return null; // Use original resolution
    
    // Start at 300px and subtract 5px for every 1 unit of blur
    final int calculatedWidth = (300 - (blur * 5)).round();
    
    // Clamp values:
    // Max: 300px (Plenty for a blurred background)
    // Min: 50px (Don't let it get too tiny or colors might shift)
    return calculatedWidth.clamp(50, 300);
  }
}
