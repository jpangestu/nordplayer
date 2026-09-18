import 'package:flutter/foundation.dart' show immutable, listEquals;
import 'package:nordplayer/core/database/app_database.dart' show Track, Album, Artist;

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
  String toString() => 'TrackWithArtists(track: ${track.id}, album: ${album.title}, artists: ${artists.map((a) => a.name).toList()})';
}
