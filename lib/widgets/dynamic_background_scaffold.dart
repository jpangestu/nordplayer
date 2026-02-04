import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
// import 'package:suara/models/song.dart'; // No longer strictly needed for explicit type checks, but good to keep
import 'package:suara/models/texture_profile.dart';
import 'package:suara/services/audio_service.dart';
import 'package:suara/services/config_service.dart'; 

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
    return ListenableBuilder(
      listenable: ConfigService(),
      builder: (context, _) {
        final config = ConfigService().config;
        final adaptiveBackground = config.adaptiveBackground;
        final texturedLayer = config.texturedLayer;
        
        final TextureProfile activeTexture = config.activeTexture; 
        final double dimLevel = config.globalDimmer;

        // Calculate cache width once
        final cacheW = _getCacheWidth(adaptiveBackground.blur);

        return Stack(
          children: [
            // LAYER 1: The Album Artwork
            if (adaptiveBackground.isEnabled)
              RepaintBoundary(
                child: ListenableBuilder(
                  listenable: AudioService(),
                  builder: (context, _) {
                    final artPath = AudioService().currentSong?.artPath;

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
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.center,
                        radius: 1.5,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.3),
                        ],
                      ),
                    ),
                    child: Opacity(
                      opacity: texturedLayer.opacity,
                      child: _buildTextureImage(
                        activeTexture,
                        texturedLayer.fit,
                      ),
                    ),
                  ),
                ),
              ),

            // LAYER 3: The Dimmer
            Positioned.fill(
              child: Container(
                color: (Theme.of(context).brightness == Brightness.dark
                        ? Colors.black
                        : Colors.white)
                    .withValues(alpha: dimLevel),
              ),
            ),
            
            // LAYER 4: Content
            Scaffold(
              backgroundColor: Colors.transparent,
              body: body,
              bottomNavigationBar: bottomNavigationBar,
            ),
          ],
        );
      },
    );
  }

  // ... (Your Helper Methods remain exactly the same) ...

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

  Widget _buildTextureImage(TextureProfile profile, BoxFit fit) {
    final repeat = fit == BoxFit.none
        ? ImageRepeat.repeat
        : ImageRepeat.noRepeat;

    if (profile.type == TextureType.file) {
      return Image.file(
        File(profile.path),
        repeat: repeat,
        fit: fit,
        errorBuilder: (_, __, ___) => const SizedBox(), 
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

  int? _getCacheWidth(double blur) {
    if (blur < 5) return null; 
    final int calculatedWidth = (300 - (blur * 5)).round();
    return calculatedWidth.clamp(50, 300);
  }
}