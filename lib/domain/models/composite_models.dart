import 'package:flutter/foundation.dart';
import 'package:nordplayer/domain/models/album.dart';
import 'package:nordplayer/domain/models/artist.dart';
import 'package:nordplayer/domain/models/playlist.dart';
import 'package:nordplayer/domain/models/track.dart';

/// Composite domain entity representing a music track along with its parent album
/// and associated contributing artists.
@immutable
class TrackWithArtists {
  final Track track;
  final Album album;
  final List<Artist> artists;

  const TrackWithArtists({
    required this.track,
    required this.album,
    required this.artists,
  });

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
class AlbumWithTracks {
  final Album album;
  final List<TrackWithArtists> tracks;
  final int tracksLengthMs;

  const AlbumWithTracks({
    required this.album,
    required this.tracks,
    required this.tracksLengthMs,
  });

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
class PlaylistWithDetails {
  final Playlist playlist;
  final int trackCount;
  final List<String> imageUrls;

  const PlaylistWithDetails({
    required this.playlist,
    required this.trackCount,
    required this.imageUrls,
  });

  PlaylistWithDetails copyWith({
    Playlist? playlist,
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
class PlaylistWithTracks {
  final Playlist playlist;
  final List<TrackWithArtists> tracks;

  const PlaylistWithTracks({
    required this.playlist,
    required this.tracks,
  });

  bool get isEmpty => tracks.isEmpty;
  bool get isNotEmpty => !isEmpty;

  PlaylistWithTracks copyWith({
    Playlist? playlist,
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
