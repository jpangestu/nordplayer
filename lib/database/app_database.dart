import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import 'package:suara/database/entities.dart';
import 'package:suara/models/scanned_metadata.dart';
import 'package:suara/models/song.dart';

part 'app_database.g.dart';

// =============================================================================
// DATABASE CONNECTION SETUP
// =============================================================================

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbPath = await getApplicationSupportDirectory();
    final file = File(path.join(dbPath.path, 'database.sqlite'));
    return NativeDatabase.createInBackground(
      file,
      setup: (rawDb) {
        // Enable WAL (Write-Ahead Logging) Mode (Higher concurrency, less locking)
        rawDb.execute('PRAGMA journal_mode=WAL;');
        // Synchronous Normal (Faster writes, slightly less safe on power loss)
        rawDb.execute('PRAGMA synchronous=NORMAL;');
      },
    );
  });
}

// =============================================================================
// MAIN DATABASE CLASS
// =============================================================================

@DriftDatabase(tables: [Folders, Songs, Artists, Albums, SongArtists])
class Database extends _$Database {
  static final Database _instance = Database._internal();

  factory Database() {
    return _instance;
  }

  Database._internal() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // ===========================================================================
  // READ OPERATIONS (Queries)
  // ===========================================================================

  /// Returns a Map of {Path: LastModifiedTime} for the entire library.
  /// Used by the Scanner to determine which files have changed.
  Future<Map<String, int>> getPathTimestampMap() async {
    final query = select(
      songs,
    ).map((row) => MapEntry(row.path, row.lastModified));
    final result = await query.get();
    return Map.fromEntries(result);
  }

  /// Live Stream of all songs, joined with Artist and Album data.
  /// Used by the UI (Library Page).
  Stream<List<Song>> watchAllSongs() {
    // 1. Construct the Join
    //    Songs <-(artist_id)- Artists
    //    Songs <-(album_id)- Albums
    final query = select(songs).join([
      leftOuterJoin(artists, artists.id.equalsExp(songs.artistId)),
      leftOuterJoin(albums, albums.id.equalsExp(songs.albumId)),
    ]);

    // 2. Define Sort Order (A-Z by Title)
    query.orderBy([OrderingTerm(expression: songs.title)]);

    // 3. Map Rows to Domain Objects
    return query.watch().map((rows) {
      return rows.map((row) {
        final songEntry = row.readTable(songs);
        final artistEntry = row.readTable(artists);
        final albumEntry = row.readTable(albums);

        return Song(
          // Map id for navigation purposes
          id: songEntry.id,
          artistId: artistEntry.id,
          albumId: albumEntry.id,

          title: songEntry.title,
          artist: artistEntry.name,
          album: albumEntry.title,
          artPath: albumEntry.artPath, // Art comes from Album table
          year: albumEntry.year,
          trackNumber: songEntry.trackNumber,
          discNumber: songEntry.discNumber,
          duration: Duration(milliseconds: songEntry.duration),
          path: songEntry.path,
          timestamp: songEntry.lastModified,
        );
      }).toList();
    });
  }

  // ===========================================================================
  // WRITE OPERATIONS (Inserts & Deletes)
  // ===========================================================================

  /// Batch Delete: Efficiently removes songs that no longer exist on disk.
  Future<void> deleteSpecificSongs(List<String> pathsToDelete) async {
    await batch((batch) {
      batch.deleteWhere(songs, (row) => row.path.isIn(pathsToDelete));
    });
  }

  /// The Core Import Logic.
  /// Takes raw metadata -> Splits it into relational tables -> Links them.
  Future<void> insertScannedSongs(List<ScannedMetadata> metadataList) async {
    // Transaction ensures all-or-nothing (no half-saved songs)
    await transaction(() async {
      for (final meta in metadataList) {
        // --- STEP 1: Handle Album Identity ---
        // We find the album owner first to ensure the album is created correctly.
        final artistId = await _getOrCreateArtistId(meta.artist);

        final albumId = await _getOrCreateAlbumId(
          meta.album,
          artistId,
          meta.artPath, // Art is saved here
          meta.year,
        );

        // --- STEP 2: Determine Primary Artist ---
        // This is used for sorting the main song list (e.g. "Drake").
        List<String> allArtists = meta.allArtists;
        String primaryArtistName = allArtists.isNotEmpty
            ? allArtists.first
            : "Unknown";
        int primaryArtistId = await _getOrCreateArtistId(primaryArtistName);

        // --- STEP 3: Insert the Song ---
        final songCompanion = SongsCompanion(
          title: Value(meta.title),
          trackNumber: Value(meta.trackNumber),
          discNumber: Value(meta.discNumber),
          duration: Value(meta.duration.inMilliseconds),
          path: Value(meta.path),
          lastModified: Value(meta.timestamp),
          artistId: Value(primaryArtistId), // Link for Sorting
          albumId: Value(albumId), // Link for Album Art
        );

        // We capture the ID so we can use it in Step 4
        final songId = await into(songs).insert(
          songCompanion,
          // Conflict Strategy: Update existing row if Path matches
          onConflict: DoUpdate((old) => songCompanion, target: [songs.path]),
        );

        // --- STEP 4: Link Multiple Artists ---
        // Populates the Many-to-Many table (SongArtists)
        await _linkSongToArtists(songId, allArtists);
      }
    });
  }

  // ===========================================================================
  // PRIVATE HELPERS (Logic Abstractions)
  // ===========================================================================

  /// Finds an Artist by name. If missing, creates it. Returns the ID.
  Future<int> _getOrCreateArtistId(String name) async {
    final existing = await (select(
      artists,
    )..where((t) => t.name.equals(name))).getSingleOrNull();

    if (existing != null) return existing.id;

    return await into(artists).insert(ArtistsCompanion(name: Value(name)));
  }

  /// Finds an Album by Title + Artist. If missing, creates it. Returns the ID.
  Future<int> _getOrCreateAlbumId(
    String title,
    int artistId,
    String? artPath,
    int year,
  ) async {
    final existing =
        await (select(albums)..where(
              (t) => t.title.equals(title) & t.artistId.equals(artistId),
            ))
            .getSingleOrNull();

    if (existing != null) {
      // NOTE: We could update artPath here if needed in the future
      return existing.id;
    }

    return await into(albums).insert(
      AlbumsCompanion(
        title: Value(title),
        artistId: Value(artistId),
        artPath: Value(artPath),
        year: Value(year),
      ),
    );
  }

  /// Manages the "SongArtists" Junction Table.
  /// 1. Clears old links for this song.
  /// 2. Creates new links for every artist in the list.
  Future<void> _linkSongToArtists(int songId, List<String> artistNames) async {
    // 1. Wipe previous relationships (Critical for handling tag updates)
    await (delete(songArtists)..where((t) => t.songId.equals(songId))).go();

    // 2. Re-create relationships
    for (final name in artistNames) {
      final trimmedName = name.trim();
      if (trimmedName.isEmpty) continue;

      final artistId = await _getOrCreateArtistId(trimmedName);

      await into(songArtists).insert(
        SongArtistsCompanion(songId: Value(songId), artistId: Value(artistId)),
        mode: InsertMode.insertOrIgnore,
      );
    }
  }
}
