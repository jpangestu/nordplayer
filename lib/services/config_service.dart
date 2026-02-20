import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:nordplayer/models/app_config.dart';
import 'package:nordplayer/services/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class ConfigService extends ChangeNotifier with LoggerMixin {
  ConfigService._instance();
  static final _singleton = ConfigService._instance();
  factory ConfigService() => _singleton;

  AppConfig _appConfig = AppConfig();
  AppConfig get appConfig => _appConfig;

  File? _configFile;

  /// Initializes the config file.
  /// Must be called before accessing any properties.
  Future<void> init() async {
    final configDir = await getApplicationSupportDirectory();
    log.d("Initializing ConfigService. Directory: ${configDir.path}");

    _configFile = File(p.join(configDir.path, 'config.json'));

    if (!_configFile!.existsSync()) {
      log.i('Config file missing. Creating default configuration.');
      _saveToDisk();
    } else {
      try {
        final configString = await _configFile!.readAsString();
        final decodedJson = jsonDecode(configString);

        if (decodedJson is! Map<String, dynamic>) {
          throw const FormatException(
            "Config JSON is not a valid object structure",
          );
        }

        _appConfig = AppConfig.fromJson(decodedJson, logger: log);

        final cleanJson = _appConfig.toJson();
        if (jsonEncode(decodedJson) != jsonEncode(cleanJson)) {
          log.w(
            "Config contained invalid values. Overwriting with corrected version.",
          );
          await _backupInvalidConfig();
          await _saveToDisk();
        } else {
          log.i("Config loaded successfully.");
        }

        notifyListeners();
      } catch (e, s) {
        log.e(
          "Failed to load existing config. Resetting to defaults.",
          error: e,
          stackTrace: s,
        );
        await _backupInvalidConfig();
        _appConfig = AppConfig();
        await _saveToDisk();
      }
    }
  }

  void update({
    List<String>? musicPaths,
    String? theme,
    double? textScale,
    List<String>? artistDelimiters,
    bool save = true,
  }) {
    _appConfig = _appConfig.copyWith(
      musicPaths: musicPaths,
      theme: theme,
      textScale: textScale,
      artistDelimiters: artistDelimiters,
    );
    notifyListeners();

    if (save) {
      final changes = [
        if (musicPaths != null) 'musicPath',
        if (theme != null) 'theme',
        if (textScale != null) 'textScale',
        if (musicPaths != null) 'musicPath',
        if (artistDelimiters != null) 'artistDelimiters',
      ].join(', ');

      log.d("Updating Config -> $changes");
      _saveToDisk(reason: "updating $changes");
    }
  }

  Future<void> resetToDefaults() async {
    log.w("User requested factory reset of settings.");

    _appConfig = AppConfig();
    notifyListeners();
    await _saveToDisk();
    log.i("Settings reset to defaults.");
  }

  //
  // HELPER
  //

  Future<void> _saveToDisk({String? reason}) async {
    if (_configFile == null) return;
    try {
      const encoder = JsonEncoder.withIndent('  ');
      await _configFile!.writeAsString(encoder.convert(_appConfig.toJson()));
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
