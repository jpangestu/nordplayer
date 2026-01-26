import 'dart:io';
import 'package:path/path.dart' as p;

class Song {
  final String title;
  final String artist;
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
    required this.title,
    required this.artist,
    this.album = '', // Default to empty string
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
