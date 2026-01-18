import 'dart:io';
import 'package:path/path.dart' as p;

class Song {
  final String title;
  final String artist;
  final String path;
  final Duration? duration;

  Song({
    required this.title,
    required this.artist,
    required this.path,
    this.duration,
  });

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