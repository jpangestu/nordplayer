class AppConfig {
  final List<String> musicPath;
  final String theme;

  AppConfig({this.musicPath = const [], this.theme = 'nord'});

  AppConfig copyWith({List<String>? musicPath, String? theme}) {
    return AppConfig(
      musicPath: musicPath ?? this.musicPath,
      theme: theme ?? this.theme,
    );
  }

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    return AppConfig(
      musicPath: List<String>.from(json['musicPath'] ?? []),
      theme: json['theme'] as String? ?? 'nord',
    );
  }

  Map<String, dynamic> toJson() {
    return {'musicPath': musicPath, 'theme': theme};
  }
}
