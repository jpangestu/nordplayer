import 'package:flutter/foundation.dart' show immutable, listEquals;
import 'package:nordplayer/core/database/app_database.dart' show PlaylistData;

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
  String toString() => 'PlaylistWithDetails(playlist: ${playlist.name}, trackCount: $trackCount, covers: ${imageUrls.length})';
}
