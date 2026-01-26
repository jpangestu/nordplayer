import 'dart:io';
import 'package:path/path.dart' as p;

class Song {
  final int id;        // To play this specific song
  final int artistId;  // To go to Artist Page
  final int albumId;   // To go to Album Page

  final String title;
  final String artist; // The "Primary" artist name (for display)
  final String album;
  final String genre;
  final int year;
  final int trackNumber;
  final int discNumber;
  final Duration duration;
  final String path;
  final String? artPath;
  final int timestamp;

  const Song({
    this.id = -1,       // Default to -1 for temporary objects
    this.artistId = -1,
    this.albumId = -1,
    required this.title,
    required this.artist,
    this.album = '',
    this.genre = '',
    this.year = 0,
    this.trackNumber = 0,
    this.discNumber = 0,
    required this.duration,
    required this.path,
    this.artPath,
    this.timestamp = 0,
  });

  // Helper to copy object
  Song copyWith({
    int? id,
    int? artistId,
    int? albumId,
    String? title,
    String? artist,
    String? album,
    String? genre,
    int? year,
    int? trackNumber,
    int? discNumber,
    Duration? duration,
    String? path,
    String? artPath,
    int? timestamp,
  }) {
    return Song(
      id: id ?? this.id,
      artistId: artistId ?? this.artistId,
      albumId: albumId ?? this.albumId,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      genre: genre ?? this.genre,
      year: year ?? this.year,
      trackNumber: trackNumber ?? this.trackNumber,
      discNumber: discNumber ?? this.discNumber,
      duration: duration ?? this.duration,
      path: path ?? this.path,
      artPath: artPath ?? this.artPath,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  // Create a song object from audio file with no metadata
  factory Song.fromFile(File file) {
    return Song(
      title: p.basenameWithoutExtension(file.path),
      artist: 'unknown artist',
      path: file.path,
      duration: Duration(milliseconds: 0),
    );
  }
}