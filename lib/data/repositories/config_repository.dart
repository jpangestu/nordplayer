import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nordplayer/config/app_config.dart';
import 'package:nordplayer/data/services/storage/config_file_service.dart';
import 'package:nordplayer/utils/logger.dart';
import 'package:path/path.dart' as p;

/// Pre-loaded [AppConfig] at startup. Overridden in [ProviderScope] in `main.dart`.
final initialAppConfigProvider = Provider<AppConfig>((ref) {
  return AppConfig();
});

/// Configuration directory for Nordplayer. Overridden in [ProviderScope] in `main.dart`.
final configDirectoryProvider = Provider<Directory?>((ref) {
  return null;
});

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

  /// Resets configuration to default values and flushes to disk.
  Future<void> resetToDefaults();
}

/// Default implementation of [ConfigRepository] backed by [ConfigFileService].
class DefaultConfigRepository(
  final ConfigFileService _fileService,
  final File? _configFile, {
  required AppConfig initialConfig,
  final Duration debounceDuration = const Duration(milliseconds: 300),
}) with LoggerMixin implements ConfigRepository {
  final StreamController<AppConfig> _controller = StreamController<AppConfig>.broadcast();

  AppConfig _state = initialConfig;
  Timer? _debounceTimer;
  AppConfig? _pendingSaveConfig;

  /// Loads configuration from disk during startup before `runApp`.
  static Future<AppConfig> loadInitialConfig(
    Directory configDir, {
    ConfigFileService fileService = const ConfigFileService(),
    Logger? logger,
  }) async {
    final configFile = File(p.join(configDir.path, 'config.json'));
    logger?.d("Initializing Config. Directory: ${configDir.path}");

    if (!configFile.existsSync()) {
      logger?.i('Config file missing. Creating default configuration.');
      final defaultConfig = AppConfig();
      await _writeConfigAtomic(configFile, defaultConfig, fileService: fileService, logger: logger);
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
        await fileService.backupFile(configFile, configDir);
        await _writeConfigAtomic(configFile, loadedConfig, fileService: fileService, logger: logger);
      } else {
        logger?.i("Config loaded successfully.");
      }

      return loadedConfig;
    } catch (e, s) {
      logger?.e("Failed to load existing config. Resetting to defaults.", error: e, stackTrace: s);
      await fileService.backupFile(configFile, configDir);
      final backupConfig = AppConfig();
      await _writeConfigAtomic(configFile, backupConfig, fileService: fileService, logger: logger);
      return backupConfig;
    }
  }

  static Future<void> _writeConfigAtomic(
    File targetFile,
    AppConfig config, {
    required ConfigFileService fileService,
    Logger? logger,
  }) async {
    try {
      final jsonStr = const JsonEncoder.withIndent('  ').convert(config.toJson());
      await fileService.writeAtomic(targetFile, jsonStr);
      logger?.d("Config saved to disk (atomic).");
    } catch (e, s) {
      logger?.e("Failed atomic write to config file", error: e, stackTrace: s);
    }
  }

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
  }

  Future<void>? _activeWriteFuture;

  void _scheduleSave(AppConfig config) {
    _pendingSaveConfig = config;

    if (debounceDuration == Duration.zero) {
      _executeSave();
      return;
    }

    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounceDuration, _executeSave);
  }

  Future<void> _executeSave() async {
    if (_activeWriteFuture != null) return;

    while (_pendingSaveConfig != null && _configFile != null) {
      final toSave = _pendingSaveConfig!;
      _pendingSaveConfig = null;
      try {
        final jsonStr = const JsonEncoder.withIndent('  ').convert(toSave.toJson());
        final future = _fileService.writeAtomic(_configFile, jsonStr);
        _activeWriteFuture = future;
        await future;
        log.d("Config successfully saved to disk.");
      } catch (e, s) {
        log.e("Failed to write config.json to disk.", error: e, stackTrace: s);
      } finally {
        _activeWriteFuture = null;
      }
    }
  }

  @override
  Future<void> flush() async {
    _debounceTimer?.cancel();
    if (_activeWriteFuture != null) {
      await _activeWriteFuture;
    }
    if (_pendingSaveConfig != null) {
      await _executeSave();
    }
  }

  @override
  Future<void> resetToDefaults() async {
    final defaultConfig = AppConfig();
    updateConfig(defaultConfig);
    await flush();
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

  final repo = DefaultConfigRepository(fileService, configFile, initialConfig: initialConfig);

  ref.onDispose(repo.dispose);
  return repo;
});

/// Riverpod provider exposing reactive [AppConfig] with synchronous access and `.select()` support.
final configStateProvider = NotifierProvider<ConfigStateNotifier, AppConfig>(ConfigStateNotifier.new);

class ConfigStateNotifier extends Notifier<AppConfig> {
  @override
  AppConfig build() {
    final repo = ref.watch(configRepositoryProvider);
    final sub = repo.watchConfig().listen((config) {
      state = config;
    });
    ref.onDispose(sub.cancel);
    return repo.currentConfig;
  }
}

/// Backward-compatible alias for [configStateProvider].
final configServiceProvider = configStateProvider;
