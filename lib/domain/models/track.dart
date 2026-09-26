import 'package:flutter/foundation.dart';

/// Pure domain entity representing an audio track, independent of database schema.
@immutable
class const Track({
  required final int id,
  required final String title,
  final int trackNumber = 0,
  final int trackTotal = 0,
  final int discNumber = 0,
  final int discTotal = 0,
  final int durationMs = 0,
  final String? genre,
  required final String fileHash,
  final Uint8List? audioFingerprint,
  final bool isMissing = false,
  required final String filePath,
  final int fileSize = 0,
  required final int artistId,
  required final int albumId,
  required final DateTime dateAdded,
}) {
  Track copyWith({
    int? id,
    String? title,
    int? trackNumber,
    int? trackTotal,
    int? discNumber,
    int? discTotal,
    int? durationMs,
    String? genre,
    String? fileHash,
    Uint8List? audioFingerprint,
    bool? isMissing,
    String? filePath,
    int? fileSize,
    int? artistId,
    int? albumId,
    DateTime? dateAdded,
  }) {
    return Track(
      id: id ?? this.id,
      title: title ?? this.title,
      trackNumber: trackNumber ?? this.trackNumber,
      trackTotal: trackTotal ?? this.trackTotal,
      discNumber: discNumber ?? this.discNumber,
      discTotal: discTotal ?? this.discTotal,
      durationMs: durationMs ?? this.durationMs,
      genre: genre ?? this.genre,
      fileHash: fileHash ?? this.fileHash,
      audioFingerprint: audioFingerprint ?? this.audioFingerprint,
      isMissing: isMissing ?? this.isMissing,
      filePath: filePath ?? this.filePath,
      fileSize: fileSize ?? this.fileSize,
      artistId: artistId ?? this.artistId,
      albumId: albumId ?? this.albumId,
      dateAdded: dateAdded ?? this.dateAdded,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Track &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          filePath == other.filePath &&
          fileHash == other.fileHash &&
          isMissing == other.isMissing;

  @override
  int get hashCode => Object.hash(id, filePath, fileHash, isMissing);

  @override
  String toString() => 'Track(id: $id, title: $title, path: $filePath)';
}
