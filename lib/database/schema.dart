import 'package:drift/drift.dart';

class Artists extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().unique()();
}

class Albums extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  IntColumn get year => integer().withDefault(const Constant(0))();
  TextColumn get albumArtist => text().nullable()();
  TextColumn get albumArtPath => text().nullable()();
  IntColumn get artistId => integer().references(Artists, #id)();
}

class Tracks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  IntColumn get trackNumber => integer().withDefault(const Constant(0))();
  IntColumn get trackTotal => integer().withDefault(const Constant(0))();
  IntColumn get discNumber => integer().withDefault(const Constant(0))();
  IntColumn get discTotal => integer().withDefault(const Constant(0))();
  IntColumn get durationMs => integer().withDefault(const Constant(0))();
  TextColumn get genre => text().nullable()();
  TextColumn get filePath => text().unique()();
  IntColumn get fileSize => integer().withDefault(const Constant(0))();
  IntColumn get artistId => integer().references(Artists, #id)();
  IntColumn get albumId => integer().references(Albums, #id)();
  DateTimeColumn get dateAdded => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('PlaylistData')
class Playlists extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get coverPath => text().nullable()();
}

class TrackArtist extends Table {
  IntColumn get trackId =>
      integer().references(Tracks, #id, onDelete: KeyAction.cascade)();
  IntColumn get artistId =>
      integer().references(Artists, #id, onDelete: KeyAction.cascade)();

  @override
  Set<Column> get primaryKey => {trackId, artistId};
}

class PlaylistTrack extends Table {
  IntColumn get playlistId =>
      integer().references(Playlists, #id, onDelete: KeyAction.cascade)();
  IntColumn get trackId =>
      integer().references(Tracks, #id, onDelete: KeyAction.cascade)();
}
