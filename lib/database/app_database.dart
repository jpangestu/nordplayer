import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import 'package:suara/database/entities.dart';
import 'package:suara/models/song.dart';

part 'app_database.g.dart';

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbPath = await getApplicationSupportDirectory();
    final file = File(path.join(dbPath.path, 'database.sqlite'));

    return NativeDatabase(file);
  });
}

@DriftDatabase(tables: [Songs, Folders])
class Database extends _$Database {
  static final Database _instance = Database._internal();

  factory Database() {
    return _instance;
  }

  Database._internal() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // Get database state
  /// Returns a Map of {Path: LastModifiedTime} for the entire library.
  Future<Map<String, int>> getPathTimestampMap() async {
    final query = select(songs).map((row) {
      return MapEntry(row.path, row.lastModified);
    });

    final result = await query.get();
    return Map.fromEntries(result);
  }

  /// Batch Delete
  Future<void> deleteSpecificSongs(List<String> pathsToDelete) async {
    await batch((batch) {
      batch.deleteWhere(songs, (row) => row.path.isIn(pathsToDelete));
    });
  }

  Stream<List<Song>> watchAllSongs() {
    // Sort by title as default
    return (select(songs)..orderBy([(t) => OrderingTerm(expression: t.title)]))
        .watch()
        .map((entities) {
          // Convert List<SongEntity> to List<Song>
          return entities.map((entity) {
            return Song(
              title: entity.title,
              artist: entity.artist,
              album: entity.album,
              genre: entity.genre,
              year: entity.year,
              trackNumber: entity.trackNumber,
              discNumber: entity.discNumber,
              duration: Duration(milliseconds: entity.duration),
              path: entity.path,
              artPath: entity.artPath,
              timestamp: entity.lastModified,
            );
          }).toList();
        });
  }

  Future<void> insertSongs(List<Song> allMusic) async {
    List<SongsCompanion> companions = allMusic.map((music) {
      return SongsCompanion(
        title: Value(music.title),
        artist: Value(music.artist),
        album: Value(music.album), // <--- Map these
        genre: Value(music.genre),
        year: Value(music.year),
        trackNumber: Value(music.trackNumber),
        discNumber: Value(music.discNumber),
        duration: Value(music.duration.inMilliseconds),
        path: Value(music.path),
        artPath: Value(music.artPath),
        lastModified: Value(music.timestamp),
      );
    }).toList();

    await batch((batch) {
      batch.insertAll(songs, companions, mode: InsertMode.insertOrReplace);
    });
  }
}
