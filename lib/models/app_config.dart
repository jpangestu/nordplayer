import 'package:logger/logger.dart';
import 'package:nordplayer/models/app_theme.dart';

class AppConfig {
  final List<String> musicPath;
  final String theme;

  static const List<String> _defaultMusicPath = [];
  static const String _defaultTheme = 'nord';

  AppConfig({this.musicPath = _defaultMusicPath, this.theme = _defaultTheme});

  AppConfig copyWith({List<String>? musicPath, String? theme}) {
    return AppConfig(
      musicPath: musicPath ?? this.musicPath,
      theme: theme ?? this.theme,
    );
  }

  factory AppConfig.fromJson(Map<String, dynamic> json, {required Logger logger}) {
    return AppConfig(
      musicPath: _parseMusicPath(json['musicPath'], logger: logger),
      theme: _parseTheme(json['theme'], logger: logger),
    );
  }

  static List<String> _parseMusicPath(dynamic value, {required Logger logger}) {
    if (value is! List) {
      logger.w("Invalid music path(s): $value. Replaced with '$_defaultMusicPath'.");
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

  Map<String, dynamic> toJson() {
    return {'musicPath': musicPath, 'theme': theme};
  }
}
