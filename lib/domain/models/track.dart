import 'package:flutter/foundation.dart';

/// Pure domain entity representing an audio track, independent of database schema.
@immutable
class Track {
  final int id;
  final String title;
  final int trackNumber;
  final int trackTotal;
  final int discNumber;
  final int discTotal;
  final int durationMs;
  final String? genre;
  final String fileHash;
  final Uint8List? audioFingerprint;
  final bool isMissing;
  final String filePath;
  final int fileSize;
  final int artistId;
  final int albumId;
  final DateTime dateAdded;

  const Track({
    required this.id,
    required this.title,
    this.trackNumber = 0,
    this.trackTotal = 0,
    this.discNumber = 0,
    this.discTotal = 0,
    this.durationMs = 0,
    this.genre,
    required this.fileHash,
    this.audioFingerprint,
    this.isMissing = false,
    required this.filePath,
    this.fileSize = 0,
    required this.artistId,
    required this.albumId,
    required this.dateAdded,
  });

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
