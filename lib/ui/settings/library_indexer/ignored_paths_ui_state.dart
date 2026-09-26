import 'package:flutter/foundation.dart';
import 'package:nordplayer/data/database/app_database.dart' show IgnoredPath;

/// Immutable UI state representing ignored file paths and restoration processing.
class const IgnoredPathsUiState({
  final List<IgnoredPath> paths = const [],
  final Set<String> manuallyRestoredPaths = const {},
  final bool isLoading = true,
  final bool isProcessing = false,
  final String? errorMessage,
  final bool adaptiveBg = false,
  final double adaptiveBgPanelBlur = 20.0,
  final double adaptiveBgThemeOverlay = 0.5,
}) {
  /// Filtered ignored paths excluding manually restored items.
  List<IgnoredPath> get filteredPaths => paths.where((p) => !manuallyRestoredPaths.contains(p.filePath)).toList();

  bool get showRestoreAll => filteredPaths.isNotEmpty;
  bool get showEmptyMessage => filteredPaths.isEmpty;
  bool get showList => filteredPaths.isNotEmpty;
  bool get hasError => errorMessage != null;

  IgnoredPathsUiState copyWith({
    List<IgnoredPath>? paths,
    Set<String>? manuallyRestoredPaths,
    bool? isLoading,
    bool? isProcessing,
    String? Function()? errorMessage,
    bool? adaptiveBg,
    double? adaptiveBgPanelBlur,
    double? adaptiveBgThemeOverlay,
  }) {
    return IgnoredPathsUiState(
      paths: paths ?? this.paths,
      manuallyRestoredPaths: manuallyRestoredPaths ?? this.manuallyRestoredPaths,
      isLoading: isLoading ?? this.isLoading,
      isProcessing: isProcessing ?? this.isProcessing,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      adaptiveBg: adaptiveBg ?? this.adaptiveBg,
      adaptiveBgPanelBlur: adaptiveBgPanelBlur ?? this.adaptiveBgPanelBlur,
      adaptiveBgThemeOverlay: adaptiveBgThemeOverlay ?? this.adaptiveBgThemeOverlay,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IgnoredPathsUiState &&
          runtimeType == other.runtimeType &&
          listEquals(paths, other.paths) &&
          setEquals(manuallyRestoredPaths, other.manuallyRestoredPaths) &&
          isLoading == other.isLoading &&
          isProcessing == other.isProcessing &&
          errorMessage == other.errorMessage &&
          adaptiveBg == other.adaptiveBg &&
          adaptiveBgPanelBlur == other.adaptiveBgPanelBlur &&
          adaptiveBgThemeOverlay == other.adaptiveBgThemeOverlay;

  @override
  int get hashCode => Object.hash(
    Object.hashAll(paths),
    Object.hashAll(manuallyRestoredPaths),
    isLoading,
    isProcessing,
    errorMessage,
    adaptiveBg,
    adaptiveBgPanelBlur,
    adaptiveBgThemeOverlay,
  );

  @override
  String toString() =>
      'IgnoredPathsUiState(paths: ${paths.length}, restored: ${manuallyRestoredPaths.length}, isLoading: $isLoading)';
}
