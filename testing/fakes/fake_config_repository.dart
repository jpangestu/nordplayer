import 'dart:async';

import 'package:nordplayer/config/app_config.dart';
import 'package:nordplayer/data/repositories/config_repository.dart';

/// In-memory test double for [ConfigRepository].
class FakeConfigRepository implements ConfigRepository {
  AppConfig _state;
  final StreamController<AppConfig> _controller =
      StreamController<AppConfig>.broadcast();

  final List<AppConfig> updatedConfigs = [];
  bool flushCalled = false;

  FakeConfigRepository({
    AppConfig? initialConfig,
  }) : _state = initialConfig ?? AppConfig();

  @override
  AppConfig get currentConfig => _state;

  @override
  Stream<AppConfig> watchConfig() {
    return Stream.value(_state).concatWith([_controller.stream]);
  }

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

extension on Stream<dynamic> {
  Stream<T> concatWith<T>(Iterable<Stream<T>> others) async* {
    if (this is Stream<T>) {
      yield* this as Stream<T>;
    }
    for (final other in others) {
      yield* other;
    }
  }
}
