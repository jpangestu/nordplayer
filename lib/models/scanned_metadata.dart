/// A simple DTO to carry data from the Background Isolate -> Main Thread.
class ScannedMetadata {
  final String title;
  
  /// The "Primary" artist (e.g., "Drake").
  /// Used for sorting and the main [Songs] table.
  final String artist; 

  /// All artists split from the tag (e.g., ["Drake", "Future"]).
  /// Used to populate the [SongArtists] junction table.
  final List<String> allArtists;

  final String album;
  final String genre;
  final int year;
  final int trackNumber;
  final int discNumber;
  final Duration duration;
  final String path;

  /// Path to the cached album art image (if extracted).
  /// This will be linked to the [Albums] table, not the Song.
  final String? artPath;

  /// File modification time (in milliseconds).
  /// Used to detect if the file has changed since the last scan.
  final int timestamp;

  const ScannedMetadata({
    required this.title,
    required this.artist,
    required this.allArtists,
    required this.album,
    required this.genre,
    required this.year,
    required this.trackNumber,
    required this.discNumber,
    required this.duration,
    required this.path,
    this.artPath,
    required this.timestamp,
  });
}