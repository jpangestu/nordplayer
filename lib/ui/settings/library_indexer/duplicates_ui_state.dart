import 'package:flutter/foundation.dart';
import 'package:nordplayer/domain/models/duplicate_group.dart';

/// Immutable UI state representing duplicate tracks and resolution processing.
class const DuplicatesUiState({
  final List<DuplicateGroup> duplicateGroups = const [],
  final Set<int> manuallyIgnoredTrackIds = const {},
  final bool isLoading = true,
  final bool isProcessing = false,
  final bool isScanning = false,
  final bool isScanningTriggered = false,
  final String? errorMessage,
  final bool adaptiveBg = false,
  final double adaptiveBgPanelBlur = 20.0,
  final double adaptiveBgThemeOverlay = 0.5,
}) {
  /// Deduplicated and filtered duplicate groups based on manually ignored tracks.
  List<DuplicateGroup> get filteredGroups {
    return duplicateGroups
        .map((group) {
          final remainingTracks = group.tracks.where((t) => !manuallyIgnoredTrackIds.contains(t.id)).toList();
          if (remainingTracks.length < 2) return null;

          final preferredTrack = remainingTracks.contains(group.preferredTrack)
              ? group.preferredTrack
              : remainingTracks.first;

          return DuplicateGroup(
            title: group.title,
            artist: group.artist,
            album: group.album,
            tracks: remainingTracks,
            preferredTrack: preferredTrack,
          );
        })
        .whereType<DuplicateGroup>()
        .toList()
      ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
  }

  bool get isScanLoading => isLoading || isScanning || isScanningTriggered;
  bool get hasError => errorMessage != null;
  bool get showKeepAllBest => !isScanLoading && !hasError && filteredGroups.isNotEmpty;
  bool get showStats => !isScanLoading && !hasError && filteredGroups.isNotEmpty;

  DuplicatesUiState copyWith({
    List<DuplicateGroup>? duplicateGroups,
    Set<int>? manuallyIgnoredTrackIds,
    bool? isLoading,
    bool? isProcessing,
    bool? isScanning,
    bool? isScanningTriggered,
    String? Function()? errorMessage,
    bool? adaptiveBg,
    double? adaptiveBgPanelBlur,
    double? adaptiveBgThemeOverlay,
  }) {
    return DuplicatesUiState(
      duplicateGroups: duplicateGroups ?? this.duplicateGroups,
      manuallyIgnoredTrackIds: manuallyIgnoredTrackIds ?? this.manuallyIgnoredTrackIds,
      isLoading: isLoading ?? this.isLoading,
      isProcessing: isProcessing ?? this.isProcessing,
      isScanning: isScanning ?? this.isScanning,
      isScanningTriggered: isScanningTriggered ?? this.isScanningTriggered,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      adaptiveBg: adaptiveBg ?? this.adaptiveBg,
      adaptiveBgPanelBlur: adaptiveBgPanelBlur ?? this.adaptiveBgPanelBlur,
      adaptiveBgThemeOverlay: adaptiveBgThemeOverlay ?? this.adaptiveBgThemeOverlay,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DuplicatesUiState &&
          runtimeType == other.runtimeType &&
          listEquals(duplicateGroups, other.duplicateGroups) &&
          setEquals(manuallyIgnoredTrackIds, other.manuallyIgnoredTrackIds) &&
          isLoading == other.isLoading &&
          isProcessing == other.isProcessing &&
          isScanning == other.isScanning &&
          isScanningTriggered == other.isScanningTriggered &&
          errorMessage == other.errorMessage &&
          adaptiveBg == other.adaptiveBg &&
          adaptiveBgPanelBlur == other.adaptiveBgPanelBlur &&
          adaptiveBgThemeOverlay == other.adaptiveBgThemeOverlay;

  @override
  int get hashCode => Object.hash(
        Object.hashAll(duplicateGroups),
        Object.hashAll(manuallyIgnoredTrackIds),
        isLoading,
        isProcessing,
        isScanning,
        isScanningTriggered,
        errorMessage,
        adaptiveBg,
        adaptiveBgPanelBlur,
        adaptiveBgThemeOverlay,
      );

  @override
  String toString() =>
      'DuplicatesUiState(groups: ${duplicateGroups.length}, ignored: ${manuallyIgnoredTrackIds.length}, isLoading: $isLoading, isScanning: $isScanning)';
}
