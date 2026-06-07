import 'package:drift/drift.dart';

class Artists extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().unique()();
  TextColumn get artistImgPath => text().nullable()();
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

  /// MD5/SHA-256 chunk hash.
  TextColumn get fileHash => text().unique()();

  /// Chromaprint base64 string. Used as a fallback identity if tags change.
  TextColumn get audioFingerprint => text().nullable()();

  /// Soft-delete flag. Flips to true if file vanishes, false if rediscovered.
  BoolColumn get isMissing => boolean().withDefault(const Constant(false))();

  TextColumn get filePath => text()();
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
  DateTimeColumn get dateAdded => dateTime().withDefault(currentDateAndTime)();
}

class PlayHistory extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get trackId => integer().references(Tracks, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get startedAt => dateTime().withDefault(currentDateAndTime)();
  IntColumn get durationListenedMs => integer().withDefault(const Constant(0))();
  BoolColumn get isSkipped => boolean().withDefault(const Constant(false))();

  /// The origin of the queue (i.e. 'album', 'playlist', 'all_tracks').
  TextColumn get playbackContextType => text().nullable()();

  /// The specific database ID of the origin (i.e. Playlist ID 5, Album ID 77).
  /// Nullable because all_tracks don't have id
  IntColumn get playbackContextId => integer().nullable()();
}

/// This table is used to save the current queue state so it never gets removed when closing the app.
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

// ================================= Metadata Extension ===========================================

class SourcePriorities extends Table {
  TextColumn get source => text()(); // 'spotify', 'deezer', etc.
  IntColumn get priorityRank => integer()();

  @override
  Set<Column> get primaryKey => {source};
}

class ArtistMetadata extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get artistId => integer().references(Artists, #id, onDelete: KeyAction.cascade)();

  /// The provider type: 'spotify', 'deezer', 'custom', etc.
  TextColumn get source => text()();

  /// Remote image URL string
  TextColumn get imageUrl => text().nullable()();

  /// Relative local path for offline image caches
  TextColumn get localPath => text().nullable()();

  TextColumn get biography => text().nullable()();
  TextColumn get externalUrl => text().nullable()();
  DateTimeColumn get lastFetched => dateTime().withDefault(currentDateAndTime)();

  /// True if the user manually pinned this provider's image/bio as active
  BoolColumn get isUserSelected => boolean().withDefault(const Constant(false))();

  @override
  List<Set<Column>> get uniqueKeys => [
    {artistId, source},
  ];
}

class AlbumMetadata extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get albumId => integer().references(Albums, #id, onDelete: KeyAction.cascade)();

  /// The source type: 'spotify', 'deezer', or 'custom'
  TextColumn get source => text()();

  /// Web URL fallback. Null if source is 'custom'.
  TextColumn get albumArtUrl => text().nullable()();

  /// **Crucial:** Null if source is 'custom' because the art is embedded in the audio files.
  TextColumn get localPath => text().nullable()();

  TextColumn get releaseType => text().nullable()();
  IntColumn get popularity => integer().nullable()();
  BoolColumn get isUserSelected => boolean().withDefault(const Constant(false))();

  @override
  List<Set<Column>> get uniqueKeys => [
    {albumId, source},
  ];
}

// ====================================== User Tags ===============================================

class UserFavorites extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get trackId => integer().nullable().references(Tracks, #id, onDelete: KeyAction.cascade)();
  IntColumn get albumId => integer().nullable().references(Albums, #id, onDelete: KeyAction.cascade)();
  IntColumn get artistId => integer().nullable().references(Artists, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get dateAdded => dateTime().withDefault(currentDateAndTime)();

  @override
  List<String> get customConstraints => [
    '''CHECK (
      (track_id IS NOT NULL AND album_id IS NULL AND artist_id IS NULL) OR
      (track_id IS NULL AND album_id IS NOT NULL AND artist_id IS NULL) OR
      (track_id IS NULL AND album_id IS NULL AND artist_id IS NOT NULL)
    )''',
  ];
}

class UserBlacklist extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get trackId => integer().nullable().references(Tracks, #id, onDelete: KeyAction.cascade)();
  IntColumn get albumId => integer().nullable().references(Albums, #id, onDelete: KeyAction.cascade)();
  IntColumn get artistId => integer().nullable().references(Artists, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get dateAdded => dateTime().withDefault(currentDateAndTime)();

  @override
  List<String> get customConstraints => [
    '''CHECK (
      (track_id IS NOT NULL AND album_id IS NULL AND artist_id IS NULL) OR
      (track_id IS NULL AND album_id IS NOT NULL AND artist_id IS NULL) OR
      (track_id IS NULL AND album_id IS NULL AND artist_id IS NOT NULL)
    )''',
  ];
}

class UserPins extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get trackId => integer().nullable().references(Tracks, #id, onDelete: KeyAction.cascade)();
  IntColumn get albumId => integer().nullable().references(Albums, #id, onDelete: KeyAction.cascade)();
  IntColumn get artistId => integer().nullable().references(Artists, #id, onDelete: KeyAction.cascade)();
  IntColumn get playlistId => integer().nullable().references(Playlists, #id, onDelete: KeyAction.cascade)();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  List<String> get customConstraints => [
    '''CHECK (
      (track_id IS NOT NULL AND album_id IS NULL AND artist_id IS NULL AND playlist_id IS NULL) OR
      (track_id IS NULL AND album_id IS NOT NULL AND artist_id IS NULL AND playlist_id IS NULL) OR
      (track_id IS NULL AND album_id IS NULL AND artist_id IS NOT NULL AND playlist_id IS NULL) OR
      (track_id IS NULL AND album_id IS NULL AND artist_id IS NULL AND playlist_id IS NOT NULL)
    )''',
  ];
}
