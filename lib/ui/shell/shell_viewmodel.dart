import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nordplayer/data/repositories/config_repository.dart';
import 'package:nordplayer/data/repositories/ui_preferences_repository.dart';
import 'package:nordplayer/ui/shell/shell_ui_state.dart';

/// ViewModel managing layout, sidebar state, and responsive chrome visibility.
class ShellViewModel extends Notifier<ShellUiState> {
  late UiPreferencesRepository _uiPreferencesRepo;
  late ConfigRepository _configRepo;

  @override
  ShellUiState build() {
    _uiPreferencesRepo = ref.watch(uiPreferencesRepositoryProvider);
    _configRepo = ref.watch(configRepositoryProvider);

    final currentPrefs = _uiPreferencesRepo.currentPreferences;
    final currentConfig = _configRepo.currentConfig;

    final initialState = ShellUiState(
      isSidebarExtended: currentPrefs.sidebarExtended,
      showQueue: currentPrefs.showQueue,
      isAdaptiveBg: currentConfig.adaptiveBg,
      adaptiveBgPanelBlur: currentConfig.adaptiveBgPanelBlur,
      adaptiveBgThemeOverlay: currentConfig.adaptiveBgThemeOverlay,
    );

    final sub1 = _uiPreferencesRepo.watchPreferences().listen((prefs) {
      state = state.copyWith(isSidebarExtended: prefs.sidebarExtended, showQueue: prefs.showQueue);
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
    return _uiPreferencesRepo.setSidebarExtended(!state.isSidebarExtended);
  }

  Future<void> setSidebarExtended(bool extended) {
    return _uiPreferencesRepo.setSidebarExtended(extended);
  }

  Future<void> toggleShowQueue() {
    return _uiPreferencesRepo.setShowQueue(!state.showQueue);
  }

  Future<void> setShowQueue(bool show) {
    return _uiPreferencesRepo.setShowQueue(show);
  }
}

/// Provider for [ShellViewModel] and its immutable [ShellUiState].
final shellViewModelProvider = NotifierProvider<ShellViewModel, ShellUiState>(ShellViewModel.new);
