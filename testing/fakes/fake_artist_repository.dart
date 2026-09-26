import 'dart:async';

import 'package:nordplayer/data/repositories/artist_repository.dart';
import 'package:nordplayer/domain/models/artist.dart';

/// In-memory test double for [ArtistRepository].
class FakeArtistRepository([List<Artist>? initialArtists]) implements ArtistRepository {
  List<Artist> artists = initialArtists ?? [];
  final StreamController<List<Artist>> _artistsController = StreamController<List<Artist>>.broadcast();

  void emitArtists(List<Artist> newArtists) {
    artists = newArtists;
    _artistsController.add(artists);
  }

  void emitError(Object error) {
    _artistsController.addError(error);
  }

  @override
  Stream<List<Artist>> watchArtists() {
    if (artists.isNotEmpty) {
      return Stream.value(artists).concatWith([_artistsController.stream]);
    }
    return _artistsController.stream;
  }

  void dispose() {
    _artistsController.close();
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
