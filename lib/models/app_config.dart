import 'package:logger/logger.dart';
import 'package:nordplayer/models/app_theme.dart';

class AppConfig {
  final List<String> musicPaths;
  final String theme;
  final double textScale;

  static const List<String> _defaultMusicPath = [];
  static const String _defaultTheme = 'nord';
  static const double _defaultTextScale = 1.0;

  AppConfig({
    this.musicPaths = _defaultMusicPath,
    this.theme = _defaultTheme,
    this.textScale = _defaultTextScale,
  });

  AppConfig copyWith({
    List<String>? musicPaths,
    String? theme,
    double? textScale,
  }) {
    return AppConfig(
      musicPaths: musicPaths ?? this.musicPaths,
      theme: theme ?? this.theme,
      textScale: textScale ?? this.textScale,
    );
  }

  factory AppConfig.fromJson(
    Map<String, dynamic> json, {
    required Logger logger,
  }) {
    return AppConfig(
      musicPaths: _parseMusicPath(json['musicPath'], logger: logger),
      theme: _parseTheme(json['theme'], logger: logger),
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

  static double _parseTextScale(dynamic value, {required Logger logger}) {
    if (value is! double) {
      logger.w("Invalid text scale: $value. Fallback to '$_defaultTheme.");
      return _defaultTextScale;
    }

    return value;
  }

  Map<String, dynamic> toJson() {
    return {'musicPath': musicPaths, 'theme': theme, 'textScale': textScale};
  }
}
