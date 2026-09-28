import 'dart:convert';
import 'dart:io';

import 'package:flutter/painting.dart' show BoxFit;
import 'package:flutter/services.dart' show Brightness;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nordplayer/config/app_config.dart';
import 'package:nordplayer/data/repositories/config_repository.dart';
import 'package:nordplayer/data/services/storage/config_file_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('nordplayer_config_repo_test_');
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      try {
        await tempDir.delete(recursive: true);
      } catch (_) {
        // Best-effort cleanup for Windows file locks
      }
    }
  });

  group('AppConfig model serialization', () {
    test('default configuration values', () {
      final config = AppConfig();

      expect(config.theme, 'nord');
      expect(config.themeBrightness, Brightness.dark);
      expect(config.iconSet, 'lucide');
      expect(config.adaptiveBg, isFalse);
      expect(config.fontFamily, 'outfit');
      expect(config.textScale, 1.0);
      expect(config.watchTrackDirectories, isTrue);
      expect(config.trackDirectories, isEmpty);
    });

    test('fromJson successfully parses valid json', () {
      final json = {
        'trackDirectories': ['/music/rock'],
        'watchTrackDirectories': false,
        'artistDelimiters': [';', '&'],
        'artistExclusions': ['The Beatles'],
        'theme': 'graphite',
        'themeBrightness': 'light',
        'iconSet': 'material',
        'adaptiveBg': true,
        'albumFit': 'contain',
        'albumBlur': 25.0,
        'panelBlur': 12.0,
        'themeOverlay': 0.6,
        'fontFamily': 'system',
        'textScale': 1.25,
        'librarySections': [
          {'id': 'tracks', 'isVisible': true},
        ],
      };

      final config = AppConfig.fromJson(json);

      expect(config.trackDirectories, ['/music/rock']);
      expect(config.watchTrackDirectories, isFalse);
      expect(config.artistDelimiters, [';', '&']);
      expect(config.artistExclusions, ['The Beatles']);
      expect(config.theme, 'graphite');
      expect(config.themeBrightness, Brightness.light);
      expect(config.iconSet, 'material');
      expect(config.adaptiveBg, isTrue);
      expect(config.adaptiveBgAlbumFit, BoxFit.contain);
      expect(config.adaptiveBgAlbumBlur, 25.0);
      expect(config.adaptiveBgPanelBlur, 12.0);
      expect(config.adaptiveBgThemeOverlay, 0.6);
      expect(config.fontFamily, 'system');
      expect(config.textScale, 1.25);
    });

    test('fromJson falls back safely on corrupted fields and triggers onWarning', () {
      final warnings = <String>[];
      final corruptedJson = {
        'theme': 'non_existent_theme',
        'themeBrightness': 'invalid_brightness',
        'iconSet': 12345,
        'albumBlur': 'forty',
        'trackDirectories': 42,
      };

      final config = AppConfig.fromJson(corruptedJson, onWarning: (msg) => warnings.add(msg));

      expect(config.theme, 'nord');
      expect(config.themeBrightness, Brightness.dark);
      expect(config.iconSet, 'lucide');
      expect(config.adaptiveBgAlbumBlur, 40.0);
      expect(config.trackDirectories, isEmpty);
      expect(warnings.length, greaterThanOrEqualTo(4));
    });
  });

  group('DefaultConfigRepository.loadInitialConfig', () {
    test('creates default file if config.json is missing', () async {
      final config = await DefaultConfigRepository.loadInitialConfig(tempDir);
      final configFile = File('${tempDir.path}/config.json');

      expect(configFile.existsSync(), isTrue);
      expect(config.theme, 'nord');

      final content = await configFile.readAsString();
      final decoded = jsonDecode(content) as Map<String, dynamic>;
      expect(decoded['theme'], 'nord');
    });

    test('heals and restores corrupted config JSON, creating backup', () async {
      final configFile = File('${tempDir.path}/config.json');
      await configFile.writeAsString('THIS IS NOT VALID JSON {{{{');

      final config = await DefaultConfigRepository.loadInitialConfig(tempDir);

      expect(config.theme, 'nord');
      expect(configFile.existsSync(), isTrue);

      final backups = tempDir.listSync().where((e) => e.path.contains('invalid_config.')).toList();
      expect(backups.isNotEmpty, isTrue);
    });

    test('repairs partially invalid config and preserves valid keys', () async {
      final configFile = File('${tempDir.path}/config.json');
      await configFile.writeAsString(jsonEncode({'theme': 'graphite', 'textScale': 'INVALID_FLOAT'}));

      final config = await DefaultConfigRepository.loadInitialConfig(tempDir);

      expect(config.theme, 'graphite');
      expect(config.textScale, 1.0);

      final backups = tempDir.listSync().where((e) => e.path.contains('invalid_config.')).toList();
      expect(backups.isNotEmpty, isTrue);
    });
  });

  group('DefaultConfigRepository repository operations', () {
    test('updates config and streams new values', () async {
      final configFile = File('${tempDir.path}/config.json');
      final repo = DefaultConfigRepository(
        const ConfigFileService(),
        configFile,
        initialConfig: AppConfig(theme: 'nord'),
        debounceDuration: Duration.zero,
      );
      addTearDown(repo.dispose);

      expect(repo.currentConfig.theme, 'nord');

      final emitted = <String>[];
      final sub = repo.watchConfig().listen((c) => emitted.add(c.theme));
      addTearDown(sub.cancel);

      repo.updateConfig(repo.currentConfig.copyWith(theme: 'graphite'));
      expect(repo.currentConfig.theme, 'graphite');

      // Allow microtask to deliver stream event
      await Future<void>.delayed(Duration.zero);
      expect(emitted, ['graphite']);

      // Ensure persistence is flushed to disk
      await repo.flush();
      expect(configFile.existsSync(), isTrue);
      final saved = jsonDecode(await configFile.readAsString());
      expect(saved['theme'], 'graphite');
    });

    test('debounces file persistence and flushes on demand', () async {
      final configFile = File('${tempDir.path}/config.json');
      final repo = DefaultConfigRepository(
        const ConfigFileService(),
        configFile,
        initialConfig: AppConfig(theme: 'nord'),
        debounceDuration: const Duration(seconds: 10),
      );
      addTearDown(repo.dispose);

      repo.updateConfig(repo.currentConfig.copyWith(theme: 'graphite'));

      // Not saved yet due to 10s debounce
      expect(configFile.existsSync(), isFalse);

      await repo.flush();

      // Saved after flush
      expect(configFile.existsSync(), isTrue);
      final saved = jsonDecode(await configFile.readAsString());
      expect(saved['theme'], 'graphite');
    });

    test('resetToDefaults resets state to factory defaults and persists', () async {
      final configFile = File('${tempDir.path}/config.json');
      final repo = DefaultConfigRepository(
        const ConfigFileService(),
        configFile,
        initialConfig: AppConfig(theme: 'graphite', adaptiveBg: true),
        debounceDuration: Duration.zero,
      );
      addTearDown(repo.dispose);

      expect(repo.currentConfig.theme, 'graphite');

      await repo.resetToDefaults();

      expect(repo.currentConfig.theme, 'nord');
      expect(repo.currentConfig.adaptiveBg, isFalse);

      final saved = jsonDecode(await configFile.readAsString());
      expect(saved['theme'], 'nord');
      expect(saved['adaptiveBg'], isFalse);
    });
  });

  group('configStateProvider & Riverpod integration', () {
    test('synchronous frame 0 state and reactivity', () async {
      final initialConfig = AppConfig(theme: 'nord');
      final container = ProviderContainer(
        overrides: [
          initialAppConfigProvider.overrideWithValue(initialConfig),
          configDirectoryProvider.overrideWithValue(tempDir),
        ],
      );
      addTearDown(container.dispose);

      // Frame-0 synchronous availability
      expect(container.read(configStateProvider).theme, 'nord');

      final repo = container.read(configRepositoryProvider);
      repo.updateConfig(initialConfig.copyWith(theme: 'graphite'));

      // StateNotifier responds to stream
      await Future<void>.delayed(Duration.zero);
      expect(container.read(configStateProvider).theme, 'graphite');
    });

    test('supports fine-grained .select reactivity', () async {
      final initialConfig = AppConfig(theme: 'nord', textScale: 1.0);
      final container = ProviderContainer(
        overrides: [
          initialAppConfigProvider.overrideWithValue(initialConfig),
          configDirectoryProvider.overrideWithValue(tempDir),
        ],
      );
      addTearDown(container.dispose);

      final themeChanges = <String>[];
      container.listen(configStateProvider.select((c) => c.theme), (previous, next) => themeChanges.add(next));

      final repo = container.read(configRepositoryProvider);

      // Change text scale only -> theme listener should NOT trigger
      repo.updateConfig(repo.currentConfig.copyWith(textScale: 1.5));
      await Future<void>.delayed(Duration.zero);
      expect(themeChanges, isEmpty);

      // Change theme -> theme listener triggers
      repo.updateConfig(repo.currentConfig.copyWith(theme: 'graphite'));
      await Future<void>.delayed(Duration.zero);
      expect(themeChanges, ['graphite']);
    });
  });
}
