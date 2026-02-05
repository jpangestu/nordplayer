import 'dart:io';
import 'package:flutter/material.dart';
import 'package:suara/services/audio_service.dart';
import 'package:suara/services/config_service.dart';

class DynamicThemeWrapper extends StatelessWidget {
  final Widget child;

  const DynamicThemeWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AudioService(),
      builder: (context, _) {
        final song = AudioService().currentSong;
        final artPath = song?.artPath;

        return ListenableBuilder(
          listenable: ConfigService(),
          builder: (context, _) {
            final config = ConfigService().config;

            // If no art, just return the normal app (or child)
            if (artPath == null) {
              return Theme(
                data: _getTheme(config.themeMode, null), 
                child: child
              );
            }

            // Generate Scheme from Image
            return FutureBuilder<ColorScheme>(
              future: ColorScheme.fromImageProvider(
                provider: FileImage(File(artPath)),
                // Ask for a scheme that matches the user's preference (Dark/Light)
                brightness: config.themeMode == ThemeMode.light 
                    ? Brightness.light 
                    : Brightness.dark,
              ),
              builder: (context, snapshot) {
                // While loading (or if failed), use default theme
                final scheme = snapshot.data;
                
                return Theme(
                  data: _getTheme(config.themeMode, scheme),
                  child: child,
                );
              },
            );
          },
        );
      },
    );
  }

  ThemeData _getTheme(ThemeMode mode, ColorScheme? scheme) {
    // Base brightness
    final isDark = mode == ThemeMode.dark; 
    
    // If we have a dynamic scheme, use it. Otherwise use default purple/blue.
    final base = isDark ? ThemeData.dark() : ThemeData.light();
    
    if (scheme != null) {
      return base.copyWith(
        colorScheme: scheme,
        // Optional: Force the slider and icons to use the dominant color
        iconTheme: IconThemeData(color: scheme.primary),
        sliderTheme: SliderThemeData(
          activeTrackColor: scheme.primary,
          thumbColor: scheme.primary,
          inactiveTrackColor: scheme.primary.withValues(alpha: 0.3),
        ),
      );
    }
    return base;
  }
}