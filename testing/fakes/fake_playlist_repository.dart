import 'dart:async';

import 'package:nordplayer/data/repositories/playlist_repository.dart';
import 'package:nordplayer/domain/models/composite_models.dart';
import 'package:nordplayer/domain/models/playlist.dart';

/// In-memory test double for [PlaylistRepository].
class FakePlaylistRepository({
  List<PlaylistWithDetails>? initialPlaylists,
  Map<int, List<TrackWithArtists>>? initialPlaylistTracks,
}) implements PlaylistRepository {
  List<PlaylistWithDetails> playlists = initialPlaylists ?? [];
  Map<int, List<TrackWithArtists>> playlistTracksMap = initialPlaylistTracks ?? {};
  int _nextId = (initialPlaylists != null && initialPlaylists.isNotEmpty)
      ? initialPlaylists.map((p) => p.playlist.id).reduce((a, b) => a > b ? a : b) + 1
      : 101;

  final List<String> createdNames = [];
  final List<List<int>?> createdTrackIds = [];
  final Map<int, String> renamedPlaylists = {};
  final List<int> deletedPlaylists = [];
  final Map<int, List<int>> addedTracks = {};
  final List<(int, int)> removedTracks = [];
  List<TrackWithArtists> defaultPlaylistTracks = const [];

  final StreamController<List<PlaylistWithDetails>> _playlistsController =
      StreamController<List<PlaylistWithDetails>>.broadcast();
  final StreamController<List<TrackWithArtists>> _playlistTracksController =
      StreamController<List<TrackWithArtists>>.broadcast();

  List<TrackWithArtists> get playlistTracks => defaultPlaylistTracks;
  set playlistTracks(List<TrackWithArtists> tracks) {
    defaultPlaylistTracks = tracks;
    _playlistTracksController.add(tracks);
  }

  void emitPlaylists(List<PlaylistWithDetails> newPlaylists) {
    playlists = newPlaylists;
    _playlistsController.add(playlists);
  }

  @override
  Stream<List<PlaylistWithDetails>> watchAllPlaylists() {
    return Stream.value(playlists).concatWith([_playlistsController.stream]);
  }

  @override
  Stream<Playlist> watchPlaylist(int playlistId) {
    final match = playlists.firstWhere(
      (p) => p.playlist.id == playlistId,
      orElse: () => PlaylistWithDetails(
        playlist: Playlist(id: playlistId, name: 'Test Playlist'),
        trackCount: 0,
        imageUrls: const [],
      ),
    );
    return Stream.value(match.playlist);
  }

  @override
  Future<List<TrackWithArtists>> getPlaylistTracks(int playlistId) async {
    return playlistTracksMap[playlistId] ?? defaultPlaylistTracks;
  }

  @override
  Stream<List<TrackWithArtists>> watchPlaylistTracks(int playlistId) {
    final current = playlistTracksMap[playlistId] ?? defaultPlaylistTracks;
    return Stream.value(current).concatWith([_playlistTracksController.stream]);
  }

  @override
  Future<int> createPlaylist(String name, {List<int>? trackIds}) async {
    createdNames.add(name);
    createdTrackIds.add(trackIds);
    final id = _nextId++;
    final newPlaylist = PlaylistWithDetails(
      playlist: Playlist(id: id, name: name),
      trackCount: trackIds?.length ?? 0,
      imageUrls: const [],
    );
    playlists.add(newPlaylist);
    playlistTracksMap[id] = [];
    emitPlaylists(playlists);
    return id;
  }

  @override
  Future<void> renamePlaylist(int playlistId, String newName) async {
    renamedPlaylists[playlistId] = newName;
    final idx = playlists.indexWhere((p) => p.playlist.id == playlistId);
    if (idx != -1) {
      final current = playlists[idx];
      playlists[idx] = PlaylistWithDetails(
        playlist: Playlist(id: playlistId, name: newName, coverPath: current.playlist.coverPath),
        trackCount: current.trackCount,
        imageUrls: current.imageUrls,
      );
      emitPlaylists(playlists);
    }
  }

  @override
  Future<void> deletePlaylist(int playlistId) async {
    deletedPlaylists.add(playlistId);
    playlists.removeWhere((p) => p.playlist.id == playlistId);
    playlistTracksMap.remove(playlistId);
    emitPlaylists(playlists);
  }

  @override
  Future<void> addTracksToPlaylist(int playlistId, List<int> trackIds) async {
    addedTracks[playlistId] = trackIds;
  }

  @override
  Future<void> removeTrackFromPlaylist(int playlistId, int trackId) async {
    removedTracks.add((playlistId, trackId));
    final tracks = playlistTracksMap[playlistId];
    if (tracks != null) {
      tracks.removeWhere((t) => t.track.id == trackId);
      final idx = playlists.indexWhere((p) => p.playlist.id == playlistId);
      if (idx != -1) {
        playlists[idx] = PlaylistWithDetails(
          playlist: playlists[idx].playlist,
          trackCount: tracks.length,
          imageUrls: playlists[idx].imageUrls,
        );
        emitPlaylists(playlists);
      }
    }
  }

  void dispose() {
    _playlistsController.close();
    _playlistTracksController.close();
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
