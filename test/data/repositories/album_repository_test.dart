import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nordplayer/core/database/app_database.dart';
import 'package:nordplayer/data/repositories/album_repository.dart';

void main() {
  late AppDatabase db;
  late AlbumRepository albumRepository;
  late ProviderContainer container;

  setUp(() async {
    db = AppDatabase(
      NativeDatabase.memory(
        setup: (database) {
          database.execute('PRAGMA foreign_keys = ON;');
        },
      ),
    );

    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
      ],
    );

    albumRepository = container.read(albumRepositoryProvider);

    // Seed test data
    await db.into(db.artists).insert(ArtistsCompanion.insert(id: const Value(1), name: 'Artist One'));
    await db.into(db.artists).insert(ArtistsCompanion.insert(id: const Value(2), name: 'Artist Two'));

    await db.into(db.albums).insert(
          AlbumsCompanion.insert(
            id: const Value(1),
            title: 'Beatles Album',
            albumArtPath: const Value('/art/beatles.jpg'),
          ),
        );
    await db.into(db.albums).insert(
          AlbumsCompanion.insert(
            id: const Value(2),
            title: 'Empty Album',
            albumArtPath: const Value('/art/empty.jpg'),
          ),
        );

    // Tracks for Album 1
    await db.into(db.tracks).insert(
          TracksCompanion.insert(
            id: const Value(1),
            title: 'Song A',
            filePath: '/music/song_a.mp3',
            fileHash: 'hash_song_a',
            artistId: 1,
            albumId: 1,
            trackNumber: const Value(1),
            durationMs: const Value(200000),
            fileSize: const Value(4000000),
          ),
        );
    await db.into(db.tracks).insert(
          TracksCompanion.insert(
            id: const Value(2),
            title: 'Song B',
            filePath: '/music/song_b.mp3',
            fileHash: 'hash_song_b',
            artistId: 2,
            albumId: 1,
            trackNumber: const Value(2),
            durationMs: const Value(300000),
            fileSize: const Value(6000000),
          ),
        );

    await db.into(db.trackArtist).insert(TrackArtistCompanion.insert(trackId: 1, artistId: 1));
    await db.into(db.trackArtist).insert(TrackArtistCompanion.insert(trackId: 2, artistId: 2));
  });

  tearDown(() async {
    await db.close();
    container.dispose();
  });

  group('AlbumRepository Tests', () {
    test('watchAlbums returns only albums containing non-missing tracks', () async {
      final albums = await albumRepository.watchAlbums().first;

      expect(albums.length, 1);
      expect(albums.first.title, 'Beatles Album');
    });

    test('watchAlbumWithTracks returns album with grouped tracks and total duration', () async {
      final albumWithTracks = await albumRepository.watchAlbumWithTracks(1).first;

      expect(albumWithTracks, isNotNull);
      expect(albumWithTracks!.album.title, 'Beatles Album');
      expect(albumWithTracks.tracks.length, 2);
      expect(albumWithTracks.tracks[0].track.title, 'Song A');
      expect(albumWithTracks.tracks[1].track.title, 'Song B');
      expect(albumWithTracks.tracksLengthMs, 500000); // 200k + 300k
    });

    test('getTrackArtists returns distinct artists featured on album', () async {
      final artists = await albumRepository.getTrackArtists(albumId: 1);

      expect(artists.length, 2);
      expect(artists.map((a) => a.name).toSet(), {'Artist One', 'Artist Two'});
    });

    test('getRandomAlbums returns non-empty albums within limit', () async {
      final random = await albumRepository.getRandomAlbums(limitAmount: 5);

      expect(random.length, 1);
      expect(random.first.title, 'Beatles Album');
    });
  });
}
