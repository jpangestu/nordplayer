import 'package:nordplayer/config/app_config.dart';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nordplayer/data/services/system/config_service.dart';
import 'package:nordplayer/ui/settings/about/about_ui_state.dart';
import 'package:nordplayer/ui/settings/about/about_viewmodel.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AboutViewModel', () {
    late Directory tempDir;
    late ProviderContainer container;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('nordplayer_about_test_');

      container = ProviderContainer(
        overrides: [
          initialAppConfigProvider.overrideWithValue(
            AppConfig(
              adaptiveBg: true,
              adaptiveBgPanelBlur: 30.0,
              adaptiveBgThemeOverlay: 0.7,
            ),
          ),
          configDirectoryProvider.overrideWithValue(tempDir),
          packageInfoProvider.overrideWith(
            (ref) async => PackageInfo(
              appName: 'Nordplayer Test',
              packageName: 'com.example.nordplayer',
              version: '1.2.3',
              buildNumber: '42',
            ),
          ),
        ],
      );
    });

    tearDown(() async {
      container.dispose();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('initial state loads package info and reflects adaptive config', () async {
      // Allow async packageInfoProvider to resolve
      await container.read(packageInfoProvider.future);

      final state = container.read(aboutViewModelProvider);

      expect(state.isLoading, isFalse);
      expect(state.packageInfo, isNotNull);
      expect(state.appName, equals('Nordplayer Test'));
      expect(state.version, equals('v1.2.3'));
      expect(state.adaptiveBg, isTrue);
      expect(state.adaptiveBgPanelBlur, equals(30.0));
      expect(state.adaptiveBgThemeOverlay, equals(0.7));
    });

    test('AboutUiState supports equality and copyWith', () {
      const state1 = AboutUiState(
        adaptiveBg: true,
        adaptiveBgPanelBlur: 20.0,
        adaptiveBgThemeOverlay: 0.5,
      );

      final state2 = state1.copyWith();
      expect(state1, equals(state2));
      expect(state1.hashCode, equals(state2.hashCode));

      final state3 = state1.copyWith(adaptiveBg: false);
      expect(state1, isNot(equals(state3)));
    });
  });
}
