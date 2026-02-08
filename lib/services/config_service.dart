import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:nordplayer/models/app_config.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class ConfigService extends ChangeNotifier {
  ConfigService._instance();
  static final _singleton = ConfigService._instance();
  factory ConfigService() => _singleton;

  AppConfig _appConfig = AppConfig();
  AppConfig get appConfig {
    return _appConfig;
  }

  File? _configFile;

  Future<void> initConfig() async {
    final configDir = await getApplicationSupportDirectory();
    _configFile = File(p.join(configDir.path, 'config.json'));

    if (!_configFile!.existsSync()) {
      print('Config file not exist. Writing the default AppConfig()');
      if (_configFile == null) return;
      try {
        const encoder = JsonEncoder.withIndent('  ');
        await _configFile!.writeAsString(encoder.convert(_appConfig.toJson()));
      } catch (e) {
        print("SAVE ERROR: $e");
      }
    } else {
      try {
        final configString = await _configFile!.readAsString();
        final configMap = jsonDecode(configString);
        _appConfig = AppConfig.fromJson(configMap);
        notifyListeners();
      } catch (e) {
        print("CONFIG ERROR: $e");
      }
    }
  }

  // AppConfig got updated -> update config.json
  Future<void> updateJson() async {
    try {
      const encoder = JsonEncoder.withIndent('  ');
      _configFile!.writeAsString(encoder.convert(_appConfig.toJson()));
    } catch (e) {
      print("SAVE ERROR: $e");
    }
  }

  void update({List<String>? musicPath, String? theme}) {
    _appConfig = _appConfig.copyWith(musicPath: musicPath, theme: theme);
    notifyListeners();
    updateJson();
  }
}
