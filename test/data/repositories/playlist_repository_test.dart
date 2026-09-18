import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nordplayer/core/database/app_database.dart';
import 'package:nordplayer/data/repositories/repositories.dart';

void main() {
  late AppDatabase db;
  late PlaylistRepository playlistRepository;
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

    playlistRepository = container.read(playlistRepositoryProvider);

    // Seed test data
    await db.into(db.artists).insert(ArtistsCompanion.insert(id: const Value(1), name: 'Artist X'));

    await db.into(db.albums).insert(
          AlbumsCompanion.insert(
            id: const Value(1),
            title: 'Album X',
            albumArtPath: const Value('/art/x.jpg'),
          ),
        );

    await db.into(db.tracks).insert(
          TracksCompanion.insert(
            id: const Value(10),
            title: 'Track 10',
            filePath: '/music/track10.mp3',
            fileHash: 'hash_track10',
            artistId: 1,
            albumId: 1,
            durationMs: const Value(150000),
            fileSize: const Value(3000000),
          ),
        );
    await db.into(db.tracks).insert(
          TracksCompanion.insert(
            id: const Value(20),
            title: 'Track 20',
            filePath: '/music/track20.mp3',
            fileHash: 'hash_track20',
            artistId: 1,
            albumId: 1,
            durationMs: const Value(180000),
            fileSize: const Value(4000000),
          ),
        );

    await db.into(db.trackArtist).insert(TrackArtistCompanion.insert(trackId: 10, artistId: 1));
    await db.into(db.trackArtist).insert(TrackArtistCompanion.insert(trackId: 20, artistId: 1));
  });

  tearDown(() async {
    await db.close();
    container.dispose();
  });

  group('PlaylistRepository Tests', () {
    test('createPlaylist creates playlist and adds initial tracks atomically', () async {
      final playlistId = await playlistRepository.createPlaylist(
        'My Favorites',
        trackIds: [10, 20],
      );

      expect(playlistId, greaterThan(0));

      final playlists = await playlistRepository.watchAllPlaylists().first;
      expect(playlists.length, 1);
      expect(playlists.first.playlist.name, 'My Favorites');
      expect(playlists.first.trackCount, 2);
      expect(playlists.first.imageUrls, contains('/art/x.jpg'));

      final tracks = await playlistRepository.getPlaylistTracks(playlistId);
      expect(tracks.length, 2);
      expect(tracks.map((t) => t.track.id).toList(), [10, 20]);
    });

    test('renamePlaylist updates playlist name', () async {
      final playlistId = await playlistRepository.createPlaylist('Old Name');
      await playlistRepository.renamePlaylist(playlistId, 'New Name');

      final playlist = await playlistRepository.watchPlaylist(playlistId).first;
      expect(playlist.name, 'New Name');
    });

    test('addTracksToPlaylist and removeTrackFromPlaylist modify track list', () async {
      final playlistId = await playlistRepository.createPlaylist('Workout');

      await playlistRepository.addTracksToPlaylist(playlistId, [10, 20]);
      var tracks = await playlistRepository.getPlaylistTracks(playlistId);
      expect(tracks.length, 2);

      await playlistRepository.removeTrackFromPlaylist(playlistId, 10);
      tracks = await playlistRepository.getPlaylistTracks(playlistId);
      expect(tracks.length, 1);
      expect(tracks.first.track.id, 20);
    });

    test('deletePlaylist removes playlist from database', () async {
      final playlistId = await playlistRepository.createPlaylist('Temporary');
      await playlistRepository.deletePlaylist(playlistId);

      final playlists = await playlistRepository.watchAllPlaylists().first;
      expect(playlists, isEmpty);
    });
  });
}
