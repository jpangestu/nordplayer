import 'package:drift/drift.dart';

// Avoid naming conflict between song entity and song domain (from model)
@DataClassName('SongEntity')
class Songs extends Table {
  IntColumn get songId => integer().autoIncrement().named('song_id')();
  TextColumn get title => text()();
  TextColumn get artist => text()();
  TextColumn get path => text().unique()();
  IntColumn get duration => integer().withDefault(const Constant(0))();
}