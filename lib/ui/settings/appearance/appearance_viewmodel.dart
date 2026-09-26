import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nordplayer/data/repositories/config_repository.dart';
import 'package:nordplayer/ui/settings/appearance/appearance_ui_state.dart';
import 'package:nordplayer/utils/logger.dart';

/// ViewModel managing state and operations for the Appearance settings screen.
class AppearanceViewModel extends Notifier<AppearanceUiState> with LoggerMixin {
  ConfigRepository get _configRepo => ref.read(configRepositoryProvider);

  @override
  AppearanceUiState build() {
    final configRepo = ref.watch(configRepositoryProvider);
    final initialConfig = configRepo.currentConfig;

    final subscription = configRepo.watchConfig().listen((config) {
      state = state.copyWith(
        theme: config.theme,
        themeBrightness: config.themeBrightness,
        iconSet: config.iconSet,
        adaptiveBg: config.adaptiveBg,
        adaptiveBgAlbumFit: config.adaptiveBgAlbumFit,
        adaptiveBgAlbumBlur: config.adaptiveBgAlbumBlur,
        adaptiveBgPanelBlur: config.adaptiveBgPanelBlur,
        adaptiveBgThemeOverlay: config.adaptiveBgThemeOverlay,
        fontFamily: config.fontFamily,
        textScale: config.textScale,
      );
    });

    ref.onDispose(subscription.cancel);

    return AppearanceUiState(
      theme: initialConfig.theme,
      themeBrightness: initialConfig.themeBrightness,
      iconSet: initialConfig.iconSet,
      adaptiveBg: initialConfig.adaptiveBg,
      adaptiveBgAlbumFit: initialConfig.adaptiveBgAlbumFit,
      adaptiveBgAlbumBlur: initialConfig.adaptiveBgAlbumBlur,
      adaptiveBgPanelBlur: initialConfig.adaptiveBgPanelBlur,
      adaptiveBgThemeOverlay: initialConfig.adaptiveBgThemeOverlay,
      fontFamily: initialConfig.fontFamily,
      textScale: initialConfig.textScale,
    );
  }

  void setTheme(String theme) {
    log.d('AppearanceViewModel.setTheme: $theme');
    _configRepo.updateConfig(_configRepo.currentConfig.copyWith(theme: theme));
  }

  void setThemeBrightness(Brightness brightness) {
    log.d('AppearanceViewModel.setThemeBrightness: $brightness');
    _configRepo.updateConfig(_configRepo.currentConfig.copyWith(themeBrightness: brightness));
  }

  void setIconSet(String iconSet) {
    log.d('AppearanceViewModel.setIconSet: $iconSet');
    _configRepo.updateConfig(_configRepo.currentConfig.copyWith(iconSet: iconSet));
  }

  void setAdaptiveBg(bool value) {
    log.d('AppearanceViewModel.setAdaptiveBg: $value');
    _configRepo.updateConfig(_configRepo.currentConfig.copyWith(adaptiveBg: value));
  }

  void setAlbumFit(BoxFit fit) {
    log.d('AppearanceViewModel.setAlbumFit: $fit');
    _configRepo.updateConfig(_configRepo.currentConfig.copyWith(adaptiveBgAlbumFit: fit));
  }

  void setAlbumBlur(double blur) {
    _configRepo.updateConfig(_configRepo.currentConfig.copyWith(adaptiveBgAlbumBlur: blur));
  }

  void setPanelBlur(double blur) {
    _configRepo.updateConfig(_configRepo.currentConfig.copyWith(adaptiveBgPanelBlur: blur));
  }

  void setThemeOverlay(double overlay) {
    _configRepo.updateConfig(_configRepo.currentConfig.copyWith(adaptiveBgThemeOverlay: overlay));
  }

  void setFontFamily(String font) {
    log.d('AppearanceViewModel.setFontFamily: $font');
    _configRepo.updateConfig(_configRepo.currentConfig.copyWith(fontFamily: font));
  }

  void setTextScale(double scale) {
    final rounded = (scale * 100).round() / 100;
    _configRepo.updateConfig(_configRepo.currentConfig.copyWith(textScale: rounded));
  }
}

/// Riverpod provider exposing [AppearanceViewModel] and [AppearanceUiState].
final appearanceViewModelProvider = NotifierProvider<AppearanceViewModel, AppearanceUiState>(AppearanceViewModel.new);
