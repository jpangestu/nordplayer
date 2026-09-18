import 'package:flutter/foundation.dart' show immutable, listEquals;
import 'package:nordplayer/core/database/app_database.dart' show Album;
import 'package:nordplayer/core/models/track_with_artists.dart';

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
  String toString() => 'AlbumWithTracks(album: ${album.title}, tracks: ${tracks.length}, tracksLengthMs: $tracksLengthMs)';
}
