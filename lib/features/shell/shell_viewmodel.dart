import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nordplayer/data/repositories/config_repository.dart';
import 'package:nordplayer/data/repositories/settings_repository.dart';
import 'package:nordplayer/features/shell/shell_ui_state.dart';

export 'package:nordplayer/features/shell/shell_ui_state.dart';

/// ViewModel managing layout, sidebar state, and responsive chrome visibility.
class ShellViewModel extends Notifier<ShellUiState> {
  late SettingsRepository _settingsRepo;
  late ConfigRepository _configRepo;

  @override
  ShellUiState build() {
    _settingsRepo = ref.watch(settingsRepositoryProvider);
    _configRepo = ref.watch(configRepositoryProvider);

    final currentSettings = _settingsRepo.currentSettings;
    final currentConfig = _configRepo.currentConfig;

    final initialState = ShellUiState(
      isSidebarExtended: currentSettings.sidebarExtended,
      showQueue: currentSettings.showQueue,
      isAdaptiveBg: currentConfig.adaptiveBg,
      adaptiveBgPanelBlur: currentConfig.adaptiveBgPanelBlur,
      adaptiveBgThemeOverlay: currentConfig.adaptiveBgThemeOverlay,
    );

    final sub1 = _settingsRepo.watchSettings().listen((settings) {
      state = state.copyWith(
        isSidebarExtended: settings.sidebarExtended,
        showQueue: settings.showQueue,
      );
    });

    final sub2 = _configRepo.watchConfig().listen((config) {
      state = state.copyWith(
        isAdaptiveBg: config.adaptiveBg,
        adaptiveBgPanelBlur: config.adaptiveBgPanelBlur,
        adaptiveBgThemeOverlay: config.adaptiveBgThemeOverlay,
      );
    });

    ref.onDispose(() {
      sub1.cancel();
      sub2.cancel();
    });

    return initialState;
  }

  // User Actions (Intents)

  Future<void> toggleSidebar() {
    return _settingsRepo.setSidebarExtended(!state.isSidebarExtended);
  }

  Future<void> setSidebarExtended(bool extended) {
    return _settingsRepo.setSidebarExtended(extended);
  }

  Future<void> toggleShowQueue() {
    return _settingsRepo.setShowQueue(!state.showQueue);
  }

  Future<void> setShowQueue(bool show) {
    return _settingsRepo.setShowQueue(show);
  }
}

/// Provider for [ShellViewModel] and its immutable [ShellUiState].
final shellViewModelProvider =
    NotifierProvider<ShellViewModel, ShellUiState>(
  ShellViewModel.new,
);
