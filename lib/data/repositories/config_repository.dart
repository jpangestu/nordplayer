import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nordplayer/config/app_config.dart';
import 'package:nordplayer/data/services/storage/config_file_service.dart';
import 'package:nordplayer/data/services/system/config_service.dart';
import 'package:nordplayer/utils/logger.dart';
import 'package:path/path.dart' as p;

/// Repository interface abstracting application configuration persistence and updates.
abstract interface class ConfigRepository {
  /// Currently active in-memory configuration snapshot.
  AppConfig get currentConfig;

  /// Reactive stream of configuration changes.
  Stream<AppConfig> watchConfig();

  /// Updates configuration in memory and schedules debounced persistence to disk.
  void updateConfig(AppConfig newConfig);

  /// Forces an immediate flush of pending configuration changes to disk.
  Future<void> flush();
}

/// Default implementation of [ConfigRepository] backed by [ConfigFileService].
class DefaultConfigRepository(
  final ConfigFileService _fileService,
  final File? _configFile, {
  required AppConfig initialConfig,
  final void Function(AppConfig)? onConfigUpdated,
}) with LoggerMixin implements ConfigRepository {
  final StreamController<AppConfig> _controller = StreamController<AppConfig>.broadcast();

  AppConfig _state = initialConfig;
  Timer? _debounceTimer;
  AppConfig? _pendingSaveConfig;

  @override
  AppConfig get currentConfig => _state;

  @override
  Stream<AppConfig> watchConfig() => _controller.stream;

  @override
  void updateConfig(AppConfig newConfig) {
    if (_state == newConfig) return;

    _state = newConfig;
    _controller.add(_state);

    _scheduleSave(newConfig);
    onConfigUpdated?.call(newConfig);
  }

  void _scheduleSave(AppConfig config) {
    _pendingSaveConfig = config;

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      final toSave = _pendingSaveConfig;
      if (toSave != null && _configFile != null) {
        _pendingSaveConfig = null;
        try {
          final jsonStr = const JsonEncoder.withIndent('  ').convert(toSave.toJson());
          await _fileService.writeAtomic(_configFile, jsonStr);
          log.d("Config successfully saved to disk.");
        } catch (e, s) {
          log.e("Failed to write config.json to disk.", error: e, stackTrace: s);
        }
      }
    });
  }

  @override
  Future<void> flush() async {
    _debounceTimer?.cancel();
    final toSave = _pendingSaveConfig;
    if (toSave != null && _configFile != null) {
      _pendingSaveConfig = null;
      try {
        final jsonStr = const JsonEncoder.withIndent('  ').convert(toSave.toJson());
        await _fileService.writeAtomic(_configFile, jsonStr);
      } catch (e, s) {
        log.e("Failed to flush config.json", error: e, stackTrace: s);
      }
    }
  }

  void dispose() {
    _debounceTimer?.cancel();
    if (_pendingSaveConfig != null && _configFile != null) {
      try {
        final jsonStr = const JsonEncoder.withIndent('  ').convert(_pendingSaveConfig!.toJson());
        _fileService.writeAtomicSync(_configFile, jsonStr);
      } catch (e, s) {
        log.e("Failed to write config on dispose", error: e, stackTrace: s);
      }
    }
    _controller.close();
  }
}

/// Riverpod provider for [ConfigRepository].
final configRepositoryProvider = Provider<ConfigRepository>((ref) {
  final fileService = ref.watch(configFileServiceProvider);
  final configDir = ref.watch(configDirectoryProvider);
  final initialConfig = ref.watch(initialAppConfigProvider);

  final configFile = configDir != null ? File(p.join(configDir.path, 'config.json')) : null;

  final repo = DefaultConfigRepository(
    fileService,
    configFile,
    initialConfig: initialConfig,
    onConfigUpdated: (newConfig) {
      ref.read(configServiceProvider.notifier).setConfig(newConfig);
    },
  );

  ref.listen(configServiceProvider, (_, next) {
    repo.updateConfig(next);
  });

  ref.onDispose(repo.dispose);
  return repo;
});
