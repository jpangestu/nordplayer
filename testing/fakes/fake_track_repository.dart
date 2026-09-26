import 'dart:async';

import 'package:nordplayer/data/repositories/track_repository.dart';
import 'package:nordplayer/domain/models/models.dart';

/// In-memory test double for [TrackRepository].
class FakeTrackRepository implements TrackRepository {
  List<TrackWithArtists> tracks;
  LibraryStats stats;

  final StreamController<List<TrackWithArtists>> _tracksController =
      StreamController<List<TrackWithArtists>>.broadcast();
  final StreamController<LibraryStats> _statsController =
      StreamController<LibraryStats>.broadcast();

  final List<int> deletedTrackIds = [];
  final List<int> markedMissingTrackIds = [];
  bool deleteOrphanedMetadataCalled = false;
  bool clearAllDataCalled = false;

  FakeTrackRepository({
    List<TrackWithArtists>? initialTracks,
    LibraryStats? initialStats,
  })  : tracks = initialTracks ?? [],
        stats = initialStats ?? const LibraryStats.empty();

  void emitTracks(List<TrackWithArtists> newTracks) {
    tracks = newTracks;
    _tracksController.add(tracks);
  }

  void emitStats(LibraryStats newStats) {
    stats = newStats;
    _statsController.add(stats);
  }

  @override
  Stream<List<TrackWithArtists>> watchAllTracks() {
    return Stream.value(tracks).concatWith([_tracksController.stream]);
  }

  @override
  Future<TrackWithArtists?> getTrackById(int id) async {
    for (final track in tracks) {
      if (track.track.id == id) return track;
    }
    return null;
  }

  @override
  Stream<List<TrackWithArtists>> watchRecentlyAddedTracks({int limitAmount = 10}) {
    final recent = tracks.take(limitAmount).toList();
    return Stream.value(recent).concatWith([
      _tracksController.stream.map((list) => list.take(limitAmount).toList()),
    ]);
  }

  @override
  Stream<LibraryStats> watchLibraryStats() {
    return Stream.value(stats).concatWith([_statsController.stream]);
  }

  @override
  Stream<List<TrackWithArtists>> searchTracks(String queryStr) {
    final lower = queryStr.toLowerCase();
    final matched = tracks.where((t) {
      final titleMatch = t.track.title.toLowerCase().contains(lower);
      final albumMatch = t.album.title.toLowerCase().contains(lower);
      final artistMatch = t.artists.any((a) => a.name.toLowerCase().contains(lower));
      return titleMatch || albumMatch || artistMatch;
    }).toList();
    return Stream.value(matched);
  }

  @override
  Future<void> deleteOrphanedMetadata() async {
    deleteOrphanedMetadataCalled = true;
  }

  @override
  Future<void> clearAllData() async {
    clearAllDataCalled = true;
    tracks.clear();
    emitTracks([]);
  }

  @override
  Future<void> markTracksMissingByIds(List<int> trackIds) async {
    markedMissingTrackIds.addAll(trackIds);
  }

  @override
  Future<void> updateTrackFilePath(int trackId, String newFilePath) async {
    final index = tracks.indexWhere((t) => t.track.id == trackId);
    if (index != -1) {
      final current = tracks[index];
      final updatedTrack = current.track.copyWith(filePath: newFilePath);
      tracks[index] = TrackWithArtists(track: updatedTrack, album: current.album, artists: current.artists);
      emitTracks(tracks);
    }
  }

  @override
  Future<void> updateTrackHash(int trackId, String newHash) async {
    final index = tracks.indexWhere((t) => t.track.id == trackId);
    if (index != -1) {
      final current = tracks[index];
      final updatedTrack = current.track.copyWith(fileHash: newHash);
      tracks[index] = TrackWithArtists(track: updatedTrack, album: current.album, artists: current.artists);
      emitTracks(tracks);
    }
  }

  @override
  Future<void> deleteTrack(int trackId) async {
    deletedTrackIds.add(trackId);
    tracks.removeWhere((t) => t.track.id == trackId);
    emitTracks(tracks);
  }

  void dispose() {
    _tracksController.close();
    _statsController.close();
  }
}

extension on Stream<dynamic> {
  Stream<T> concatWith<T>(Iterable<Stream<T>> others) async* {
    if (this is Stream<T>) {
      yield* this as Stream<T>;
    }
    for (final other in others) {
      yield* other;
    }
  }
}
