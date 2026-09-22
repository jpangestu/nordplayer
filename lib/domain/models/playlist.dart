import 'package:flutter/foundation.dart';

/// Pure domain entity representing a music playlist, independent of database schema.
@immutable
class Playlist {
  final int id;
  final String name;
  final String? coverPath;

  const Playlist({
    required this.id,
    required this.name,
    this.coverPath,
  });

  Playlist copyWith({
    int? id,
    String? name,
    String? coverPath,
  }) {
    return Playlist(
      id: id ?? this.id,
      name: name ?? this.name,
      coverPath: coverPath ?? this.coverPath,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Playlist &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          coverPath == other.coverPath;

  @override
  int get hashCode => Object.hash(id, name, coverPath);

  @override
  String toString() => 'Playlist(id: $id, name: $name)';
}
