import 'package:flutter/foundation.dart' show immutable, listEquals;
import 'package:nordplayer/core/database/app_database.dart' show Album, Artist, PlaylistData, Track;

/// Composite domain entity representing a music track along with its parent album
/// and associated contributing artists.
@immutable
class const TrackWithArtists({
  required final Track track,
  required final Album album,
  required final List<Artist> artists,
}) {
  /// Helper to check whether this object is empty.
  /// A track is considered empty if it has no valid database ID and an empty file path.
  bool get isEmpty => track.id == 0 || track.filePath.isEmpty;

  bool get isNotEmpty => !isEmpty;

  TrackWithArtists copyWith({
    Track? track,
    Album? album,
    List<Artist>? artists,
  }) {
    return TrackWithArtists(
      track: track ?? this.track,
      album: album ?? this.album,
      artists: artists ?? this.artists,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrackWithArtists &&
          runtimeType == other.runtimeType &&
          track == other.track &&
          album == other.album &&
          listEquals(artists, other.artists);

  @override
  int get hashCode => Object.hash(track, album, Object.hashAll(artists));

  @override
  String toString() =>
      'TrackWithArtists(track: ${track.id}, album: ${album.title}, artists: ${artists.map((a) => a.name).toList()})';
}

/// Composite domain entity representing an album with its associated tracks
/// and cumulative playback duration.
@immutable
class const AlbumWithTracks({
  required final Album album,
  required final List<TrackWithArtists> tracks,
  required final int tracksLengthMs,
}) {
  AlbumWithTracks copyWith({
    Album? album,
    List<TrackWithArtists>? tracks,
    int? tracksLengthMs,
  }) {
    return AlbumWithTracks(
      album: album ?? this.album,
      tracks: tracks ?? this.tracks,
      tracksLengthMs: tracksLengthMs ?? this.tracksLengthMs,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlbumWithTracks &&
          runtimeType == other.runtimeType &&
          album == other.album &&
          tracksLengthMs == other.tracksLengthMs &&
          listEquals(tracks, other.tracks);

  @override
  int get hashCode => Object.hash(album, tracksLengthMs, Object.hashAll(tracks));

  @override
  String toString() =>
      'AlbumWithTracks(album: ${album.title}, tracks: ${tracks.length}, tracksLengthMs: $tracksLengthMs)';
}

/// Composite domain entity representing a playlist with its aggregate track count
/// and a preview collage of album cover paths.
@immutable
class const PlaylistWithDetails({
  required final PlaylistData playlist,
  required final int trackCount,
  required final List<String> imageUrls,
}) {
  PlaylistWithDetails copyWith({
    PlaylistData? playlist,
    int? trackCount,
    List<String>? imageUrls,
  }) {
    return PlaylistWithDetails(
      playlist: playlist ?? this.playlist,
      trackCount: trackCount ?? this.trackCount,
      imageUrls: imageUrls ?? this.imageUrls,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlaylistWithDetails &&
          runtimeType == other.runtimeType &&
          playlist == other.playlist &&
          trackCount == other.trackCount &&
          listEquals(imageUrls, other.imageUrls);

  @override
  int get hashCode => Object.hash(playlist, trackCount, Object.hashAll(imageUrls));

  @override
  String toString() =>
      'PlaylistWithDetails(playlist: ${playlist.name}, trackCount: $trackCount, covers: ${imageUrls.length})';
}

/// Composite domain entity representing a playlist and its fully-resolved ordered track list.
@immutable
class const PlaylistWithTracks({
  required final PlaylistData playlist,
  required final List<TrackWithArtists> tracks,
}) {
  bool get isEmpty => tracks.isEmpty;
  bool get isNotEmpty => !isEmpty;

  PlaylistWithTracks copyWith({
    PlaylistData? playlist,
    List<TrackWithArtists>? tracks,
  }) {
    return PlaylistWithTracks(
      playlist: playlist ?? this.playlist,
      tracks: tracks ?? this.tracks,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlaylistWithTracks &&
          runtimeType == other.runtimeType &&
          playlist == other.playlist &&
          listEquals(tracks, other.tracks);

  @override
  int get hashCode => Object.hash(playlist, Object.hashAll(tracks));

  @override
  String toString() => 'PlaylistWithTracks(playlist: ${playlist.name}, tracks: ${tracks.length})';
}

/// Aggregate library statistics including total counts, storage size, and playtime.
@immutable
class const LibraryStats({
  required final int trackCount,
  required final int albumCount,
  required final int artistCount,
  required final int playlistCount,
  required final int genreCount,
  required final int totalSizeBytes,
  required final int totalPlaytimeMs,
}) {
  const new empty()
      : this(
          trackCount: 0,
          albumCount: 0,
          artistCount: 0,
          playlistCount: 0,
          genreCount: 0,
          totalSizeBytes: 0,
          totalPlaytimeMs: 0,
        );

  LibraryStats copyWith({
    int? trackCount,
    int? albumCount,
    int? artistCount,
    int? playlistCount,
    int? genreCount,
    int? totalSizeBytes,
    int? totalPlaytimeMs,
  }) {
    return LibraryStats(
      trackCount: trackCount ?? this.trackCount,
      albumCount: albumCount ?? this.albumCount,
      artistCount: artistCount ?? this.artistCount,
      playlistCount: playlistCount ?? this.playlistCount,
      genreCount: genreCount ?? this.genreCount,
      totalSizeBytes: totalSizeBytes ?? this.totalSizeBytes,
      totalPlaytimeMs: totalPlaytimeMs ?? this.totalPlaytimeMs,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LibraryStats &&
          runtimeType == other.runtimeType &&
          trackCount == other.trackCount &&
          albumCount == other.albumCount &&
          artistCount == other.artistCount &&
          playlistCount == other.playlistCount &&
          genreCount == other.genreCount &&
          totalSizeBytes == other.totalSizeBytes &&
          totalPlaytimeMs == other.totalPlaytimeMs;

  @override
  int get hashCode => Object.hash(
        trackCount,
        albumCount,
        artistCount,
        playlistCount,
        genreCount,
        totalSizeBytes,
        totalPlaytimeMs,
      );

  @override
  String toString() {
    return 'LibraryStats(trackCount: $trackCount, albumCount: $albumCount, artistCount: $artistCount, '
        'playlistCount: $playlistCount, genreCount: $genreCount, totalSizeBytes: $totalSizeBytes, totalPlaytimeMs: $totalPlaytimeMs)';
  }
}
