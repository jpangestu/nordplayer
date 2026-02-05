class Artist {
  final int id;
  final String name;
  final String? artistImagePath; // Different from album art!
  final int numberOfAlbums;
  final int numberOfTracks;

  Artist({
    this.id = -1,
    required this.name,
    this.artistImagePath,
    this.numberOfAlbums = 0,
    this.numberOfTracks = 0,
  });

  Artist copyWith({
    int? id,
    String? name,
    String? artistImagePath,
    int? numberOfAlbums,
    int? numberOfTracks,
  }) {
    return Artist(
      id: id ?? this.id,
      name: name ?? this.name,
      artistImagePath: artistImagePath ?? this.artistImagePath,
      numberOfAlbums: numberOfAlbums ?? this.numberOfAlbums,
      numberOfTracks: numberOfTracks ?? this.numberOfTracks,
    );
  }
}
