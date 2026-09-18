import 'package:flutter/foundation.dart' show listEquals;
import 'package:material_ui/material_ui.dart';
import 'package:nordplayer/core/models/library_section_config.dart';
import 'package:nordplayer/core/theme/app_theme.dart';

class AppConfig {
  final List<String> trackDirectories;
  final bool watchTrackDirectories;
  final List<String> artistDelimiters;
  final List<String> artistExclusions;
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
  final List<LibrarySectionConfig> librarySections;

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
  static const List<String> defaultArtistExclusions = [
    'Bob Marley and the Wailers',
    'Bondan Prakoso & Fade2Black',
    'Brooks & Dunn',
    'Bruce Springsteen & The E Street Band',
    'Bruce Springsteen and the E Street Band',
    'Crosby, Stills, Nash & Young',
    'Earth, Wind & Fire',
    'Fitz & The Tantrums',
    'Florence + The Machine',
    'Florence and the Machine',
    'Hall & Oates',
    'Katrina & The Waves',
    'KC and the Sunshine Band',
    'Kool & The Gang',
    'Kool and the Gang',
    'Marina & The Diamonds',
    'Marina and the Diamonds',
    'Mumford & Sons',
    'Mumford and Sons',
    'Prince & The Revolution',
    'Simon & Garfunkel',
    'Simon and Garfunkel',
    'Sly & The Family Stone',
    'Sly and the Family Stone',
    'Tom Petty & The Heartbreakers',
    'Tom Petty and the Heartbreakers',
    'Tony Orlando and Dawn',
    'Tyler, The Creator',
  ];
  static const String _defaultTheme = 'nord';
  static const Brightness _defaultThemeBrightness = Brightness.dark;
  static const String _defaultIconSet = 'lucide';
  static const bool _defaultAdaptiveBg = false;
  static const BoxFit _defaultAdaptiveBgAlbumFit = BoxFit.cover;
  static const double _defaultAdaptiveBgAlbumBlur = 40;
  static const double _defaultAdaptiveBgPanelBlur = 10;
  static const double _defaultAdaptiveBgThemeOverlay = 0.4;
  static const String _defaultFontFamily = 'outfit';
  static const double _defaultTextScale = 1.0;
  static const bool _defaultWatchTrackDirectories = true;
  static const List<LibrarySectionConfig> _defaultLibrarySections = [
    LibrarySectionConfig(id: 'recently_added', isVisible: true),
    LibrarySectionConfig(id: 'albums', isVisible: true),
    LibrarySectionConfig(id: 'tracks', isVisible: true),
  ];

  AppConfig({
    this.trackDirectories = _defaultTrackDirectories,
    this.watchTrackDirectories = _defaultWatchTrackDirectories,
    this.artistDelimiters = defaultArtistDelimiters,
    this.artistExclusions = defaultArtistExclusions,
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
    this.librarySections = _defaultLibrarySections,
  });

  AppConfig copyWith({
    List<String>? trackDirectories,
    bool? watchTrackDirectories,
    List<String>? artistDelimiters,
    List<String>? artistExclusions,
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
    List<LibrarySectionConfig>? librarySections,
  }) {
    return AppConfig(
      trackDirectories: trackDirectories ?? this.trackDirectories,
      watchTrackDirectories: watchTrackDirectories ?? this.watchTrackDirectories,
      artistDelimiters: artistDelimiters ?? this.artistDelimiters,
      artistExclusions: artistExclusions ?? this.artistExclusions,
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
      librarySections: librarySections ?? this.librarySections,
    );
  }

  factory AppConfig.fromJson(
    Map<String, dynamic> json, {
    void Function(String message)? onWarning,
  }) {
    return AppConfig(
      trackDirectories: _parsetrackDirectories(json['trackDirectories'], onWarning: onWarning),
      watchTrackDirectories: _parseWatchTrackDirectories(json['watchTrackDirectories'], onWarning: onWarning),
      artistDelimiters: _parseArtistDelimiters(json['artistDelimiters'], onWarning: onWarning),
      artistExclusions: _parseArtistExclusions(json['artistExclusions'], onWarning: onWarning),
      theme: _parseTheme(json['theme'], onWarning: onWarning),
      themeBrightness: _parseThemeBrightness(json['themeBrightness'], onWarning: onWarning),
      iconSet: _parseIconSet(json['iconSet'], onWarning: onWarning),
      adaptiveBg: _parseAdaptiveBg(json['adaptiveBg'], onWarning: onWarning),
      adaptiveBgAlbumFit: _parseAlbumFit(json['albumFit'], onWarning: onWarning),
      adaptiveBgAlbumBlur: _parseAlbumBlur(json['albumBlur'], onWarning: onWarning),
      adaptiveBgPanelBlur: _parsePanelBlur(json['panelBlur'], onWarning: onWarning),
      adaptiveBgThemeOverlay: _parseThemeOverlay(json['themeOverlay'], onWarning: onWarning),
      fontFamily: _parseFontFamily(json['fontFamily'], onWarning: onWarning),
      textScale: _parseTextScale(json['textScale'], onWarning: onWarning),
      librarySections: _parseLibrarySections(json['librarySections'], onWarning: onWarning),
    );
  }

  static List<String> _parsetrackDirectories(dynamic value, {void Function(String)? onWarning}) {
    if (value is! List) {
      onWarning?.call("Invalid track directory: $value. Replaced with '$_defaultTrackDirectories'.");
      return _defaultTrackDirectories;
    }

    final safeList = value.whereType<String>().toList();
    return safeList;
  }

  static bool _parseWatchTrackDirectories(dynamic value, {void Function(String)? onWarning}) {
    if (value is! bool) {
      onWarning?.call("Invalid watchTrackDirectories: $value. Fallback to '$_defaultWatchTrackDirectories'.");
      return _defaultWatchTrackDirectories;
    }

    return value;
  }

  static List<String> _parseArtistDelimiters(dynamic value, {void Function(String)? onWarning}) {
    if (value is! List) {
      onWarning?.call("Invalid artist delimiters: $value. Fallback to default.");
      return defaultArtistDelimiters;
    }

    final safeList = value.whereType<String>().toList();

    return safeList;
  }

  static List<String> _parseArtistExclusions(dynamic value, {void Function(String)? onWarning}) {
    if (value is! List) {
      onWarning?.call("Invalid artist exclusions: $value. Fallback to default.");
      return defaultArtistExclusions;
    }

    final safeList = value.whereType<String>().toList();

    return safeList;
  }

  static String _parseTheme(dynamic value, {void Function(String)? onWarning}) {
    if (value is! String) {
      onWarning?.call("Invalid theme type: $value. Fallback to '$_defaultTheme'.");
      return _defaultTheme;
    }

    if (!AppTheme.labels.containsKey(value)) {
      onWarning?.call("Invalid theme config '$value'. Fallback to '$_defaultTheme'.");
      return _defaultTheme;
    }

    return value;
  }

  static Brightness _parseThemeBrightness(dynamic value, {void Function(String)? onWarning}) {
    if (value is! String) {
      onWarning?.call("Invalid brightness type: $value. Fallback to '$_defaultThemeBrightness'.");
      return _defaultThemeBrightness;
    }

    try {
      return Brightness.values.byName(value);
    } catch (e) {
      onWarning?.call("Unknown brightness value: $value. Fallback to '$_defaultThemeBrightness'.");
      return _defaultThemeBrightness;
    }
  }

  static String _parseIconSet(dynamic value, {void Function(String)? onWarning}) {
    if (value is! String || (value != 'lucide' && value != 'material')) {
      onWarning?.call("Invalid icon set: $value. Fallback to '$_defaultIconSet'.");
      return _defaultIconSet;
    }
    return value;
  }

  static bool _parseAdaptiveBg(dynamic value, {void Function(String)? onWarning}) {
    if (value is! bool) {
      onWarning?.call("Invalid adaptive background: $value. Fallback to '$_defaultAdaptiveBg'.");
      return _defaultAdaptiveBg;
    }

    return value;
  }

  static BoxFit _parseAlbumFit(dynamic value, {void Function(String)? onWarning}) {
    if (value is! String) {
      onWarning?.call("Invalid BoxFit type: $value. Fallback to '$_defaultAdaptiveBgAlbumFit'.");
      return _defaultAdaptiveBgAlbumFit;
    }

    try {
      return BoxFit.values.byName(value);
    } catch (e) {
      onWarning?.call("Unknown BoxFit value: $value. Fallback to '$_defaultAdaptiveBgAlbumFit'.");
      return _defaultAdaptiveBgAlbumFit;
    }
  }

  static double _parseAlbumBlur(dynamic value, {void Function(String)? onWarning}) {
    if (value is! num) {
      onWarning?.call("Invalid album blur: $value. Fallback to '$_defaultAdaptiveBgAlbumBlur'.");
      return _defaultAdaptiveBgAlbumBlur;
    }

    return value.toDouble();
  }

  static double _parsePanelBlur(dynamic value, {void Function(String)? onWarning}) {
    if (value is! num) {
      onWarning?.call("Invalid panel blur: $value. Fallback to '$_defaultAdaptiveBgPanelBlur'.");
      return _defaultAdaptiveBgPanelBlur;
    }

    return value.toDouble();
  }

  static double _parseThemeOverlay(dynamic value, {void Function(String)? onWarning}) {
    if (value is! num) {
      onWarning?.call("Invalid background themeOverlay: $value. Fallback to '$_defaultAdaptiveBgThemeOverlay'.");
      return _defaultAdaptiveBgThemeOverlay;
    }

    return value.toDouble();
  }

  static String _parseFontFamily(dynamic value, {void Function(String)? onWarning}) {
    if (value is! String) {
      onWarning?.call("Invalid font family: $value. Fallback to '$_defaultFontFamily'.");
      return _defaultFontFamily;
    }
    return value;
  }

  static double _parseTextScale(dynamic value, {void Function(String)? onWarning}) {
    if (value is! num) {
      onWarning?.call("Invalid text scale: $value. Fallback to '$_defaultTextScale'.");
      return _defaultTextScale;
    }

    return value.toDouble();
  }

  static List<LibrarySectionConfig> _parseLibrarySections(dynamic value, {void Function(String)? onWarning}) {
    if (value is! List) {
      onWarning?.call("Invalid librarySections: $value. Fallback to default.");
      return _defaultLibrarySections;
    }
    try {
      final list = <LibrarySectionConfig>[];
      for (final item in value) {
        if (item is Map<String, dynamic>) {
          list.add(LibrarySectionConfig.fromJson(item));
        } else {
          onWarning?.call("Invalid library section item in config: $item. Skipping.");
        }
      }
      final loadedIds = list.map((e) => e.id).toSet();
      for (final def in _defaultLibrarySections) {
        if (!loadedIds.contains(def.id)) {
          onWarning?.call("Missing section '${def.id}' in loaded configuration. Appending default.");
          list.add(def);
        }
      }
      return list;
    } catch (e) {
      onWarning?.call("Failed to parse librarySections: $e. Fallback to default.");
      return _defaultLibrarySections;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'trackDirectories': trackDirectories,
      'watchTrackDirectories': watchTrackDirectories,
      'artistDelimiters': artistDelimiters,
      'artistExclusions': artistExclusions,
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
      'librarySections': librarySections.map((e) => e.toJson()).toList(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppConfig &&
          runtimeType == other.runtimeType &&
          watchTrackDirectories == other.watchTrackDirectories &&
          theme == other.theme &&
          themeBrightness == other.themeBrightness &&
          iconSet == other.iconSet &&
          adaptiveBg == other.adaptiveBg &&
          adaptiveBgAlbumFit == other.adaptiveBgAlbumFit &&
          adaptiveBgAlbumBlur == other.adaptiveBgAlbumBlur &&
          adaptiveBgPanelBlur == other.adaptiveBgPanelBlur &&
          adaptiveBgThemeOverlay == other.adaptiveBgThemeOverlay &&
          fontFamily == other.fontFamily &&
          textScale == other.textScale &&
          listEquals(trackDirectories, other.trackDirectories) &&
          listEquals(artistDelimiters, other.artistDelimiters) &&
          listEquals(artistExclusions, other.artistExclusions) &&
          listEquals(librarySections, other.librarySections);

  @override
  int get hashCode => Object.hash(
        Object.hashAll(trackDirectories),
        watchTrackDirectories,
        Object.hashAll(artistDelimiters),
        Object.hashAll(artistExclusions),
        theme,
        themeBrightness,
        iconSet,
        adaptiveBg,
        adaptiveBgAlbumFit,
        adaptiveBgAlbumBlur,
        adaptiveBgPanelBlur,
        adaptiveBgThemeOverlay,
        fontFamily,
        textScale,
        Object.hashAll(librarySections),
      );

  @override
  String toString() {
    return 'AppConfig('
        'theme: $theme, '
        'brightness: $themeBrightness, '
        'iconSet: $iconSet, '
        'fontFamily: $fontFamily, '
        'adaptiveBg: $adaptiveBg)';
  }
}

/// Compatibility extension for accessing properties on [AppConfig] during
/// migration from [AsyncNotifier] to synchronous [Notifier].
extension AppConfigCompat on AppConfig {
  AppConfig get requireValue => this;
  AppConfig get value => this;
}

