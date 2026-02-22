import 'dart:io';
import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nordplayer/models/app_config.dart';
import 'package:nordplayer/services/logger.dart';

final configServiceProvider = AsyncNotifierProvider<ConfigService, AppConfig>(
  () {
    return ConfigService();
  },
);

class ConfigService extends AsyncNotifier<AppConfig> with LoggerMixin {
  File? _configFile;

  @override
  Future<AppConfig> build() async {
    final configDir = await getApplicationSupportDirectory();
    log.d("Initializing ConfigService. Directory: ${configDir.path}");

    _configFile = File(p.join(configDir.path, 'config.json'));

    if (!_configFile!.existsSync()) {
      log.i('Config file missing. Creating default configuration.');
      final defaultConfig = AppConfig();
      await _saveToDisk(defaultConfig);
      return defaultConfig;
    }

    try {
      final configString = await _configFile!.readAsString();
      final decodedJson = jsonDecode(configString);

      if (decodedJson is! Map<String, dynamic>) {
        throw const FormatException(
          "Config JSON is not a valid object structure",
        );
      }

      final loadedConfig = AppConfig.fromJson(decodedJson, logger: log);

      // Validate and clean JSON
      final cleanJson = loadedConfig.toJson();
      if (jsonEncode(decodedJson) != jsonEncode(cleanJson)) {
        log.w(
          "Config contained invalid values. Overwriting with corrected version.",
        );
        await _backupInvalidConfig();
        await _saveToDisk(loadedConfig);
      } else {
        log.i("Config loaded successfully.");
      }

      return loadedConfig;
    } catch (e, s) {
      log.e(
        "Failed to load existing config. Resetting to defaults.",
        error: e,
        stackTrace: s,
      );
      await _backupInvalidConfig();
      final backupConfig = AppConfig();
      await _saveToDisk(backupConfig);
      return backupConfig;
    }
  }

  void updateConfig({
    List<String>? musicPaths,
    String? theme,
    double? textScale,
    List<String>? artistDelimiters,
    bool save = true,
  }) {
    if (!state.hasValue) return;

    final currentConfig = state.requireValue;
    final newConfig = currentConfig.copyWith(
      musicPaths: musicPaths,
      theme: theme,
      textScale: textScale,
      artistDelimiters: artistDelimiters,
    );

    state = AsyncData(newConfig);

    if (save) {
      final changes = [
        if (musicPaths != null) 'musicPath',
        if (theme != null) 'theme',
        if (textScale != null) 'textScale',
        if (musicPaths != null) 'musicPath',
        if (artistDelimiters != null) 'artistDelimiters',
      ].join(', ');

      log.d("Updating Config -> $changes");
      _saveToDisk(newConfig);
    }
  }

  Future<void> resetToDefaults() async {
    log.w("User requested factory reset of settings.");

    final defaultConfig = AppConfig();

    state = AsyncData(defaultConfig);
    await _saveToDisk(defaultConfig);

    log.i("Settings reset to defaults.");
  }

  //
  // Helpers
  //

  Future<void> _saveToDisk(AppConfig configToSave, {String? reason}) async {
    if (_configFile == null) return;
    try {
      const encoder = JsonEncoder.withIndent('  ');
      await _configFile!.writeAsString(encoder.convert(configToSave.toJson()));
      log.d("Config saved to disk.");
    } catch (e, s) {
      log.e(
        "Failed to save config file ${reason != null ? '($reason)' : ''}",
        error: e,
        stackTrace: s,
      );
    }
  }

  Future<void> _backupInvalidConfig() async {
    if (_configFile == null || !_configFile!.existsSync()) return;
    try {
      final configDir = await getApplicationSupportDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final backupPath = p.join(
        configDir.path,
        'invalid_config.$timestamp.json',
      );

      await _configFile!.copy(backupPath);
      log.w("Invalid config backed up to: $backupPath");
    } catch (e, s) {
      log.e("Failed to backup corrupt config.", error: e, stackTrace: s);
    }
  }
}
