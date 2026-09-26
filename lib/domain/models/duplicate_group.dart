import 'package:nordplayer/domain/models/track.dart';

/// Represents a cluster of duplicate tracks sharing title/artist/fingerprint metadata,
/// along with the recommended [preferredTrack] based on quality and completeness.
class const DuplicateGroup({
  required final String title,
  required final String artist,
  required final String album,
  required final List<Track> tracks,
  required final Track preferredTrack,
});
