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

  /// The database ID of the solo album artist (fallback to the track's primary artist if the albumArtist is empty).
  /// Set to null for compilation albums or multi-artist releases to avoid database clutter in the artists table.
  IntColumn get albumArtistId => integer().nullable().references(Artists, #id)();
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

  /// FNV-1a hash.
  TextColumn get fileHash => text()();

  /// Chromaprint raw fingerprint stored as binary blob (Uint32List bytes).
  BlobColumn get audioFingerprint => blob().nullable()();

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

/// Single-row table persisting active player session, playback position, and context.
class PlaybackSessions extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();

  /// Foreign key linking to the active Track in the Tracks table.
  IntColumn get activeTrackId => integer().nullable().references(Tracks, #id, onDelete: KeyAction.setNull)();

  /// Active track absolute file path (cached for fast engine open).
  TextColumn get activeTrackPath => text().nullable()();

  /// Active queue index.
  IntColumn get activeIndex => integer().withDefault(const Constant(0))();

  /// Playback position in milliseconds.
  IntColumn get positionMs => integer().withDefault(const Constant(0))();

  /// Context type identifier ('album', 'playlist', 'all_tracks', 'search', 'manual').
  TextColumn get playbackContextType => text().withDefault(const Constant('manual'))();

  /// Associated collection database ID (e.g. Playlist ID or Album ID).
  IntColumn get playbackContextId => integer().nullable()();

  /// Associated collection title or search query for UI header display.
  TextColumn get playbackContextTitle => text().nullable()();

  /// Whether shuffle is active.
  BoolColumn get isShuffle => boolean().withDefault(const Constant(false))();

  /// Permutation map serialized as JSON (e.g. "[0, 3, 1, 2]") when shuffle is active.
  TextColumn get shuffleIndicesJson => text().nullable()();

  /// Active loop mode ('off', 'all', 'single').
  TextColumn get loopMode => text().withDefault(const Constant('off'))();

  /// Last updated timestamp.
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Normalized queue entries table storing current sequence, original sequence, and item source tier.
@TableIndex(name: 'idx_queue_entries_sort_order', columns: {#sortOrder})
@TableIndex(name: 'idx_queue_entries_track_id', columns: {#trackId})
class QueueEntries extends Table {
  /// Unique identifier (UUID string) corresponding to QueueItem.id.
  TextColumn get id => text()();

  /// Foreign key linking to the Tracks metadata table.
  IntColumn get trackId => integer().references(Tracks, #id, onDelete: KeyAction.cascade)();

  /// Active sequence index in the queue.
  IntColumn get sortOrder => integer()();

  /// The original unshuffled/context index for reverting or un-shuffling.
  IntColumn get originalOrder => integer()();

  /// Origin tier ('context', 'userNext', 'userQueue').
  TextColumn get source => text().withDefault(const Constant('context'))();

  /// Timestamp when this item was added to the queue.
  DateTimeColumn get addedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
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

class IgnoredPaths extends Table {
  TextColumn get filePath => text()();
  DateTimeColumn get dateAdded => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {filePath};
}
