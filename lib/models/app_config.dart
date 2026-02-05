import 'package:flutter/material.dart';
import 'package:suara/models/adaptive_background.dart';
import 'package:suara/models/textured_layer.dart';
import 'package:suara/models/texture_profile.dart';

class AppConfig {
  final List<String> musicPaths;
  final ThemeMode themeMode;
  final String fontFamily;
  final double globalDimmer;

  final AdaptiveBackground adaptiveBackground;
  final TexturedLayer texturedLayer;

  final List<TextureProfile> customTextures;

  const AppConfig({
    this.musicPaths = const [],
    this.themeMode = ThemeMode.system,
    this.fontFamily = 'Open Sans',
    this.globalDimmer = 0.5,
    this.adaptiveBackground = const AdaptiveBackground(),
    this.texturedLayer = const TexturedLayer(),
    this.customTextures = const [],
  });

  static const List<String> availableFonts = [
    'Default',
    'Poppins',
    'Roboto',
    'Lato',
    'Open Sans',
    'Montserrat',
    'Oswald',
    'Merriweather',
  ];

  /// Get the active texture
  TextureProfile get activeTexture {
    return texturedLayer.activeTexture ?? TextureProfile.defaultPresets.first;
  }

  /// Get the full list for the Dropdown (Presets + Customs)
  List<TextureProfile> get allTextures {
    return [...TextureProfile.defaultPresets, ...customTextures];
  }

  AppConfig copyWith({
    List<String>? musicPaths,
    ThemeMode? themeMode,
    String? fontFamily,
    double? globalDimmer,
    AdaptiveBackground? adaptiveBackground,
    TexturedLayer? texturedLayer,
    List<TextureProfile>? customTextures,
  }) {
    return AppConfig(
      musicPaths: musicPaths ?? this.musicPaths,
      themeMode: themeMode ?? this.themeMode,
      fontFamily: fontFamily ?? this.fontFamily,
      globalDimmer: globalDimmer ?? this.globalDimmer,
      adaptiveBackground: adaptiveBackground ?? this.adaptiveBackground,
      texturedLayer: texturedLayer ?? this.texturedLayer,
      customTextures: customTextures ?? this.customTextures,
    );
  }

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    return AppConfig(
      musicPaths: (json['musicPaths'] as List?)?.cast<String>() ?? [],
      themeMode: ThemeMode.values.firstWhere(
        (e) => e.name == json['themeMode'],
        orElse: () => ThemeMode.system,
      ),
      fontFamily: json['fontFamily'] ?? 'Poppins',
      globalDimmer: (json['globalDimmer'] as num?)?.toDouble() ?? 0.5,
      adaptiveBackground: AdaptiveBackground.fromMap(
        json['adaptiveBackground'] ?? {},
      ),
      texturedLayer: TexturedLayer.fromMap(json['texturedLayer'] ?? {}),
      customTextures:
          (json['customTextures'] as List?)
              ?.map((e) => TextureProfile.fromMap(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'musicPaths': musicPaths,
      'themeMode': themeMode.name,
      'fontFamily': fontFamily,
      'globalDimmer': globalDimmer,
      'adaptiveBackground': adaptiveBackground.toMap(),
      'texturedLayer': texturedLayer.toMap(),
      'customTextures': customTextures.map((e) => e.toMap()).toList(),
    };
  }
}
