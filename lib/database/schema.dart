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
  IntColumn get trackId => integer().references(Tracks, #id, onDelete: KeyAction.cascade)();
  IntColumn get artistId => integer().references(Artists, #id, onDelete: KeyAction.cascade)();

  @override
  Set<Column> get primaryKey => {trackId, artistId};
}

class PlaylistTrack extends Table {
  IntColumn get playlistId => integer().references(Playlists, #id, onDelete: KeyAction.cascade)();
  IntColumn get trackId => integer().references(Tracks, #id, onDelete: KeyAction.cascade)();
}

/// This table is used to save the current queue state so it never get removed when closing the app.
class QueueEntries extends Table {
  /// The pure, unshuffled position of the track in the original list.
  /// Fall back to this when the user clicks "Unshuffle".
  IntColumn get originalQueueIndex => integer()();

  /// Foreign key linking to the `Tracks` metadata table.
  IntColumn get trackId => integer().references(Tracks, #id)();

  /// Flags the single track that was actively playing when the app was last closed.
  BoolColumn get isCurrentlyPlaying => boolean().withDefault(const Constant(false))();

  /// The exact timestamp (in milliseconds) to resume playback from on the active track.
  IntColumn get resumePositionMs => integer().withDefault(const Constant(0))();

  /// The origin of the queue (i.e. 'album', 'playlist', 'all_tracks').
  TextColumn get playbackContextType => text()();

  /// The specific database ID of the origin (i.e. Playlist ID 5, Album ID 77).
  /// Nullable because all_tracks don't have id
  IntColumn get playbackContextId => integer().nullable()();

  @override
  Set<Column> get primaryKey => {originalQueueIndex};
}
