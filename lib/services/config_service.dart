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

  Future<void> init() async {
    final configDir = await getApplicationSupportDirectory();
    log.d("Initializing ConfigService. Directory: ${configDir.path}"); 
    
    _configFile = File(p.join(configDir.path, 'config.json'));

    if (!_configFile!.existsSync()) {
      log.i('Config file missing. creating default configuration.');
      
      try {
        const encoder = JsonEncoder.withIndent('  ');
        await _configFile!.writeAsString(encoder.convert(_appConfig.toJson()));
        log.d("Default config successfully written to disk.");
      } catch (e, s) {
        log.e("Failed to create default config file", error: e, stackTrace: s);
      }
    } else {
      try {
        final configString = await _configFile!.readAsString();
        final configMap = jsonDecode(configString);
        _appConfig = AppConfig.fromJson(configMap);
        log.i("Config loaded successfully: $_appConfig");
        
        notifyListeners();
      } catch (e, s) {
        log.e("Failed to load existing config. App may be unstable.", error: e, stackTrace: s);
      }
    }
  }

  Future<void> updateJson() async {
    if (_configFile == null) {
      log.w("Attempted to save config before initialization.");
      return;
    }

    try {
      const encoder = JsonEncoder.withIndent('  ');
      await _configFile!.writeAsString(encoder.convert(_appConfig.toJson()));
      log.d("Config saved to disk.");
    } catch (e, s) {
      log.e("Failed to save config to disk", error: e, stackTrace: s);
    }
  }

  void update({List<String>? musicPath, String? theme}) {
    log.d("Updating Config -> Theme: $theme, MusicPaths: ${musicPath?.length ?? 'unchanged'}");

    _appConfig = _appConfig.copyWith(musicPath: musicPath, theme: theme);
    notifyListeners();
    updateJson(); 
  }
}