import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nordplayer/database/schema.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'app_database.g.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase(openConection());
  ref.onDispose(() => database.close());

  return database;
});

final libraryStreamProvider = StreamProvider<List<TrackWithArtists>>((ref) {
  final db = ref.watch(appDatabaseProvider);

  final query = db.select(db.tracks).join([
    leftOuterJoin(db.albums, db.albums.id.equalsExp(db.tracks.albumId)),
    leftOuterJoin(
      db.trackArtist,
      db.trackArtist.trackId.equalsExp(db.tracks.id),
    ),
    leftOuterJoin(db.artists, db.artists.id.equalsExp(db.trackArtist.artistId)),
  ]);

  // Sort title ascending
  query.orderBy([OrderingTerm.asc(db.tracks.title)]);

  // Return the stream and map the raw rows into grouped objects
  return query.watch().map((rows) {
    final Map<int, TrackWithArtists> groupedTracks = {};

    for (final row in rows) {
      final track = row.readTable(db.tracks);
      final album = row.readTable(db.albums);
      final artist = row.readTable(db.artists);

      // If track is new, create the entry
      if (!groupedTracks.containsKey(track.id)) {
        groupedTracks[track.id] = TrackWithArtists(
          track: track,
          album: album,
          artists: [],
        );
      }

      // Add the artist from this row to the artists list
      // distinct check to avoid duplicates if query logic overlaps
      final currentArtists = groupedTracks[track.id]!.artists;
      if (!currentArtists.any((a) => a.id == artist.id)) {
        currentArtists.add(artist);
      }
    }

    return groupedTracks.values.toList();
  });
});

LazyDatabase openConection() {
  return LazyDatabase(() async {
    final dbPath = await getApplicationSupportDirectory();
    final file = File(p.join(dbPath.path, 'database.sqlite'));

    return NativeDatabase.createInBackground(
      file,
      setup: (database) {
        // Enable WAL (Write-Ahead Logging) Mode (Higher concurrency, less locking)
        database.execute('PRAGMA journal_mode=WAL;');
        // Synchronous Normal (Faster writes, slightly less safe on power loss)
        database.execute('PRAGMA synchronous=NORMAL;');
      },
    );
  });
}

@DriftDatabase(tables: [Tracks, Artists, Albums, TrackArtist])
class AppDatabase extends _$AppDatabase {
  // AppDatabase._instance() : super(_openConection());
  // static final AppDatabase _singleton = AppDatabase._instance();
  // factory AppDatabase() => _singleton;

  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;
}

class TrackWithArtists {
  final Track track;
  final Album album;
  final List<Artist> artists;

  TrackWithArtists({
    required this.track,
    required this.album,
    required this.artists,
  });
}
