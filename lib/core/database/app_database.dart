import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nordplayer/core/database/schema.dart';
import 'package:nordplayer/core/utils/directory_helper.dart';

export 'package:nordplayer/core/models/album_with_tracks.dart';
export 'package:nordplayer/core/models/library_stats.dart';
export 'package:nordplayer/core/models/playlist_with_details.dart';
export 'package:nordplayer/core/models/playlist_with_tracks.dart';
export 'package:nordplayer/core/models/track_with_artists.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Tracks,
    Artists,
    Albums,
    Playlists,
    TrackArtist,
    PlaylistTrack,
    QueueEntries,
    PlayHistory,
    SourcePriorities,
    ArtistMetadata,
    AlbumMetadata,
    UserFavorites,
    UserBlacklist,
    UserPins,
    IgnoredPaths,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) async {
        await m.createAll();
      },
      onUpgrade: (migrator, from, to) async {
        if (from < 2) {
          await migrator.addColumn(artists, artists.artistImgPath);
          await migrator.addColumn(albums, albums.albumArtistId);
          await migrator.addColumn(tracks, tracks.fileHash);
          await migrator.addColumn(tracks, tracks.audioFingerprint);
          await migrator.addColumn(tracks, tracks.isMissing);

          await migrator.createTable(playHistory);
          await migrator.createTable(sourcePriorities);
          await migrator.createTable(artistMetadata);
          await migrator.createTable(albumMetadata);
          await migrator.createTable(userFavorites);
          await migrator.createTable(userBlacklist);
          await migrator.createTable(userPins);
          await migrator.createTable(ignoredPaths);
        }
      },
    );
  }

  static QueryExecutor _openConnection() {
    // Using driftDatabase instead of nativeDatabase is the recommended way for flutter project
    return driftDatabase(
      name: 'database',
      native: DriftNativeOptions(
        // Important for enabling background task that run in isolate to access the database
        shareAcrossIsolates: true,
        databaseDirectory: getDatabaseDirectory,
        setup: (db) {
          // Enable WAL (Write-Ahead Logging) Mode (Higher concurrency, less locking)
          db.execute('PRAGMA journal_mode=WAL;');
          // Synchronous Normal (Faster writes, slightly less safe on power loss)
          db.execute('PRAGMA synchronous=NORMAL;');
        },
      ),
    );
  }

  /// Wipes all application data tables and vacuums SQLite file.
  Future<void> clearAllData() async {
    await customStatement('PRAGMA foreign_keys = OFF;');

    try {
      await transaction(() async {
        await customStatement('DELETE FROM queue_entries;');
        await customStatement('DELETE FROM playlist_track;');
        await customStatement('DELETE FROM track_artist;');

        await customStatement('DELETE FROM playlists;');
        await customStatement('DELETE FROM tracks;');
        await customStatement('DELETE FROM albums;');
        await customStatement('DELETE FROM artists;');
        await customStatement('DELETE FROM ignored_paths;');
      });

      await customStatement('PRAGMA foreign_keys = ON;');
      await customStatement('VACUUM;');
    } catch (e) {
      rethrow;
    }
  }

  /// Removes orphaned albums and artists without active track references.
  Future<void> deleteOrphanedMetadata() async {
    await transaction(() async {
      await customStatement('''
        DELETE FROM albums 
        WHERE id NOT IN (SELECT DISTINCT album_id FROM tracks WHERE album_id IS NOT NULL);
      ''');

      await customStatement('''
        DELETE FROM artists 
        WHERE id NOT IN (SELECT DISTINCT artist_id FROM tracks WHERE artist_id IS NOT NULL)
          AND id NOT IN (SELECT DISTINCT album_artist_id FROM albums WHERE album_artist_id IS NOT NULL)
          AND id NOT IN (SELECT DISTINCT artist_id FROM track_artist);
      ''');
    });
  }
}

// ================================================== Providers ========================================================

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(() => database.close());
  return database;
});

