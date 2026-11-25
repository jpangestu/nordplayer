import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart' show BoxFit, ThemeMode;
import 'package:nordplayer/core/window/native_window.dart';
import 'package:typed_config/typed_config.dart';

const currentSchemaVersion = 1;

final class AppConfig(super.builder) extends TypedConfig {
  final themeMode = builder.defineEnum('themeMode', ThemeMode.system, values: ThemeMode.values);
  final ConfigEntry<String> colorTheme = builder.define('colorTheme', 'nord');

  final windowBackdrop = builder.group('windowBackground', WindowBackdropConfig.new);
  final surface = builder.group('surface', SurfaceConfig.new);
  final performance = builder.group('performance', PerformanceMetricsConfig.new);
  final ui = builder.group('ui', UiConfig.new);
}

final class UiConfig(super.builder) extends TypedConfig {
  final playerBar = builder.group('player_bar', PlayerBarConfig.new);
  final sidebar = builder.group('sidebar', SidebarConfig.new);
}

final class PlayerBarConfig(super.builder) extends TypedConfig {
  final height = builder.define('heght', 90.0);
}

final class SidebarConfig(super.builder) extends TypedConfig {
  final width = builder.define('width', 300.0);
}

enum WindowBackdropType { solid, platformStyle, albumArt, customImage }

final class WindowBackdropConfig(super.builder) extends TypedConfig {
  final type = builder.defineEnum(
    'type',
    WindowBackdropType.solid,
    values: WindowBackdropType.values,
  );
  final themeOverlayOpacity = builder.define('themeOverlayOpacity', 0.4);
  final platformStyle = builder.group('platformStyle', PlatformStyleConfig.new);
  final albumArt = builder.group('albumArt', AlbumArtConfig.new);
  final customImage = builder.group('customImage', CustomImageConfig.new);
}

final class PlatformStyleConfig(super.builder) extends TypedConfig {
  final windows = builder.defineEnum(
    'windows',
    WindowsWindowStyle.acrylic,
    values: WindowsWindowStyle.values,
  );
}

final class AlbumArtConfig(super.builder) extends TypedConfig {
  final fit = builder.defineEnum('fit', BoxFit.cover, values: BoxFit.values);
  final blurRadius = builder.define('blurRadius', 20.0);
}

final class CustomImageConfig(super.builder) extends TypedConfig {
  final fit = builder.defineEnum('fit', BoxFit.cover, values: BoxFit.values);
  final blurRadius = builder.define('blurRadius', 20.0);
}

final class SurfaceConfig(super.builder) extends TypedConfig {
  final blurRadius = builder.define('blurRadius', 20.0);
  final opacityLow = builder.define('opacityLow', 0.5);
  final opacityMid = builder.define('opacityMid', 0.7);
  final opacityHigh = builder.define('opacityHigh', 0.9);
}

final class PerformanceMetricsConfig(super.builder) extends TypedConfig {
  final metricsVisibility = builder.defineMap('metricsVisibility', const <String, bool>{
    'frameRate': false,
    'frameTime': false,
    'uiTime': false,
    'rasterTime': false,
    'fps': false,
    'averageFrameTime': false,
    'minFrameTime': false,
    'maxFrameTime': false,
    'cpuUsage': false,
    'gpuUsage': false,
    'gpuVram': false,
    'gpuShared': false,
    'ramPrivate': false,
    'ramRss': false,
    'ramCommitted': false,
    'ramTotal': false,
  });
}

// ================================================================================================
// Riverpod Stuff
// ================================================================================================
final _entryProviderCache = Expando<Object>();

/// Extension to add a reactive [provider] getter to [ConfigEntry].
extension ConfigEntryRiverpodX<T> on ConfigEntry<T> {
  Provider<T> get provider {
    final cached = _entryProviderCache[this];
    if (cached != null) return cached as Provider<T>;

    final created = Provider<T>((ref) {
      final sub = changes.listen((_) => ref.invalidateSelf());
      ref.onDispose(sub.cancel);
      return value;
    });
    _entryProviderCache[this] = created;
    return created;
  }
}

final appConfigProvider = Provider<AppConfig>((ref) {
  throw UnimplementedError('appConfigProvider must be initialized in main.dart');
});
