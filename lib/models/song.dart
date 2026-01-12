
class Song {
  final String title;
  final String artist;
  final String filePath;

  Song({required this.title, required this.artist, required this.filePath});

  factory Song.fromMap(Map<String, dynamic> rawData) {
    assert(rawData['filePath'].isNotEmpty, 'Path cannot be empty');
    return Song(title: rawData['title'], artist: rawData['artist'], filePath: rawData['filePath']);
  }
}