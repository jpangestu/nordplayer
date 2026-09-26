import 'dart:async';

import 'package:nordplayer/config/app_config.dart';
import 'package:nordplayer/data/repositories/config_repository.dart';

/// In-memory test double for [ConfigRepository].
class FakeConfigRepository([AppConfig? initialConfig]) implements ConfigRepository {
  AppConfig _state = initialConfig ?? AppConfig();
  final StreamController<AppConfig> _controller = StreamController<AppConfig>.broadcast();

  final List<AppConfig> updatedConfigs = [];
  bool flushCalled = false;

  @override
  AppConfig get currentConfig => _state;

  @override
  Stream<AppConfig> watchConfig() => _controller.stream;

  @override
  void updateConfig(AppConfig newConfig) {
    _state = newConfig;
    updatedConfigs.add(newConfig);
    _controller.add(_state);
  }

  @override
  Future<void> flush() async {
    flushCalled = true;
  }

  void dispose() {
    _controller.close();
  }
}
