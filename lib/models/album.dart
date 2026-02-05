class Album {
  final int id;
  final int artistId;
  final String title;
  final int year;
  final String? artPath;

  Album({
    this.id = -1,
    this.artistId = -1,
    required this.title,
    this.year = 0,
    this.artPath,
  });

  Album copyWith({
    int? id,
    int? artistId,
    String? title,
    int? year,
    String? artPath,
  }) {
    return Album(
      id: id ?? this.id,
      artistId: artistId ?? this.artistId,
      title: title ?? this.title,
      year: year ?? this.year,
      artPath: artPath ?? this.artPath,
    );
  }
}
