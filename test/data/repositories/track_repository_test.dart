import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nordplayer/core/database/app_database.dart';
import 'package:nordplayer/data/repositories/repositories.dart';

void main() {
  late AppDatabase db;
  late TrackRepository trackRepository;
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

    trackRepository = container.read(trackRepositoryProvider);

    // Seed test data
    // 1. Create Artists
    await db.into(db.artists).insert(ArtistsCompanion.insert(id: const Value(1), name: 'Artist A'));
    await db.into(db.artists).insert(ArtistsCompanion.insert(id: const Value(2), name: 'Artist B'));

    // 2. Create Album
    await db.into(db.albums).insert(
          AlbumsCompanion.insert(
            id: const Value(1),
            title: 'Album One',
            albumArtPath: const Value('/art/album1.jpg'),
          ),
        );

    // 3. Create Tracks
    await db.into(db.tracks).insert(
          TracksCompanion.insert(
            id: const Value(1),
            title: 'Zeta Track',
            filePath: '/music/zeta.mp3',
            fileHash: 'hash_zeta',
            artistId: 1,
            albumId: 1,
            durationMs: const Value(180000),
            fileSize: const Value(5000000),
            genre: const Value('Rock'),
            dateAdded: Value(DateTime.now().subtract(const Duration(days: 2))),
          ),
        );

    await db.into(db.tracks).insert(
          TracksCompanion.insert(
            id: const Value(2),
            title: 'Alpha Track',
            filePath: '/music/alpha.mp3',
            fileHash: 'hash_alpha',
            artistId: 1,
            albumId: 1,
            durationMs: const Value(240000),
            fileSize: const Value(7000000),
            genre: const Value('Pop'),
            dateAdded: Value(DateTime.now()),
          ),
        );

    // Missing track
    await db.into(db.tracks).insert(
          TracksCompanion.insert(
            id: const Value(3),
            title: 'Missing Track',
            filePath: '/music/missing.mp3',
            fileHash: 'hash_missing',
            artistId: 1,
            albumId: 1,
            durationMs: const Value(120000),
            fileSize: const Value(3000000),
            isMissing: const Value(true),
            dateAdded: Value(DateTime.now()),
          ),
        );

    // 4. Link Track Artists
    await db.into(db.trackArtist).insert(TrackArtistCompanion.insert(trackId: 1, artistId: 1));
    await db.into(db.trackArtist).insert(TrackArtistCompanion.insert(trackId: 1, artistId: 2));
    await db.into(db.trackArtist).insert(TrackArtistCompanion.insert(trackId: 2, artistId: 1));
  });

  tearDown(() async {
    await db.close();
    container.dispose();
  });

  group('TrackRepository Tests', () {
    test('watchAllTracks returns non-missing tracks ordered alphabetically by title', () async {
      final tracks = await trackRepository.watchAllTracks().first;

      expect(tracks.length, 2);
      expect(tracks[0].track.title, 'Alpha Track');
      expect(tracks[0].artists.length, 1);
      expect(tracks[0].artists.first.name, 'Artist A');

      expect(tracks[1].track.title, 'Zeta Track');
      expect(tracks[1].artists.length, 2);
      expect(tracks[1].artists.map((a) => a.name).toSet(), {'Artist A', 'Artist B'});
    });

    test('getTrackById returns track with album and artists if found', () async {
      final track = await trackRepository.getTrackById(1);

      expect(track, isNotNull);
      expect(track!.track.title, 'Zeta Track');
      expect(track.album.title, 'Album One');
      expect(track.artists.length, 2);

      final notFound = await trackRepository.getTrackById(999);
      expect(notFound, isNull);
    });

    test('watchRecentlyAddedTracks returns tracks ordered newest first', () async {
      final recent = await trackRepository.watchRecentlyAddedTracks(limitAmount: 5).first;

      expect(recent.length, 2);
      expect(recent[0].track.title, 'Alpha Track'); // Newer
      expect(recent[1].track.title, 'Zeta Track'); // Older
    });

    test('watchLibraryStats aggregates statistics correctly', () async {
      final stats = await trackRepository.watchLibraryStats().first;

      expect(stats.trackCount, 2); // Excludes missing track
      expect(stats.albumCount, 1);
      expect(stats.artistCount, 2);
      expect(stats.genreCount, 2);
      expect(stats.totalSizeBytes, 12000000); // 5M + 7M
      expect(stats.totalPlaytimeMs, 420000); // 180k + 240k
    });

    test('searchTracks matches track title, album title, and artist name', () async {
      // Search by track title
      final byTitle = await trackRepository.searchTracks('Alpha').first;
      expect(byTitle.length, 1);
      expect(byTitle.first.track.title, 'Alpha Track');

      // Search by album title
      final byAlbum = await trackRepository.searchTracks('Album').first;
      expect(byAlbum.length, 2);

      // Search by artist name
      final byArtist = await trackRepository.searchTracks('Artist B').first;
      expect(byArtist.length, 1);
      expect(byArtist.first.track.title, 'Zeta Track');
    });

    test('clearAllData wipes all tables', () async {
      await trackRepository.clearAllData();

      final tracks = await trackRepository.watchAllTracks().first;
      expect(tracks, isEmpty);

      final stats = await trackRepository.watchLibraryStats().first;
      expect(stats.trackCount, 0);
    });
  });
}
