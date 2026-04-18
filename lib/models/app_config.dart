import 'package:flutter/rendering.dart';
import 'package:logger/logger.dart';
import 'package:nordplayer/models/app_theme.dart';

class AppConfig {
  final List<String> musicPaths;
  final List<String> artistDelimiters;
  final String theme;
  final String iconSet;
  final bool adaptiveBg;
  final BoxFit adaptiveBgAlbumFit;
  final double adaptiveBgAlbumBlur;
  final double adaptiveBgPanelBlur;
  final double adaptiveBgThemeOverlay;
  final String fontFamily;
  final double textScale;

  static const List<String> _defaultMusicPaths = [];
  // Not private because settings page need access
  static const List<String> defaultArtistDelimiters = [',', ';', '/', '+', '&'];
  static const String _defaultTheme = 'nord';
  static const String _defaultIconSet = 'lucide';
  static const bool _defaultAdaptiveBg = false;
  static const BoxFit _defaultAdaptiveBgAlbumFit = BoxFit.cover;
  static const double _defaultAdaptiveBgAlbumBlur = 20;
  static const double _defaultAdaptiveBgPanelBlur = 20;
  static const double _defaultAdaptiveBgThemeOverlay = 0.4;
  static const String _defaultFontFamily = 'system';
  static const double _defaultTextScale = 1.0;

  AppConfig({
    this.musicPaths = _defaultMusicPaths,
    this.artistDelimiters = defaultArtistDelimiters,
    this.theme = _defaultTheme,
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
    List<String>? musicPaths,
    List<String>? artistDelimiters,
    String? theme,
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
      musicPaths: musicPaths ?? this.musicPaths,
      artistDelimiters: artistDelimiters ?? this.artistDelimiters,
      theme: theme ?? this.theme,
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
      musicPaths: _parseMusicPaths(json['musicPaths'], logger: logger),
      artistDelimiters: _parseArtistDelimiters(json['artistDelimiters'], logger: logger),
      theme: _parseTheme(json['theme'], logger: logger),
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

  static List<String> _parseMusicPaths(dynamic value, {required Logger logger}) {
    if (value is! List) {
      logger.w("Invalid music path(s): $value. Replaced with '$_defaultMusicPaths'.");
      return _defaultMusicPaths;
    }

    final safeList = value.whereType<String>().toList();
    return safeList;
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
      'musicPaths': musicPaths,
      'artistDelimiters': artistDelimiters,
      'theme': theme,
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

  /// Splits a raw artist string into a list of individual artists using the configured delimiters.
  List<String> splitArtists(String rawArtist) {
    if (artistDelimiters.isEmpty) return [rawArtist.trim()];

    // Escape each delimiter so regex treats characters like '+' or '&' literally,
    // then join them with the regex OR operator '|'
    final pattern = artistDelimiters.map((d) => RegExp.escape(d)).join('|');
    final regex = RegExp(pattern, caseSensitive: false);

    return rawArtist.split(regex).map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  }
}
