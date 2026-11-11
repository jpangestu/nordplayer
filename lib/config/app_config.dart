import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart' show BoxFit, ThemeMode;
import 'package:nordplayer/core/window/native_window.dart';
import 'package:typed_config/typed_config.dart';

const currentSchemaVersion = 1;

final class AppConfig(super.builder) extends TypedConfig {
  final themeMode = builder.defineEnum('themeMode', ThemeMode.system, values: ThemeMode.values);
  final ConfigEntry<String> colorTheme = builder.define('colorTheme', 'nord');
  final themeOverlayOpacity = builder.define('themeOverlayOpacity', 0.40);
  final panelBlurLevel = builder.define('panelBlurLevel', 20.0);

  final windowBg = builder.group('windowBackground', WindowBackgroundConfig.new);
}

enum WindowBgType { solid, platformStyle, albumArt, customImage }

final class WindowBackgroundConfig(super.builder) extends TypedConfig {
  final type = builder.defineEnum('type', WindowBgType.solid, values: WindowBgType.values);
  final platformStyle = builder.group('platformStyle', PlatformStyleConfig.new);
  final albumArt = builder.group('albumArt', AlbumArtConfig.new);
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
  final blurSigma = builder.define('blur', 20.0);
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
