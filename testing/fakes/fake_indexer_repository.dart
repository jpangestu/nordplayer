import 'dart:async';

import 'package:nordplayer/data/repositories/indexer_repository.dart';
import 'package:nordplayer/domain/models/track.dart';
import 'package:nordplayer/domain/models/duplicate_group.dart';

/// In-memory test double for [IndexerRepository].
class FakeIndexerRepository({
  List<DuplicateGroup>? initialDuplicateGroups,
}) implements IndexerRepository {
  bool scanLibraryCalled = false;
  bool reindexTracksCalled = false;
  bool generateMissingFingerprintsCalled = false;

  final List<String> missingDirectories = [];
  final List<String> stoppedDirectories = [];
  final List<Track> ignoredTracks = [];
  List<DuplicateGroup> duplicateGroups = initialDuplicateGroups ?? [];

  @override
  void scanLibrary() {
    scanLibraryCalled = true;
  }

  @override
  void reindexTracks() {
    reindexTracksCalled = true;
  }

  @override
  void generateMissingFingerprints() {
    generateMissingFingerprintsCalled = true;
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
    return duplicateGroups;
  }

  @override
  Future<void> ignoreTrack(Track track) async {
    ignoredTracks.add(track);
  }

  @override
  Future<void> ignoreTracks(List<Track> tracks) async {
    ignoredTracks.addAll(tracks);
  }
}
