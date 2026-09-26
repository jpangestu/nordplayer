import 'package:flutter/foundation.dart';

/// Pure domain entity representing a musical artist, independent of database schema.
@immutable
class const Artist({required final int id, required final String name, final String? artistImgPath}) {
  Artist copyWith({int? id, String? name, String? artistImgPath}) {
    return Artist(id: id ?? this.id, name: name ?? this.name, artistImgPath: artistImgPath ?? this.artistImgPath);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Artist &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          artistImgPath == other.artistImgPath;

  @override
  int get hashCode => Object.hash(id, name, artistImgPath);

  @override
  String toString() => 'Artist(id: $id, name: $name)';
}
