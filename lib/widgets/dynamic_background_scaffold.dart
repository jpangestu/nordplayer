import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:suara/models/adaptive_background.dart';
import 'package:suara/models/song.dart';
import 'package:suara/models/texture_profile';
import 'package:suara/models/textured_layer.dart';
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
      builder: (context, snapshotAdaptive) {
        return StreamBuilder(
          stream: ThemeService().texturedLayeredStream,
          builder: (context, snapshotTexture) {
            return StreamBuilder<double>(
              stream: ThemeService().dimmerStream,
              initialData: ThemeService().dimmerLevel,
              builder: (context, snapshot) {
                final dimLevel = snapshot.data ?? ThemeService().dimmerLevel;
                // Default values if data is missing
                final adaptiveBackground =
                    snapshotAdaptive.data ?? const AdaptiveBackground();
                final texturedLayer =
                    snapshotTexture.data ?? const TexturedLayer();

                final TextureProfile activeTexture =
                    texturedLayer.activeTexture ??
                    ThemeService().currentTexture;

                // Calculate cache width once
                final cacheW = _getCacheWidth(adaptiveBackground.blur);

                return Stack(
                  children: [
                    // LAYER 1: The Album Artwork
                    // Use RepaintBoundary to separate this heavy layer from the UI updates.
                    if (adaptiveBackground.isEnabled)
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
                              child: artPath != null
                                  ? SizedBox.expand(
                                      key: ValueKey(artPath),
                                      child: ImageFiltered(
                                        imageFilter: ImageFilter.blur(
                                          sigmaX: adaptiveBackground.blur,
                                          sigmaY: adaptiveBackground.blur,
                                        ),
                                        child: Image.file(
                                          File(artPath),
                                          fit: adaptiveBackground.fit,
                                          // Height will be automatically calculated (respecting the aspect ratio)
                                          cacheWidth: cacheW,
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

                    // LAYER 2: Textured Layer
                    if (texturedLayer.isEnabled)
                      Positioned.fill(
                        child: IgnorePointer(
                          // Let touches pass through
                          child: Container(
                            decoration: BoxDecoration(
                              // Vignette (Darker corners = Depth)
                              gradient: RadialGradient(
                                center: Alignment.center,
                                radius: 1.5,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(
                                    alpha: 0.3,
                                  ), // Dark corners
                                ],
                              ),
                            ),
                            // Noise Texture
                            child: Opacity(
                              opacity: texturedLayer
                                  .opacity, // Keep it VERY subtle (3-5%)
                              child: _buildTextureImage(
                                activeTexture,
                                texturedLayer.fit,
                              ),
                            ),
                          ),
                        ),
                      ),

                    // LAYER 3: The Dimmer (Extra Contrast)
                    Positioned.fill(
                      child: Container(
                        color:
                            (Theme.of(context).brightness == Brightness.dark
                                    ? Colors.black
                                    : Colors.white)
                                .withValues(alpha: dimLevel),
                      ),
                    ),
                    // LAYER 4: The Actual App Content
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
          },
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

  // --- HELPER: Handles Asset vs File logic ---
  Widget _buildTextureImage(TextureProfile profile, BoxFit fit) {
    // If fit is 'none', we almost always want it to repeat (tile).
    // If fit is 'cover', we want no repeat.
    final repeat = fit == BoxFit.none
        ? ImageRepeat.repeat
        : ImageRepeat.noRepeat;

    if (profile.type == TextureType.file) {
      return Image.file(
        File(profile.path),
        repeat: repeat,
        fit: fit,
        errorBuilder: (_, __, ___) => const SizedBox(), // Fail silently
      );
    } else {
      return Image.asset(
        profile.path,
        repeat: repeat,
        fit: fit,
        errorBuilder: (_, __, ___) => const SizedBox(),
      );
    }
  }

  /// Don't limit max album art resolution if blur is 0. Otherwise, started from 5px blur
  /// keep lowering the resolution for the cache to reduce gpu cost
  int? _getCacheWidth(double blur) {
    if (blur < 5) return null; // Use original resolution

    // Start at 300px and subtract 5px for every 1 unit of blur
    final int calculatedWidth = (300 - (blur * 5)).round();

    // Clamp values:
    // Max: 300px (Plenty for a blurred background)
    // Min: 50px (Don't let it get too tiny or colors might shift)
    return calculatedWidth.clamp(50, 300);
  }
}
