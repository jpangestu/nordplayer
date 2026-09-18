import 'package:flutter/foundation.dart' show immutable, listEquals;
import 'package:nordplayer/core/database/app_database.dart' show PlaylistData;
import 'package:nordplayer/core/models/track_with_artists.dart';

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
