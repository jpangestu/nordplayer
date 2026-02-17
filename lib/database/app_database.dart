import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:nordplayer/database/schema.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'app_database.g.dart';

LazyDatabase _openConection() {
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
  AppDatabase._instance() : super(_openConection());
  static final AppDatabase _singleton = AppDatabase._instance();
  factory AppDatabase() => _singleton;

  @override
  int get schemaVersion => 1;

  Stream<List<SongWithArtists>> watchLibrary() {
    final query = select(tracks).join([
      leftOuterJoin(albums, albums.id.equalsExp(tracks.albumId)),
      leftOuterJoin(trackArtist, trackArtist.trackId.equalsExp(tracks.id)),
      leftOuterJoin(artists, artists.id.equalsExp(trackArtist.artistId)),
    ]);

    query.orderBy([OrderingTerm.asc(tracks.title)]);

    return query.watch().map((rows) {
      // Use a Map to group rows by Track ID to handle duplicates
      final Map<int, SongWithArtists> groupedSongs = {};

      for (final row in rows) {
        final track = row.readTable(tracks);
        final album = row.readTable(albums);
        final artist = row.readTable(artists);

        // If track is new, create the entry
        if (!groupedSongs.containsKey(track.id)) {
          groupedSongs[track.id] = SongWithArtists(
            track: track,
            album: album,
            artists: [],
          );
        }

        // Add the artist from this row to the list
        // distinct check to avoid duplicates if query logic overlaps
        final currentList = groupedSongs[track.id]!.artists;
        if (!currentList.any((a) => a.id == artist.id)) {
          currentList.add(artist);
        }
      }

      return groupedSongs.values.toList();
    });
  }
}

class SongWithArtists {
  final Track track;
  final Album album;
  final List<Artist> artists;

  SongWithArtists({
    required this.track,
    required this.album,
    required this.artists,
  });
}
