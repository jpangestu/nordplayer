import 'package:package_info_plus/package_info_plus.dart';

/// Immutable UI state for the About screen and licenses.
class const AboutUiState({
  final PackageInfo? packageInfo,
  final bool isLoading = true,
  final bool adaptiveBg = false,
  final double adaptiveBgPanelBlur = 20.0,
  final double adaptiveBgThemeOverlay = 0.5,
}) {
  String get appName => packageInfo?.appName ?? 'Nordplayer';
  String get version => packageInfo != null ? 'v${packageInfo!.version}' : '';

  AboutUiState copyWith({
    PackageInfo? packageInfo,
    bool? isLoading,
    bool? adaptiveBg,
    double? adaptiveBgPanelBlur,
    double? adaptiveBgThemeOverlay,
  }) {
    return AboutUiState(
      packageInfo: packageInfo ?? this.packageInfo,
      isLoading: isLoading ?? this.isLoading,
      adaptiveBg: adaptiveBg ?? this.adaptiveBg,
      adaptiveBgPanelBlur: adaptiveBgPanelBlur ?? this.adaptiveBgPanelBlur,
      adaptiveBgThemeOverlay: adaptiveBgThemeOverlay ?? this.adaptiveBgThemeOverlay,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AboutUiState &&
          runtimeType == other.runtimeType &&
          packageInfo == other.packageInfo &&
          isLoading == other.isLoading &&
          adaptiveBg == other.adaptiveBg &&
          adaptiveBgPanelBlur == other.adaptiveBgPanelBlur &&
          adaptiveBgThemeOverlay == other.adaptiveBgThemeOverlay;

  @override
  int get hashCode => Object.hash(
        packageInfo,
        isLoading,
        adaptiveBg,
        adaptiveBgPanelBlur,
        adaptiveBgThemeOverlay,
      );

  @override
  String toString() => 'AboutUiState(appName: $appName, version: $version, isLoading: $isLoading)';
}
