/// Cohesive immutable UI state representing the app shell, sidebar, and layout preferences.
class const ShellUiState({
  final bool isSidebarExtended = true,
  final bool showQueue = false,
  final bool isAdaptiveBg = false,
  final double adaptiveBgPanelBlur = 20.0,
  final double adaptiveBgThemeOverlay = 0.5,
}) {
  ShellUiState copyWith({
    bool? isSidebarExtended,
    bool? showQueue,
    bool? isAdaptiveBg,
    double? adaptiveBgPanelBlur,
    double? adaptiveBgThemeOverlay,
  }) {
    return ShellUiState(
      isSidebarExtended: isSidebarExtended ?? this.isSidebarExtended,
      showQueue: showQueue ?? this.showQueue,
      isAdaptiveBg: isAdaptiveBg ?? this.isAdaptiveBg,
      adaptiveBgPanelBlur: adaptiveBgPanelBlur ?? this.adaptiveBgPanelBlur,
      adaptiveBgThemeOverlay: adaptiveBgThemeOverlay ?? this.adaptiveBgThemeOverlay,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShellUiState &&
          runtimeType == other.runtimeType &&
          isSidebarExtended == other.isSidebarExtended &&
          showQueue == other.showQueue &&
          isAdaptiveBg == other.isAdaptiveBg &&
          adaptiveBgPanelBlur == other.adaptiveBgPanelBlur &&
          adaptiveBgThemeOverlay == other.adaptiveBgThemeOverlay;

  @override
  int get hashCode => Object.hash(
        isSidebarExtended,
        showQueue,
        isAdaptiveBg,
        adaptiveBgPanelBlur,
        adaptiveBgThemeOverlay,
      );
}
