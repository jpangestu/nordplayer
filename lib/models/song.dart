import 'dart:io';
import 'package:path/path.dart' as p;

class Song {
  final String title;
  final String artist;
  final String path;
  final Duration? duration;
  final int timestamp;

  Song({
    required this.title,
    required this.artist,
    required this.path,
    this.duration,
    this.timestamp = 0,
  });

  /// Helper to quickly create a copy with a new timestamp
  Song copyWith({
    String? title,
    String? artist,
    String? path,
    Duration? duration,
    int? timestamp,
  }) {
    return Song(
      title: title ?? this.title,
      artist: artist ?? this.artist,
      path: path ?? this.path,
      duration: duration ?? this.duration,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  // Create a song object from audio file with no metadata
  factory Song.fromFile(File file) {
    return Song(
      title: p.basenameWithoutExtension(file.path),
      artist: 'unknown artist',
      path: file.path,
      duration: null,
    );
  }
}
