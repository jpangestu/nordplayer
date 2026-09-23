import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nordplayer/utils/logger.dart';
import 'package:nordplayer/data/repositories/config_repository.dart';
import 'package:nordplayer/ui/settings/about/about_ui_state.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Provider for async PackageInfo platform retrieval.
final packageInfoProvider = FutureProvider<PackageInfo>((ref) async {
  return await PackageInfo.fromPlatform();
});

/// ViewModel managing state and metadata for the About and Licenses screens.
class AboutViewModel extends Notifier<AboutUiState> with LoggerMixin {
  @override
  AboutUiState build() {
    final configRepo = ref.watch(configRepositoryProvider);
    final currentConfig = configRepo.currentConfig;
    final packageInfoAsync = ref.watch(packageInfoProvider);

    final configSub = configRepo.watchConfig().listen((config) {
      state = state.copyWith(
        adaptiveBg: config.adaptiveBg,
        adaptiveBgPanelBlur: config.adaptiveBgPanelBlur,
        adaptiveBgThemeOverlay: config.adaptiveBgThemeOverlay,
      );
    });
    ref.onDispose(configSub.cancel);

    return AboutUiState(
      packageInfo: packageInfoAsync.value,
      isLoading: packageInfoAsync.isLoading,
      adaptiveBg: currentConfig.adaptiveBg,
      adaptiveBgPanelBlur: currentConfig.adaptiveBgPanelBlur,
      adaptiveBgThemeOverlay: currentConfig.adaptiveBgThemeOverlay,
    );
  }
}

/// Riverpod provider for [AboutViewModel] and [AboutUiState].
final aboutViewModelProvider =
    NotifierProvider<AboutViewModel, AboutUiState>(AboutViewModel.new);

/// Provider loading licenses registered in the application.
final packageLicensesProvider = FutureProvider<Map<String, List<LicenseEntry>>>((ref) async {
  final Map<String, List<LicenseEntry>> packageLicenses = {};
  final licenses = await LicenseRegistry.licenses.toList();
  for (final license in licenses) {
    for (final package in license.packages) {
      packageLicenses.putIfAbsent(package, () => []).add(license);
    }
  }
  return packageLicenses;
});
