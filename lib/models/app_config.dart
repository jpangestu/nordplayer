import 'package:flutter/rendering.dart';
import 'package:logger/logger.dart';
import 'package:nordplayer/models/app_theme.dart';

class AppConfig {
  final List<String> musicPaths;
  final List<String> artistDelimiters;
  final String theme;
  final bool adaptiveBg;
  final double blur;
  final double dimmer;
  final BoxFit boxFit;
  final double textScale;

  static const List<String> _defaultMusicPath = [];
  // Not private because settings page need access
  static const List<String> defaultArtistDelimiters = [',', ';', '/', '+', '&'];
  static const String _defaultTheme = 'nord';
  static const bool _defaultAdaptiveBg = false;
  static const double _defaultBlur = 40;
  static const double _defaultDimmer = 0.4;
  static const BoxFit _defaultBoxFit = BoxFit.cover;
  static const double _defaultTextScale = 1.0;

  AppConfig({
    this.musicPaths = _defaultMusicPath,
    this.artistDelimiters = defaultArtistDelimiters,
    this.theme = _defaultTheme,
    this.adaptiveBg = _defaultAdaptiveBg,
    this.blur = _defaultBlur,
    this.dimmer = _defaultDimmer,
    this.boxFit = _defaultBoxFit,
    this.textScale = _defaultTextScale,
  });

  AppConfig copyWith({
    List<String>? musicPaths,
    List<String>? artistDelimiters,
    String? theme,
    bool? adaptiveBg,
    double? blur,
    double? dimmer,
    BoxFit? boxFit,
    double? textScale,
  }) {
    return AppConfig(
      musicPaths: musicPaths ?? this.musicPaths,
      artistDelimiters: artistDelimiters ?? this.artistDelimiters,
      theme: theme ?? this.theme,
      adaptiveBg: adaptiveBg ?? this.adaptiveBg,
      blur: blur ?? this.blur,
      dimmer: dimmer ?? this.dimmer,
      boxFit: boxFit ?? this.boxFit,
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
      blur: _parseBlur(json['blur'], logger: logger),
      dimmer: _parseDimmer(json['dimmer'], logger: logger),
      boxFit: _parseBoxFit(json['boxFit'], logger: logger),
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
      logger.w("Invalid text scale: $value. Fallback to '$_defaultBlur.");
      return _defaultBlur;
    }

    return value.toDouble();
  }

  static double _parseDimmer(dynamic value, {required Logger logger}) {
    if (value is! num) {
      logger.w("Invalid text scale: $value. Fallback to '$_defaultDimmer.");
      return _defaultDimmer;
    }

    return value.toDouble();
  }

  static BoxFit _parseBoxFit(dynamic value, {required Logger logger}) {
    if (value is! String) {
      logger.w("Invalid boxFit type: $value. Fallback to '$_defaultBoxFit'.");
      return _defaultBoxFit;
    }

    try {
      return BoxFit.values.byName(value);
    } catch (e) {
      // Catches the error if the string doesn't match any BoxFit enum name
      logger.w("Unknown boxFit value: $value. Fallback to '$_defaultBoxFit'.");
      return _defaultBoxFit;
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
      'blur': blur,
      'dimmer': dimmer,
      'boxfit': boxFit.name,
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
