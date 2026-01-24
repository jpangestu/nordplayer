import 'package:drift/drift.dart';

class Songs extends Table {
  IntColumn get songId => integer().autoIncrement().named('song_id')();
  TextColumn get title => text()();
  TextColumn get path => text()();
}