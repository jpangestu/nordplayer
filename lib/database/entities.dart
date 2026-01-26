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
  TextColumn get title => text().withDefault(const Constant('Unknown Title'))();
  TextColumn get artist => text().withDefault(const Constant('Unknown Artist'))();
  TextColumn get album => text().withDefault(const Constant(''))();
  TextColumn get genre => text().withDefault(const Constant(''))();
  IntColumn get year => integer().withDefault(const Constant(0))();
  IntColumn get trackNumber => integer().withDefault(const Constant(0))();
  IntColumn get discNumber => integer().withDefault(const Constant(0))();
  IntColumn get duration => integer().withDefault(const Constant(0))();
  TextColumn get path => text().unique()();
  TextColumn get artPath => text().nullable()();
  IntColumn get lastModified => integer().withDefault(const Constant(0))();
}
