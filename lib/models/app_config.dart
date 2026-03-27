import 'package:flutter/rendering.dart';
import 'package:logger/logger.dart';
import 'package:nordplayer/models/app_theme.dart';

class AppConfig {
  final List<String> musicPaths;
  final List<String> artistDelimiters;
  final String theme;
  final bool adaptiveBg;
  final double adaptiveBgBlur;
  final double adaptiveBgDimmer;
  final BoxFit adaptiveBgBoxFit;
  final double textScale;

  static const List<String> _defaultMusicPath = [];
  // Not private because settings page need access
  static const List<String> defaultArtistDelimiters = [',', ';', '/', '+', '&'];
  static const String _defaultTheme = 'nord';
  static const bool _defaultAdaptiveBg = false;
  static const double _defaultAdaptiveBgBlur = 40;
  static const double _defaultAdaptiveBgDimmer = 0.4;
  static const BoxFit _defaultAdaptiveBgBoxFit = BoxFit.cover;
  static const double _defaultTextScale = 1.0;

  AppConfig({
    this.musicPaths = _defaultMusicPath,
    this.artistDelimiters = defaultArtistDelimiters,
    this.theme = _defaultTheme,
    this.adaptiveBg = _defaultAdaptiveBg,
    this.adaptiveBgBlur = _defaultAdaptiveBgBlur,
    this.adaptiveBgDimmer = _defaultAdaptiveBgDimmer,
    this.adaptiveBgBoxFit = _defaultAdaptiveBgBoxFit,
    this.textScale = _defaultTextScale,
  });

  AppConfig copyWith({
    List<String>? musicPaths,
    List<String>? artistDelimiters,
    String? theme,
    bool? adaptiveBg,
    double? adaptiveBgBlur,
    double? adaptiveBgDimmer,
    BoxFit? adaptiveBgBoxFit,
    double? textScale,
  }) {
    return AppConfig(
      musicPaths: musicPaths ?? this.musicPaths,
      artistDelimiters: artistDelimiters ?? this.artistDelimiters,
      theme: theme ?? this.theme,
      adaptiveBg: adaptiveBg ?? this.adaptiveBg,
      adaptiveBgBlur: adaptiveBgBlur ?? this.adaptiveBgBlur,
      adaptiveBgDimmer: adaptiveBgDimmer ?? this.adaptiveBgDimmer,
      adaptiveBgBoxFit: adaptiveBgBoxFit ?? this.adaptiveBgBoxFit,
      textScale: textScale ?? this.textScale,
    );
  }

  factory AppConfig.fromJson(
    Map<String, dynamic> json, {
    required Logger logger,
  }) {
    return AppConfig(
      musicPaths: _parseMusicPath(json['musicPath'], logger: logger),
      artistDelimiters: _parseArtistDelimiters(
        json['artistDelimiters'],
        logger: logger,
      ),
      theme: _parseTheme(json['theme'], logger: logger),
      adaptiveBg: _parseAdaptiveBg(json['adaptiveBg'], logger: logger),
      adaptiveBgBlur: _parseBlur(json['blur'], logger: logger),
      adaptiveBgDimmer: _parseDimmer(json['dimmer'], logger: logger),
      adaptiveBgBoxFit: _parseBoxFit(json['boxFit'], logger: logger),
      textScale: _parseTextScale(json['textScale'], logger: logger),
    );
  }
  static List<String> _parseMusicPath(dynamic value, {required Logger logger}) {
    if (value is! List) {
      logger.w(
        "Invalid music path(s): $value. Replaced with '$_defaultMusicPath'.",
      );
      return _defaultMusicPath;
    }

    final safeList = value.whereType<String>().toList();
    return safeList;
  }

  static List<String> _parseArtistDelimiters(
    dynamic value, {
    required Logger logger,
  }) {
    if (value is! List) {
      logger.w("Invalid artist delimiters: $value. Fallback to default.");
      return defaultArtistDelimiters;
    }

    final safeList = value.whereType<String>().toList();

    return safeList;
  }

  static String _parseTheme(dynamic value, {required Logger logger}) {
    if (value is! String) {
      logger.w("Invalid theme type: $value. Fallback to '$_defaultTheme.");
      return _defaultTheme;
    }

    if (!AppTheme.themes.containsKey(value)) {
      logger.w("Invalid theme config '$value'. Fallback to '$_defaultTheme'.");
      return _defaultTheme;
    }

    return value;
  }

  static bool _parseAdaptiveBg(dynamic value, {required Logger logger}) {
    if (value is! bool) {
      logger.w("Invalid text scale: $value. Fallback to '$_defaultAdaptiveBg.");
      return _defaultAdaptiveBg;
    }

    return value;
  }

  static double _parseBlur(dynamic value, {required Logger logger}) {
    if (value is! num) {
      logger.w(
        "Invalid text scale: $value. Fallback to '$_defaultAdaptiveBgBlur.",
      );
      return _defaultAdaptiveBgBlur;
    }

    return value.toDouble();
  }

  static double _parseDimmer(dynamic value, {required Logger logger}) {
    if (value is! num) {
      logger.w(
        "Invalid text scale: $value. Fallback to '$_defaultAdaptiveBgDimmer.",
      );
      return _defaultAdaptiveBgDimmer;
    }

    return value.toDouble();
  }

  static BoxFit _parseBoxFit(dynamic value, {required Logger logger}) {
    if (value is! String) {
      logger.w(
        "Invalid boxFit type: $value. Fallback to '$_defaultAdaptiveBgBoxFit'.",
      );
      return _defaultAdaptiveBgBoxFit;
    }

    try {
      return BoxFit.values.byName(value);
    } catch (e) {
      // Catches the error if the string doesn't match any BoxFit enum name
      logger.w(
        "Unknown boxFit value: $value. Fallback to '$_defaultAdaptiveBgBoxFit'.",
      );
      return _defaultAdaptiveBgBoxFit;
    }
  }

  static double _parseTextScale(dynamic value, {required Logger logger}) {
    if (value is! num) {
      logger.w("Invalid text scale: $value. Fallback to '$_defaultTextScale.");
      return _defaultTextScale;
    }

    return value.toDouble();
  }

  Map<String, dynamic> toJson() {
    return {
      'musicPath': musicPaths,
      'artistDelimiters': artistDelimiters,
      'theme': theme,
      'adaptiveBg': adaptiveBg,
      'blur': adaptiveBgBlur,
      'dimmer': adaptiveBgDimmer,
      'boxfit': adaptiveBgBoxFit.name,
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

    return rawArtist
        .split(regex)
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }
}
