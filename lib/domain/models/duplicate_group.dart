import 'package:nordplayer/domain/models/track.dart';

/// Represents a cluster of duplicate tracks sharing title/artist/fingerprint metadata,
/// along with the recommended [preferredTrack] based on quality and completeness.
class DuplicateGroup {
  final String title;
  final String artist;
  final String album;
  final List<Track> tracks;
  final Track preferredTrack;

  const DuplicateGroup({
    required this.title,
    required this.artist,
    required this.album,
    required this.tracks,
    required this.preferredTrack,
  });
}
