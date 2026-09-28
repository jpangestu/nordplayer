import 'dart:async';

import 'package:nordplayer/data/repositories/indexer_repository.dart';
import 'package:nordplayer/domain/models/duplicate_group.dart';
import 'package:nordplayer/domain/models/track.dart';

/// In-memory test double for [IndexerRepository].
class FakeIndexerRepository({List<DuplicateGroup>? initialDuplicateGroups}) implements IndexerRepository {
  bool scanCalled = false;
  bool reindexCalled = false;
  bool fingerprintCalled = false;

  final List<String> missingDirectories = [];
  final List<String> stoppedDirectories = [];
  final List<Track> ignoredTracks = [];
  List<Track> lastIgnoredTracks = [];
  Track? lastSingleIgnoredTrack;
  List<DuplicateGroup> duplicateGroups = initialDuplicateGroups ?? [];
  List<DuplicateGroup> duplicateGroupsToReturn = [];

  String? get lastMarkedMissingPath => missingDirectories.isEmpty ? null : missingDirectories.last;
  String? get lastStoppedPath => stoppedDirectories.isEmpty ? null : stoppedDirectories.last;

  @override
  void scanLibrary() {
    scanCalled = true;
  }

  @override
  void reindexTracks() {
    reindexCalled = true;
  }

  @override
  void generateMissingFingerprints() {
    fingerprintCalled = true;
  }

  @override
  Future<void> markTracksInDirectoryAsMissing(String directoryPath) async {
    missingDirectories.add(directoryPath);
  }

  @override
  void stopWatchingDirectory(String directoryPath) {
    stoppedDirectories.add(directoryPath);
  }

  @override
  Future<List<DuplicateGroup>> findDuplicates() async {
    return duplicateGroupsToReturn.isNotEmpty ? duplicateGroupsToReturn : duplicateGroups;
  }

  @override
  Future<void> ignoreTrack(Track track) async {
    lastSingleIgnoredTrack = track;
    ignoredTracks.add(track);
  }

  @override
  Future<void> ignoreTracks(List<Track> tracks) async {
    lastIgnoredTracks = List.from(tracks);
    ignoredTracks.addAll(tracks);
  }
}
