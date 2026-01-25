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

@DriftDatabase(tables: [Songs])
class Database extends _$Database {
  static final Database _instance = Database._internal();

  factory Database() {
    return _instance;
  }

  Database._internal() : super(_openConnection());

  @override
  int get schemaVersion => 2;

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
              path: entity.path,
              duration: Duration(milliseconds: entity.duration),
            );
          }).toList();
        });
  }

  Future<void> insertSongs(List<Song> allMusic) async {
    List<SongsCompanion> companions = allMusic.map((music) {
      return SongsCompanion(
        title: Value(music.title),
        artist: Value(music.artist),
        path: Value(music.path),
        duration: Value(music.duration?.inMilliseconds ?? 0),
      );
    }).toList();

    await batch((batch) {
      batch.insertAll(songs, companions, mode: InsertMode.insertOrReplace);
    });
  }
}
