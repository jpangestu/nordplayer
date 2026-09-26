import 'package:flutter/foundation.dart';
import 'package:nordplayer/config/app_config.dart';

/// Immutable UI state representing the Library Indexer and multi-artist parsing configuration.
class const LibraryIndexerUiState({
  final List<String> trackDirectories = const [],
  final bool watchTrackDirectories = false,
  final List<String> artistDelimiters = const [],
  final List<String> artistExclusions = const [],
  final bool isScanning = false,
  final bool isReindexing = false,
  final bool isFingerprinting = false,
  final bool adaptiveBg = false,
}) {
  /// Whether any library maintenance background task is currently running.
  bool get isAnyTaskRunning => isScanning || isReindexing || isFingerprinting;

  /// Custom artist exclusions (not part of the default set), sorted alphabetically.
  List<String> get customExclusions {
    final defaultSet = AppConfig.defaultArtistExclusions.map((e) => e.toLowerCase().trim()).toSet();
    return artistExclusions.where((e) => !defaultSet.contains(e.toLowerCase().trim())).toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  }

  /// Active default artist exclusions (part of the default set), sorted alphabetically.
  List<String> get activeDefaultExclusions {
    final defaultSet = AppConfig.defaultArtistExclusions.map((e) => e.toLowerCase().trim()).toSet();
    return artistExclusions.where((e) => defaultSet.contains(e.toLowerCase().trim())).toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  }

  LibraryIndexerUiState copyWith({
    List<String>? trackDirectories,
    bool? watchTrackDirectories,
    List<String>? artistDelimiters,
    List<String>? artistExclusions,
    bool? isScanning,
    bool? isReindexing,
    bool? isFingerprinting,
    bool? adaptiveBg,
  }) {
    return LibraryIndexerUiState(
      trackDirectories: trackDirectories ?? this.trackDirectories,
      watchTrackDirectories: watchTrackDirectories ?? this.watchTrackDirectories,
      artistDelimiters: artistDelimiters ?? this.artistDelimiters,
      artistExclusions: artistExclusions ?? this.artistExclusions,
      isScanning: isScanning ?? this.isScanning,
      isReindexing: isReindexing ?? this.isReindexing,
      isFingerprinting: isFingerprinting ?? this.isFingerprinting,
      adaptiveBg: adaptiveBg ?? this.adaptiveBg,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LibraryIndexerUiState &&
          runtimeType == other.runtimeType &&
          listEquals(trackDirectories, other.trackDirectories) &&
          watchTrackDirectories == other.watchTrackDirectories &&
          listEquals(artistDelimiters, other.artistDelimiters) &&
          listEquals(artistExclusions, other.artistExclusions) &&
          isScanning == other.isScanning &&
          isReindexing == other.isReindexing &&
          isFingerprinting == other.isFingerprinting &&
          adaptiveBg == other.adaptiveBg;

  @override
  int get hashCode => Object.hash(
    Object.hashAll(trackDirectories),
    watchTrackDirectories,
    Object.hashAll(artistDelimiters),
    Object.hashAll(artistExclusions),
    isScanning,
    isReindexing,
    isFingerprinting,
    adaptiveBg,
  );

  @override
  String toString() =>
      'LibraryIndexerUiState(directories: ${trackDirectories.length}, delimiters: ${artistDelimiters.length}, exclusions: ${artistExclusions.length}, isScanning: $isScanning, isReindexing: $isReindexing, isFingerprinting: $isFingerprinting)';
}
