import 'dart:async';

import 'package:nordplayer/data/repositories/album_repository.dart';
import 'package:nordplayer/domain/models/album.dart';
import 'package:nordplayer/domain/models/artist.dart';
import 'package:nordplayer/domain/models/composite_models.dart';

/// In-memory test double for [AlbumRepository].
class FakeAlbumRepository({
  List<Album>? initialAlbums,
  Map<int, AlbumWithTracks>? initialAlbumWithTracks,
  Map<int, List<Artist>>? initialTrackArtists,
}) implements AlbumRepository {
  List<Album> albums = initialAlbums ?? [];
  Map<int, AlbumWithTracks> albumWithTracksMap = initialAlbumWithTracks ?? {};
  Map<int, List<Artist>> trackArtistsMap = initialTrackArtists ?? {};
  List<Artist> trackArtistsToReturn = const [];

  final StreamController<List<Album>> _albumsController = StreamController<List<Album>>.broadcast();
  final StreamController<AlbumWithTracks?> _albumWithTracksController =
      StreamController<AlbumWithTracks?>.broadcast();

  void emitAlbums(List<Album> newAlbums) {
    albums = newAlbums;
    _albumsController.add(albums);
  }

  void emitError(Object error) {
    _albumsController.addError(error);
  }

  void emitAlbum(AlbumWithTracks? album) {
    if (album != null) {
      albumWithTracksMap[album.album.id] = album;
    }
    _albumWithTracksController.add(album);
  }

  void emitAlbumWithTracks(int albumId, AlbumWithTracks? album) {
    if (album != null) {
      albumWithTracksMap[albumId] = album;
    }
    _albumWithTracksController.add(album);
  }

  @override
  Stream<List<Album>> watchAlbums() {
    if (albums.isNotEmpty) {
      return Stream.value(albums).concatWith([_albumsController.stream]);
    }
    return _albumsController.stream;
  }

  @override
  Stream<AlbumWithTracks?> watchAlbumWithTracks(int albumId) {
    if (albumWithTracksMap.containsKey(albumId)) {
      return Stream.value(albumWithTracksMap[albumId]).concatWith([_albumWithTracksController.stream]);
    }
    return _albumWithTracksController.stream;
  }

  @override
  Future<List<Artist>> getTrackArtists({required int albumId}) async {
    return trackArtistsMap[albumId] ?? trackArtistsToReturn;
  }

  @override
  Future<List<Album>> getRandomAlbums({int limitAmount = 10}) async {
    return albums.take(limitAmount).toList();
  }

  void dispose() {
    _albumsController.close();
    _albumWithTracksController.close();
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
