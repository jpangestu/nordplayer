import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/painting.dart' show BoxFit;
import 'package:flutter/services.dart' show Brightness;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nordplayer/config/app_config.dart';
import 'package:nordplayer/utils/logger.dart';
import 'package:path/path.dart' as p;

export 'package:nordplayer/config/app_config.dart';

/// Pre-loaded [AppConfig] at startup. Overridden in [ProviderScope] in `main.dart`.
final initialAppConfigProvider = Provider<AppConfig>((ref) {
  return AppConfig();
});

/// Configuration directory for Nordplayer. Overridden in [ProviderScope] in `main.dart`.
final configDirectoryProvider = Provider<Directory?>((ref) {
  return null;
});

/// Riverpod provider for application configuration service.
final configServiceProvider = NotifierProvider<ConfigService, AppConfig>(() {
  return ConfigService();
});

class ConfigService extends Notifier<AppConfig> with LoggerMixin {
  ConfigService([this._configFile]);

  File? _configFile;
  Timer? _debounceTimer;
  AppConfig? _pendingSaveConfig;

  @override
  AppConfig build() {
    final configDir = ref.watch(configDirectoryProvider);
    if (configDir != null && _configFile == null) {
      _configFile = File(p.join(configDir.path, 'config.json'));
    }

    ref.onDispose(() {
      _debounceTimer?.cancel();
      if (_pendingSaveConfig != null && _configFile != null) {
        _writeConfigSync(_configFile!, _pendingSaveConfig!);
      }
    });

    return ref.watch(initialAppConfigProvider);
  }

  /// Loads configuration from disk during application startup before [runApp].
  static Future<AppConfig> loadInitialConfig(Directory configDir, {Logger? logger}) async {
    final configFile = File(p.join(configDir.path, 'config.json'));
    logger?.d("Initializing ConfigService. Directory: ${configDir.path}");

    if (!configFile.existsSync()) {
      logger?.i('Config file missing. Creating default configuration.');
      final defaultConfig = AppConfig();
      await _atomicWrite(configFile, defaultConfig, logger: logger);
      return defaultConfig;
    }

    try {
      final configString = await configFile.readAsString();
      final decodedJson = jsonDecode(configString);

      if (decodedJson is! Map<String, dynamic>) {
        throw const FormatException("Config JSON is not a valid object structure");
      }

      final warnings = <String>[];
      final loadedConfig = AppConfig.fromJson(
        decodedJson,
        onWarning: (msg) {
          warnings.add(msg);
          logger?.w(msg);
        },
      );

      // Validate and clean JSON
      if (warnings.isNotEmpty) {
        logger?.w("Config contained ${warnings.length} invalid or missing values. Overwriting with corrected version.");
        await _backupInvalidConfig(configFile, configDir, logger: logger);
        await _atomicWrite(configFile, loadedConfig, logger: logger);
      } else {
        logger?.i("Config loaded successfully.");
      }

      return loadedConfig;
    } catch (e, s) {
      logger?.e("Failed to load existing config. Resetting to defaults.", error: e, stackTrace: s);
      await _backupInvalidConfig(configFile, configDir, logger: logger);
      final backupConfig = AppConfig();
      await _atomicWrite(configFile, backupConfig, logger: logger);
      return backupConfig;
    }
  }

  void updateConfig({
    List<String>? trackDirectories,
    bool? watchTrackDirectories,
    List<String>? artistDelimiters,
    List<String>? artistExclusions,
    String? theme,
    Brightness? themeBrightness,
    bool? adaptiveBg,
    BoxFit? albumFit,
    double? albumBlur,
    double? panelBlur,
    double? tinter,
    String? fontFamily,
    double? textScale,
    String? iconSet,
    List<LibrarySectionConfig>? librarySections,
    bool save = true,
  }) {
    final currentConfig = state;

    final newConfig = currentConfig.copyWith(
      trackDirectories: trackDirectories,
      watchTrackDirectories: watchTrackDirectories,
      artistDelimiters: artistDelimiters,
      artistExclusions: artistExclusions,
      theme: theme,
      themeBrightness: themeBrightness,
      adaptiveBg: adaptiveBg,
      adaptiveBgAlbumFit: albumFit,
      adaptiveBgAlbumBlur: albumBlur,
      adaptiveBgPanelBlur: panelBlur,
      adaptiveBgThemeOverlay: tinter,
      fontFamily: fontFamily,
      textScale: textScale,
      iconSet: iconSet,
      librarySections: librarySections,
    );

    if (newConfig == currentConfig) return;

    state = newConfig;

    if (save) {
      final changes = [
        if (trackDirectories != null) 'trackDirectories',
        if (watchTrackDirectories != null) 'watchTrackDirectories',
        if (artistDelimiters != null) 'artistDelimiters',
        if (artistExclusions != null) 'artistExclusions',
        if (theme != null) 'theme',
        if (themeBrightness != null) 'themeBrightness',
        if (adaptiveBg != null) 'adaptiveBg',
        if (albumBlur != null) 'blur',
        if (tinter != null) 'dimmer',
        if (albumFit != null) 'boxFit',
        if (fontFamily != null) 'fontFamily',
        if (textScale != null) 'textScale',
        if (iconSet != null) 'iconSet',
        if (librarySections != null) 'librarySections',
      ].join(', ');

      log.d("Updating Config -> $changes");
      _scheduleSave(newConfig);
    }
  }

  void setConfig(AppConfig newConfig) {
    if (state == newConfig) return;
    state = newConfig;
    _scheduleSave(newConfig);
  }

  /// Flushes any debounced pending changes to disk immediately.
  Future<void> flush() async {
    _debounceTimer?.cancel();
    if (_pendingSaveConfig != null && _configFile != null) {
      final toSave = _pendingSaveConfig!;
      _pendingSaveConfig = null;
      await _atomicWrite(_configFile!, toSave, logger: log);
    }
  }

  Future<void> resetToDefaults() async {
    log.w("User requested factory reset of settings.");
    _debounceTimer?.cancel();
    _pendingSaveConfig = null;

    final defaultConfig = AppConfig();
    state = defaultConfig;

    if (_configFile != null) {
      await _atomicWrite(_configFile!, defaultConfig, logger: log);
    }

    log.i("Settings reset to defaults.");
  }

  void _scheduleSave(AppConfig config) {
    _pendingSaveConfig = config;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      if (_pendingSaveConfig != null && _configFile != null) {
        final toSave = _pendingSaveConfig!;
        _pendingSaveConfig = null;
        await _atomicWrite(_configFile!, toSave, logger: log);
      }
    });
  }

  static Future<void> _atomicWrite(File targetFile, AppConfig config, {Logger? logger}) async {
    final tempFile = File('${targetFile.path}.tmp');
    try {
      const encoder = JsonEncoder.withIndent('  ');
      final jsonContent = encoder.convert(config.toJson());
      await tempFile.writeAsString(jsonContent, flush: true);

      try {
        await tempFile.rename(targetFile.path);
      } on FileSystemException {
        // Fallback to non-destructive copy & delete if target is locked on Windows
        await tempFile.copy(targetFile.path);
        await tempFile.delete();
      }
      logger?.d("Config saved to disk (atomic).");
    } catch (e, s) {
      logger?.e("Failed atomic write to config file", error: e, stackTrace: s);
      try {
        const encoder = JsonEncoder.withIndent('  ');
        await targetFile.writeAsString(encoder.convert(config.toJson()), flush: true);
        if (tempFile.existsSync()) {
          await tempFile.delete();
        }
      } catch (fallbackError) {
        logger?.e("Fallback direct write also failed", error: fallbackError);
      }
    }
  }

  static void _writeConfigSync(File targetFile, AppConfig config) {
    try {
      const encoder = JsonEncoder.withIndent('  ');
      final jsonContent = encoder.convert(config.toJson());
      final tempFile = File('${targetFile.path}.tmp');
      tempFile.writeAsStringSync(jsonContent, flush: true);
      try {
        tempFile.renameSync(targetFile.path);
      } on FileSystemException {
        tempFile.copySync(targetFile.path);
        tempFile.deleteSync();
      }
    } catch (_) {
      // Best effort during disposal
    }
  }

  static Future<void> _backupInvalidConfig(File configFile, Directory configDir, {Logger? logger}) async {
    if (!configFile.existsSync()) return;
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final backupPath = p.join(configDir.path, 'invalid_config.$timestamp.json');

      await configFile.copy(backupPath);
      logger?.w("Invalid config backed up to: $backupPath");
    } catch (e, s) {
      logger?.e("Failed to backup corrupt config.", error: e, stackTrace: s);
    }
  }
}
