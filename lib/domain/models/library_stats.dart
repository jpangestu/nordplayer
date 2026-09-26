import 'package:flutter/foundation.dart';

/// Pure domain entity representing aggregate library statistics.
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
  int get hashCode =>
      Object.hash(trackCount, albumCount, artistCount, playlistCount, genreCount, totalSizeBytes, totalPlaytimeMs);

  @override
  String toString() {
    return 'LibraryStats(trackCount: $trackCount, albumCount: $albumCount, artistCount: $artistCount, '
        'playlistCount: $playlistCount, genreCount: $genreCount, totalSizeBytes: $totalSizeBytes, totalPlaytimeMs: $totalPlaytimeMs)';
  }
}
