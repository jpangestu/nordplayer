/// Immutable UI state representing advanced settings and data maintenance operations.
class const AdvancedSettingsUiState({final bool isProcessing = false, final bool adaptiveBg = false}) {
  AdvancedSettingsUiState copyWith({bool? isProcessing, bool? adaptiveBg}) {
    return AdvancedSettingsUiState(
      isProcessing: isProcessing ?? this.isProcessing,
      adaptiveBg: adaptiveBg ?? this.adaptiveBg,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdvancedSettingsUiState &&
          runtimeType == other.runtimeType &&
          isProcessing == other.isProcessing &&
          adaptiveBg == other.adaptiveBg;

  @override
  int get hashCode => Object.hash(isProcessing, adaptiveBg);

  @override
  String toString() => 'AdvancedSettingsUiState(isProcessing: $isProcessing, adaptiveBg: $adaptiveBg)';
}
