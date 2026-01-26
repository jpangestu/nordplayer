import 'package:drift/drift.dart';

@DataClassName('MusicFolder')
class Folders extends Table {
  TextColumn get path => text().unique()();
  IntColumn get lastScanned => integer().withDefault(const Constant(0))();
  BoolColumn get isEnabled => boolean().withDefault(const Constant(true))();
}

@DataClassName('SongEntity')
class Songs extends Table {
  IntColumn get songId => integer().autoIncrement().named('song_id')();
  TextColumn get title => text()();
  TextColumn get artist => text()();
  TextColumn get path => text().unique()();
  IntColumn get duration => integer().withDefault(const Constant(0))();
  IntColumn get lastModified => integer().withDefault(const Constant(0))();
}
