import 'dart:convert';
import 'dart:io';

import 'package:flutter/painting.dart' show BoxFit;
import 'package:flutter/services.dart' show Brightness;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nordplayer/core/system/config_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('nordplayer_config_test_');
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('AppConfig pure model & fromJson tests', () {
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
        'iconSet': 12345, // invalid type
        'albumBlur': 'forty', // string instead of number
        'trackDirectories': 42, // integer instead of list
      };

      final config = AppConfig.fromJson(corruptedJson, onWarning: (msg) {
        warnings.add(msg);
      });

      expect(config.theme, 'nord'); // default
      expect(config.themeBrightness, Brightness.dark); // default
      expect(config.iconSet, 'lucide'); // default
      expect(config.adaptiveBgAlbumBlur, 40.0); // default
      expect(config.trackDirectories, isEmpty); // default
      expect(warnings.length, greaterThanOrEqualTo(4));
    });
  });

  group('ConfigService Disk I/O & Load Tests', () {
    test('loadInitialConfig creates default file if missing', () async {
      final config = await ConfigService.loadInitialConfig(tempDir);
      final configFile = File('${tempDir.path}/config.json');

      expect(configFile.existsSync(), isTrue);
      expect(config.theme, 'nord');

      final content = await configFile.readAsString();
      final decoded = jsonDecode(content) as Map<String, dynamic>;
      expect(decoded['theme'], 'nord');
    });

    test('loadInitialConfig heals and restores invalid JSON', () async {
      final configFile = File('${tempDir.path}/config.json');
      await configFile.writeAsString('THIS IS NOT VALID JSON {{{{');

      final config = await ConfigService.loadInitialConfig(tempDir);

      expect(config.theme, 'nord');
      expect(configFile.existsSync(), isTrue);

      // Verify a backup file was created
      final backups = tempDir
          .listSync()
          .where((e) => e.path.contains('invalid_config.'))
          .toList();
      expect(backups.isNotEmpty, isTrue);
    });
  });

  group('ConfigService Riverpod Notifier Tests', () {
    test('updates state synchronously and persists with atomic flush', () async {
      final configFile = File('${tempDir.path}/config.json');
      final initialConfig = AppConfig(theme: 'nord');

      final container = ProviderContainer(
        overrides: [
          initialAppConfigProvider.overrideWithValue(initialConfig),
          configDirectoryProvider.overrideWithValue(tempDir),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(configServiceProvider.notifier);

      // State is synchronous from frame 0
      expect(container.read(configServiceProvider).theme, 'nord');

      notifier.updateConfig(theme: 'graphite');
      expect(container.read(configServiceProvider).theme, 'graphite');

      // Flush to disk immediately
      await notifier.flush();

      expect(configFile.existsSync(), isTrue);
      final savedJson = jsonDecode(await configFile.readAsString());
      expect(savedJson['theme'], 'graphite');
    });

    test('resetToDefaults resets state to factory defaults and writes to disk', () async {
      final initialConfig = AppConfig(theme: 'graphite', adaptiveBg: true);

      final container = ProviderContainer(
        overrides: [
          initialAppConfigProvider.overrideWithValue(initialConfig),
          configDirectoryProvider.overrideWithValue(tempDir),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(configServiceProvider.notifier);
      expect(container.read(configServiceProvider).theme, 'graphite');

      await notifier.resetToDefaults();

      final state = container.read(configServiceProvider);
      expect(state.theme, 'nord');
      expect(state.adaptiveBg, isFalse);
    });
  });
}
