import 'dart:async';

import 'package:nordplayer/data/repositories/album_repository.dart';
import 'package:nordplayer/domain/models/composite_models.dart';
import 'package:nordplayer/domain/models/album.dart';
import 'package:nordplayer/domain/models/artist.dart';

/// In-memory test double for [AlbumRepository].
class FakeAlbumRepository({
  List<Album>? initialAlbums,
  Map<int, AlbumWithTracks>? initialAlbumWithTracks,
  Map<int, List<Artist>>? initialTrackArtists,
}) implements AlbumRepository {
  List<Album> albums = initialAlbums ?? [];
  Map<int, AlbumWithTracks> albumWithTracksMap = initialAlbumWithTracks ?? {};
  Map<int, List<Artist>> trackArtistsMap = initialTrackArtists ?? {};

  final StreamController<List<Album>> _albumsController =
      StreamController<List<Album>>.broadcast();

  void emitAlbums(List<Album> newAlbums) {
    albums = newAlbums;
    _albumsController.add(albums);
  }

  @override
  Stream<List<Album>> watchAlbums() {
    return Stream.value(albums).concatWith([_albumsController.stream]);
  }

  @override
  Stream<AlbumWithTracks?> watchAlbumWithTracks(int albumId) {
    return Stream.value(albumWithTracksMap[albumId]);
  }

  @override
  Future<List<Artist>> getTrackArtists({required int albumId}) async {
    return trackArtistsMap[albumId] ?? [];
  }

  @override
  Future<List<Album>> getRandomAlbums({int limitAmount = 10}) async {
    return albums.take(limitAmount).toList();
  }

  void dispose() {
    _albumsController.close();
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
