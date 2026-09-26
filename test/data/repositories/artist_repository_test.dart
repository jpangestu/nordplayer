import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nordplayer/data/database/app_database.dart';
import 'package:nordplayer/data/repositories/artist_repository.dart';

void main() {
  late AppDatabase db;
  late ArtistRepository artistRepository;
  late ProviderContainer container;

  setUp(() async {
    db = AppDatabase(
      NativeDatabase.memory(
        setup: (database) {
          database.execute('PRAGMA foreign_keys = ON;');
        },
      ),
    );

    container = ProviderContainer(overrides: [appDatabaseProvider.overrideWithValue(db)]);

    artistRepository = container.read(artistRepositoryProvider);

    // Seed test data
    await db.into(db.artists).insert(ArtistsCompanion.insert(id: const Value(1), name: 'Zebra Band'));
    await db.into(db.artists).insert(ArtistsCompanion.insert(id: const Value(2), name: 'Alpha Artist'));
    await db.into(db.artists).insert(ArtistsCompanion.insert(id: const Value(3), name: 'beta artist'));
    await db.into(db.artists).insert(ArtistsCompanion.insert(id: const Value(4), name: 'Empty Artist'));
    await db.into(db.artists).insert(ArtistsCompanion.insert(id: const Value(5), name: 'Missing Track Artist'));

    // Seed test album
    await db.into(db.albums).insert(AlbumsCompanion.insert(id: const Value(1), title: 'Test Album'));

    // Tracks
    await db
        .into(db.tracks)
        .insert(
          TracksCompanion.insert(
            id: const Value(1),
            title: 'Track 1',
            filePath: '/music/track1.mp3',
            fileHash: 'hash_1',
            artistId: 1,
            albumId: 1,
            isMissing: const Value(false),
          ),
        );
    await db
        .into(db.tracks)
        .insert(
          TracksCompanion.insert(
            id: const Value(2),
            title: 'Track 2',
            filePath: '/music/track2.mp3',
            fileHash: 'hash_2',
            artistId: 2,
            albumId: 1,
            isMissing: const Value(false),
          ),
        );
    await db
        .into(db.tracks)
        .insert(
          TracksCompanion.insert(
            id: const Value(3),
            title: 'Track 3',
            filePath: '/music/track3.mp3',
            fileHash: 'hash_3',
            artistId: 3,
            albumId: 1,
            isMissing: const Value(false),
          ),
        );
    await db
        .into(db.tracks)
        .insert(
          TracksCompanion.insert(
            id: const Value(4),
            title: 'Missing Track',
            filePath: '/music/missing.mp3',
            fileHash: 'hash_missing',
            artistId: 5,
            albumId: 1,
            isMissing: const Value(true),
          ),
        );

    // Track artist links
    await db.into(db.trackArtist).insert(TrackArtistCompanion.insert(trackId: 1, artistId: 1));
    await db.into(db.trackArtist).insert(TrackArtistCompanion.insert(trackId: 2, artistId: 2));
    await db.into(db.trackArtist).insert(TrackArtistCompanion.insert(trackId: 3, artistId: 3));
    await db.into(db.trackArtist).insert(TrackArtistCompanion.insert(trackId: 4, artistId: 5));
  });

  tearDown(() async {
    await db.close();
    container.dispose();
  });

  group('ArtistRepository Tests', () {
    test('watchArtists returns only artists with non-missing tracks, ordered alphabetically', () async {
      final artists = await artistRepository.watchArtists().first;

      expect(artists.length, 3);
      // Case-insensitive ordering: Alpha Artist, beta artist, Zebra Band
      expect(artists[0].name, 'Alpha Artist');
      expect(artists[1].name, 'beta artist');
      expect(artists[2].name, 'Zebra Band');
    });

    test('watchArtists excludes artists without tracks or with only missing tracks', () async {
      final artists = await artistRepository.watchArtists().first;
      final names = artists.map((a) => a.name).toSet();

      expect(names, isNot(contains('Empty Artist')));
      expect(names, isNot(contains('Missing Track Artist')));
    });

    test('artistRepositoryProvider resolves through container', () async {
      final artists = await container.read(artistRepositoryProvider).watchArtists().first;

      expect(artists.length, 3);
      expect(artists.map((a) => a.name).toList(), ['Alpha Artist', 'beta artist', 'Zebra Band']);
    });
  });
}
