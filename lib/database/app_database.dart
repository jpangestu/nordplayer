import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import 'package:suara/database/entities.dart';

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

  Future<List<Song>> getSongs() async {
    return await select(songs).get();
  }

  Future<int> insertSong(SongsCompanion entity) async {
    return into(songs).insert(entity);
  }
}
