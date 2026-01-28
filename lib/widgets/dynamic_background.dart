import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:suara/models/song.dart';
import 'package:suara/services/audio_service.dart';

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
    return Stack(
      children: [
        // LAYER 1: The Album Artwork
        // Use RepaintBoundary to separate this heavy layer from the UI updates.
        RepaintBoundary(
          child: StreamBuilder<Song?>(
            stream: AudioService().currentSongStream,
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
                          imageFilter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                          child: Image.file(
                            File(artPath),
                            fit: BoxFit.fill,
                            color: Color.fromRGBO(0, 0, 0, 0.3),
                            colorBlendMode: BlendMode.darken,
                            errorBuilder: (_, _, _) =>
                                Container(color: Colors.black), // Fallback
                          ),
                        ),
                      )
                    : Container(
                        key: const ValueKey('empty'), // Key for empty state
                        color: Theme.of(context).scaffoldBackgroundColor,
                      ),
              );
            },
          ),
        ),

        // LAYER 2: The Dimmer (Extra Contrast)
        Positioned.fill(child: Container(color: Color.fromRGBO(0, 0, 0, 0.5))),

        // LAYER 3: The Actual App Content
        Scaffold(
          // Important: Transparent so we see the layers below
          backgroundColor: Colors.transparent,
          body: body,
          bottomNavigationBar: bottomNavigationBar,
        ),
      ],
    );
  }
}
