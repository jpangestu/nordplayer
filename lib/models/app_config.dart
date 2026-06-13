import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:nordplayer/models/app_theme.dart';

class AppConfig {
  final List<String> trackDirectories;
  final bool watchTrackDirectories;
  final List<String> artistDelimiters;
  final String theme;
  final Brightness themeBrightness;
  final String iconSet;
  final bool adaptiveBg;
  final BoxFit adaptiveBgAlbumFit;
  final double adaptiveBgAlbumBlur;
  final double adaptiveBgPanelBlur;
  final double adaptiveBgThemeOverlay;
  final String fontFamily;
  final double textScale;

  static const List<String> _defaultTrackDirectories = [];
  // Not private because settings page need access
  static const List<String> defaultArtistDelimiters = [
    ',',
    ';',
    '/',
    '+',
    '&',
    'feat.',
    'feat',
    'ft.',
    'ft',
    'featuring',
  ];
  static const String _defaultTheme = 'nord';
  static const Brightness _defaultThemeBrightness = Brightness.dark;
  static const String _defaultIconSet = 'lucide';
  static const bool _defaultAdaptiveBg = false;
  static const BoxFit _defaultAdaptiveBgAlbumFit = BoxFit.cover;
  static const double _defaultAdaptiveBgAlbumBlur = 20;
  static const double _defaultAdaptiveBgPanelBlur = 20;
  static const double _defaultAdaptiveBgThemeOverlay = 0.5;
  static const String _defaultFontFamily = 'outfit';
  static const double _defaultTextScale = 1.0;
  static const bool _defaultWatchTrackDirectories = true;

  AppConfig({
    this.trackDirectories = _defaultTrackDirectories,
    this.watchTrackDirectories = _defaultWatchTrackDirectories,
    this.artistDelimiters = defaultArtistDelimiters,
    this.theme = _defaultTheme,
    this.themeBrightness = _defaultThemeBrightness,
    this.iconSet = _defaultIconSet,
    this.adaptiveBg = _defaultAdaptiveBg,
    this.adaptiveBgAlbumFit = _defaultAdaptiveBgAlbumFit,
    this.adaptiveBgAlbumBlur = _defaultAdaptiveBgAlbumBlur,
    this.adaptiveBgPanelBlur = _defaultAdaptiveBgPanelBlur,
    this.adaptiveBgThemeOverlay = _defaultAdaptiveBgThemeOverlay,
    this.fontFamily = _defaultFontFamily,
    this.textScale = _defaultTextScale,
  });

  AppConfig copyWith({
    List<String>? trackDirectories,
    bool? watchTrackDirectories,
    List<String>? artistDelimiters,
    String? theme,
    Brightness? themeBrightness,
    String? iconSet,
    bool? adaptiveBg,
    BoxFit? adaptiveBgAlbumFit,
    double? adaptiveBgAlbumBlur,
    double? adaptiveBgPanelBlur,
    double? adaptiveBgThemeOverlay,
    String? fontFamily,
    double? textScale,
  }) {
    return AppConfig(
      trackDirectories: trackDirectories ?? this.trackDirectories,
      watchTrackDirectories: watchTrackDirectories ?? this.watchTrackDirectories,
      artistDelimiters: artistDelimiters ?? this.artistDelimiters,
      theme: theme ?? this.theme,
      themeBrightness: themeBrightness ?? this.themeBrightness,
      iconSet: iconSet ?? this.iconSet,
      adaptiveBg: adaptiveBg ?? this.adaptiveBg,
      adaptiveBgAlbumFit: adaptiveBgAlbumFit ?? this.adaptiveBgAlbumFit,
      adaptiveBgAlbumBlur: adaptiveBgAlbumBlur ?? this.adaptiveBgAlbumBlur,
      adaptiveBgPanelBlur: adaptiveBgPanelBlur ?? this.adaptiveBgPanelBlur,
      adaptiveBgThemeOverlay: adaptiveBgThemeOverlay ?? this.adaptiveBgThemeOverlay,
      fontFamily: fontFamily ?? this.fontFamily,
      textScale: textScale ?? this.textScale,
    );
  }

  factory AppConfig.fromJson(Map<String, dynamic> json, {required Logger logger}) {
    return AppConfig(
      trackDirectories: _parsetrackDirectories(json['trackDirectories'], logger: logger),
      watchTrackDirectories: _parseWatchTrackDirectories(json['watchTrackDirectories'], logger: logger),
      artistDelimiters: _parseArtistDelimiters(json['artistDelimiters'], logger: logger),
      theme: _parseTheme(json['theme'], logger: logger),
      themeBrightness: _parseThemeBrightness(json['themeBrightness'], logger: logger),
      iconSet: _parseIconSet(json['iconSet'], logger: logger),
      adaptiveBg: _parseAdaptiveBg(json['adaptiveBg'], logger: logger),
      adaptiveBgAlbumFit: _parseAlbumFit(json['albumFit'], logger: logger),
      adaptiveBgAlbumBlur: _parseAlbumBlur(json['albumBlur'], logger: logger),
      adaptiveBgPanelBlur: _parsePanelBlur(json['panelBlur'], logger: logger),
      adaptiveBgThemeOverlay: _parseThemeOverlay(json['themeOverlay'], logger: logger),
      fontFamily: _parseFontFamily(json['fontFamily'], logger: logger),
      textScale: _parseTextScale(json['textScale'], logger: logger),
    );
  }

  static List<String> _parsetrackDirectories(dynamic value, {required Logger logger}) {
    if (value is! List) {
      logger.w("Invalid track directory: $value. Replaced with '$_defaultTrackDirectories'.");
      return _defaultTrackDirectories;
    }

    final safeList = value.whereType<String>().toList();
    return safeList;
  }

  static bool _parseWatchTrackDirectories(dynamic value, {required Logger logger}) {
    if (value is! bool) {
      logger.w("Invalid watchTrackDirectories: $value. Fallback to '$_defaultWatchTrackDirectories'.");
      return _defaultWatchTrackDirectories;
    }

    return value;
  }

  static List<String> _parseArtistDelimiters(dynamic value, {required Logger logger}) {
    if (value is! List) {
      logger.w("Invalid artist delimiters: $value. Fallback to default.");
      return defaultArtistDelimiters;
    }

    final safeList = value.whereType<String>().toList();

    return safeList;
  }

  static String _parseTheme(dynamic value, {required Logger logger}) {
    if (value is! String) {
      logger.w("Invalid theme type: $value. Fallback to '$_defaultTheme'.");
      return _defaultTheme;
    }

    if (!AppTheme.labels.containsKey(value)) {
      logger.w("Invalid theme config '$value'. Fallback to '$_defaultTheme'.");
      return _defaultTheme;
    }

    return value;
  }

  static Brightness _parseThemeBrightness(dynamic value, {required Logger logger}) {
    if (value is! String) {
      logger.w("Invalid brightness type: $value. Fallback to '$_defaultThemeBrightness'.");
      return _defaultThemeBrightness;
    }

    try {
      return Brightness.values.byName(value);
    } catch (e) {
      logger.w("Unknown brightness value: $value. Fallback to '$_defaultThemeBrightness'.");
      return _defaultThemeBrightness;
    }
  }

  static String _parseIconSet(dynamic value, {required Logger logger}) {
    if (value is! String || (value != 'lucide' && value != 'material')) {
      logger.w("Invalid icon set: $value. Fallback to '$_defaultIconSet'.");
      return _defaultIconSet;
    }
    return value;
  }

  static bool _parseAdaptiveBg(dynamic value, {required Logger logger}) {
    if (value is! bool) {
      logger.w("Invalid adaptive background: $value. Fallback to '$_defaultAdaptiveBg'.");
      return _defaultAdaptiveBg;
    }

    return value;
  }

  static BoxFit _parseAlbumFit(dynamic value, {required Logger logger}) {
    if (value is! String) {
      logger.w("Invalid BoxFit type: $value. Fallback to '$_defaultAdaptiveBgAlbumFit'.");
      return _defaultAdaptiveBgAlbumFit;
    }

    try {
      return BoxFit.values.byName(value);
    } catch (e) {
      // Catches the error if the string doesn't match any BoxFit enum name
      logger.w("Unknown BoxFit value: $value. Fallback to '$_defaultAdaptiveBgAlbumFit'.");
      return _defaultAdaptiveBgAlbumFit;
    }
  }

  static double _parseAlbumBlur(dynamic value, {required Logger logger}) {
    if (value is! num) {
      logger.w("Invalid album blur: $value. Fallback to '$_defaultAdaptiveBgAlbumBlur'.");
      return _defaultAdaptiveBgAlbumBlur;
    }

    return value.toDouble();
  }

  static double _parsePanelBlur(dynamic value, {required Logger logger}) {
    if (value is! num) {
      logger.w("Invalid panel blur: $value. Fallback to '$_defaultAdaptiveBgPanelBlur'.");
      return _defaultAdaptiveBgPanelBlur;
    }

    return value.toDouble();
  }

  static double _parseThemeOverlay(dynamic value, {required Logger logger}) {
    if (value is! num) {
      logger.w("Invalid background themeOverlay: $value. Fallback to '$_defaultAdaptiveBgThemeOverlay'.");
      return _defaultAdaptiveBgThemeOverlay;
    }

    return value.toDouble();
  }

  static String _parseFontFamily(dynamic value, {required Logger logger}) {
    if (value is! String) {
      logger.w("Invalid font family: $value. Fallback to '$_defaultFontFamily'.");
      return _defaultFontFamily;
    }
    return value;
  }

  static double _parseTextScale(dynamic value, {required Logger logger}) {
    if (value is! num) {
      logger.w("Invalid text scale: $value. Fallback to '$_defaultTextScale'.");
      return _defaultTextScale;
    }

    return value.toDouble();
  }

  Map<String, dynamic> toJson() {
    return {
      'trackDirectories': trackDirectories,
      'watchTrackDirectories': watchTrackDirectories,
      'artistDelimiters': artistDelimiters,
      'theme': theme,
      'themeBrightness': themeBrightness.name,
      'iconSet': iconSet,
      'adaptiveBg': adaptiveBg,
      'albumFit': adaptiveBgAlbumFit.name,
      'albumBlur': adaptiveBgAlbumBlur,
      'panelBlur': adaptiveBgPanelBlur,
      'themeOverlay': adaptiveBgThemeOverlay,
      'fontFamily': fontFamily,
      'textScale': textScale,
    };
  }
}
