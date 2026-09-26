import 'package:flutter/foundation.dart';

/// Pure domain entity representing an album, independent of database schema.
@immutable
class const Album({
  required final int id,
  required final String title,
  final int year = 0,
  final String? albumArtist,
  final String? albumArtPath,
  final int? albumArtistId,
}) {
  Album copyWith({
    int? id,
    String? title,
    int? year,
    String? albumArtist,
    String? albumArtPath,
    int? albumArtistId,
  }) {
    return Album(
      id: id ?? this.id,
      title: title ?? this.title,
      year: year ?? this.year,
      albumArtist: albumArtist ?? this.albumArtist,
      albumArtPath: albumArtPath ?? this.albumArtPath,
      albumArtistId: albumArtistId ?? this.albumArtistId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Album &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          year == other.year &&
          albumArtist == other.albumArtist &&
          albumArtPath == other.albumArtPath &&
          albumArtistId == other.albumArtistId;

  @override
  int get hashCode => Object.hash(id, title, year, albumArtist, albumArtPath, albumArtistId);

  @override
  String toString() => 'Album(id: $id, title: $title, year: $year)';
}
