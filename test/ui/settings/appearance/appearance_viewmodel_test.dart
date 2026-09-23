import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nordplayer/data/services/system/config_service.dart';
import 'package:nordplayer/data/repositories/config_repository.dart';
import 'package:nordplayer/ui/settings/appearance/appearance_viewmodel.dart';

class FakeConfigRepository implements ConfigRepository {
  final StreamController<AppConfig> _configController = StreamController<AppConfig>.broadcast();
  AppConfig _config;

  FakeConfigRepository([AppConfig? initialConfig]) : _config = initialConfig ?? AppConfig();

  @override
  AppConfig get currentConfig => _config;

  @override
  Stream<AppConfig> watchConfig() => _configController.stream;

  @override
  void updateConfig(AppConfig newConfig) {
    _config = newConfig;
    _configController.add(newConfig);
  }

  @override
  Future<void> flush() async {}

  void dispose() {
    _configController.close();
  }
}

void main() {
  group('AppearanceViewModel', () {
    late FakeConfigRepository fakeConfigRepo;
    late ProviderContainer container;

    setUp(() {
      fakeConfigRepo = FakeConfigRepository(
        AppConfig(
          theme: 'nord',
          themeBrightness: Brightness.dark,
          iconSet: 'lucide',
          adaptiveBg: false,
          adaptiveBgAlbumFit: BoxFit.cover,
          adaptiveBgAlbumBlur: 20.0,
          adaptiveBgPanelBlur: 20.0,
          adaptiveBgThemeOverlay: 0.5,
          fontFamily: 'inter',
          textScale: 1.0,
        ),
      );

      container = ProviderContainer(
        overrides: [
          configRepositoryProvider.overrideWithValue(fakeConfigRepo),
        ],
      );
    });

    tearDown(() {
      container.dispose();
      fakeConfigRepo.dispose();
    });

    test('builds initial state correctly from ConfigRepository', () {
      final state = container.read(appearanceViewModelProvider);
      expect(state.theme, equals('nord'));
      expect(state.themeBrightness, equals(Brightness.dark));
      expect(state.iconSet, equals('lucide'));
      expect(state.adaptiveBg, isFalse);
      expect(state.adaptiveBgAlbumFit, equals(BoxFit.cover));
      expect(state.adaptiveBgAlbumBlur, equals(20.0));
      expect(state.adaptiveBgPanelBlur, equals(20.0));
      expect(state.adaptiveBgThemeOverlay, equals(0.5));
      expect(state.fontFamily, equals('inter'));
      expect(state.textScale, equals(1.0));
    });

    test('setTheme updates repository and state', () async {
      final vm = container.read(appearanceViewModelProvider.notifier);
      vm.setTheme('nord_light');

      await Future<void>.delayed(Duration.zero);
      expect(fakeConfigRepo.currentConfig.theme, equals('nord_light'));
      expect(container.read(appearanceViewModelProvider).theme, equals('nord_light'));
    });

    test('setThemeBrightness updates repository and state', () async {
      final vm = container.read(appearanceViewModelProvider.notifier);
      vm.setThemeBrightness(Brightness.light);

      await Future<void>.delayed(Duration.zero);
      expect(fakeConfigRepo.currentConfig.themeBrightness, equals(Brightness.light));
      expect(container.read(appearanceViewModelProvider).themeBrightness, equals(Brightness.light));
    });

    test('setIconSet updates repository and state', () async {
      final vm = container.read(appearanceViewModelProvider.notifier);
      vm.setIconSet('feather');

      await Future<void>.delayed(Duration.zero);
      expect(fakeConfigRepo.currentConfig.iconSet, equals('feather'));
      expect(container.read(appearanceViewModelProvider).iconSet, equals('feather'));
    });

    test('setAdaptiveBg updates repository and state', () async {
      final vm = container.read(appearanceViewModelProvider.notifier);
      vm.setAdaptiveBg(true);

      await Future<void>.delayed(Duration.zero);
      expect(fakeConfigRepo.currentConfig.adaptiveBg, isTrue);
      expect(container.read(appearanceViewModelProvider).adaptiveBg, isTrue);
    });

    test('setAlbumFit updates repository and state', () async {
      final vm = container.read(appearanceViewModelProvider.notifier);
      vm.setAlbumFit(BoxFit.contain);

      await Future<void>.delayed(Duration.zero);
      expect(fakeConfigRepo.currentConfig.adaptiveBgAlbumFit, equals(BoxFit.contain));
      expect(container.read(appearanceViewModelProvider).adaptiveBgAlbumFit, equals(BoxFit.contain));
    });

    test('setAlbumBlur updates repository and state', () async {
      final vm = container.read(appearanceViewModelProvider.notifier);
      vm.setAlbumBlur(35.0);

      await Future<void>.delayed(Duration.zero);
      expect(fakeConfigRepo.currentConfig.adaptiveBgAlbumBlur, equals(35.0));
      expect(container.read(appearanceViewModelProvider).adaptiveBgAlbumBlur, equals(35.0));
    });

    test('setPanelBlur updates repository and state', () async {
      final vm = container.read(appearanceViewModelProvider.notifier);
      vm.setPanelBlur(15.0);

      await Future<void>.delayed(Duration.zero);
      expect(fakeConfigRepo.currentConfig.adaptiveBgPanelBlur, equals(15.0));
      expect(container.read(appearanceViewModelProvider).adaptiveBgPanelBlur, equals(15.0));
    });

    test('setThemeOverlay updates repository and state', () async {
      final vm = container.read(appearanceViewModelProvider.notifier);
      vm.setThemeOverlay(0.75);

      await Future<void>.delayed(Duration.zero);
      expect(fakeConfigRepo.currentConfig.adaptiveBgThemeOverlay, equals(0.75));
      expect(container.read(appearanceViewModelProvider).adaptiveBgThemeOverlay, equals(0.75));
    });

    test('setFontFamily updates repository and state', () async {
      final vm = container.read(appearanceViewModelProvider.notifier);
      vm.setFontFamily('roboto');

      await Future<void>.delayed(Duration.zero);
      expect(fakeConfigRepo.currentConfig.fontFamily, equals('roboto'));
      expect(container.read(appearanceViewModelProvider).fontFamily, equals('roboto'));
    });

    test('setTextScale rounds and updates repository and state', () async {
      final vm = container.read(appearanceViewModelProvider.notifier);
      vm.setTextScale(1.2567);

      await Future<void>.delayed(Duration.zero);
      expect(fakeConfigRepo.currentConfig.textScale, equals(1.26));
      expect(container.read(appearanceViewModelProvider).textScale, equals(1.26));
    });
  });
}
