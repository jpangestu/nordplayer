import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nordplayer/database/app_database.dart';
import 'package:nordplayer/services/audio_fingerprinter.dart';
import 'package:nordplayer/services/logger.dart';
import 'package:nordplayer/utils/string_extension.dart';
import 'package:path/path.dart' as p;

final duplicateDetectorProvider = Provider<DuplicateDetector>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final fingerprinter = ref.watch(audioFingerprinterProvider);
  return DuplicateDetector(db, fingerprinter);
});

class DuplicateCandidate {
  final Track track;
  final String artistName;
  final String albumTitle;

  DuplicateCandidate({required this.track, required this.artistName, required this.albumTitle});
}

class DuplicateGroup {
  final String title;
  final String artist;
  final String album;
  final List<Track> tracks;
  final Track preferredTrack;

  DuplicateGroup({
    required this.title,
    required this.artist,
    required this.album,
    required this.tracks,
    required this.preferredTrack,
  });
}

class DuplicateDetector with LoggerMixin {
  final AppDatabase _db;
  final AudioFingerprinter _fingerprinter;

  DuplicateDetector(this._db, this._fingerprinter);

  /// Scans the library database to find groups of duplicate tracks.
  Future<List<DuplicateGroup>> findDuplicates() async {
    log.i("Starting duplicate track detection scan...");
    final stopwatch = Stopwatch()..start();

    // Fetch active tracks with fingerprints, joined with Artists and Albums
    final query = _db.select(_db.tracks).join([
      leftOuterJoin(_db.albums, _db.albums.id.equalsExp(_db.tracks.albumId)),
      leftOuterJoin(_db.artists, _db.artists.id.equalsExp(_db.tracks.artistId)),
    ])..where(_db.tracks.isMissing.equals(false) & _db.tracks.audioFingerprint.isNotNull());

    final rows = await query.get();
    final List<DuplicateCandidate> candidates = rows.map((row) {
      final track = row.readTable(_db.tracks);
      final album = row.readTableOrNull(_db.albums);
      final artist = row.readTableOrNull(_db.artists);

      return DuplicateCandidate(
        track: track,
        artistName: artist?.name ?? 'Unknown Artist',
        albumTitle: album?.title ?? 'Unknown Album',
      );
    }).toList();

    log.i("Fetched ${candidates.length} tracks with fingerprints for duplication checking.");

    // Sort candidates by duration to enable window-based scanning
    candidates.sort((a, b) => a.track.durationMs.compareTo(b.track.durationMs));

    final List<DuplicateGroup> duplicateGroups = [];
    final Set<int> processedIds = {};

    // Slide a window forward
    for (int i = 0; i < candidates.length; i++) {
      final target = candidates[i];
      if (processedIds.contains(target.track.id)) continue;

      final List<DuplicateCandidate> currentGroupCandidates = [target];

      for (int j = i + 1; j < candidates.length; j++) {
        final next = candidates[j];
        if (next.track.durationMs - target.track.durationMs > 5000) {
          break; // Duration difference exceeds 5 seconds window, stop looking forward
        }
        if (processedIds.contains(next.track.id)) continue;

        // Perform raw fingerprint comparison
        final fp1 = _fingerprinter.parseRawFingerprint(target.track.audioFingerprint);
        final fp2 = _fingerprinter.parseRawFingerprint(next.track.audioFingerprint);

        if (fp1 != null && fp2 != null) {
          final similarity = _fingerprinter.compareRawFingerprints(fp1, fp2);
          if (similarity >= 0.85) {
            currentGroupCandidates.add(next);
          }
        }
      }

      if (currentGroupCandidates.length > 1) {
        // We found duplicates! Construct the group
        final groupTracks = currentGroupCandidates.map((c) => c.track).toList();
        final preferredTrack = _determinePreferredTrack(groupTracks);

        duplicateGroups.add(
          DuplicateGroup(
            title: target.track.title,
            artist: target.artistName,
            album: target.albumTitle,
            tracks: groupTracks,
            preferredTrack: preferredTrack,
          ),
        );

        // Mark all matched tracks as processed
        for (final c in currentGroupCandidates) {
          processedIds.add(c.track.id);
        }
      }
    }

    stopwatch.stop();
    log.i(
      "Duplicate scan complete. Found ${duplicateGroups.length} duplicate groups in ${stopwatch.elapsedMilliseconds}ms.",
    );
    return duplicateGroups;
  }

  /// Ignores a track by removing it from the database and adding it to the ignored paths table.
  Future<void> ignorePath(Track track) async {
    log.i("Ignoring track '${track.title}' (ID: ${track.id}) by removing from database and adding to ignored paths.");

    await (_db.delete(_db.tracks)..where((t) => t.id.equals(track.id))).go();

    await _db
        .into(_db.ignoredPaths)
        .insertOnConflictUpdate(IgnoredPathsCompanion(filePath: Value(track.filePath.normalizePath().toLowerCase())));
  }

  /// Determines the preferred/highest quality track copy in a list.
  /// Prefers lossless formats (.flac, .wav, .alac, .ape) and falls back to larger file sizes.
  Track _determinePreferredTrack(List<Track> group) {
    return group.reduce((best, current) {
      final extBest = p.extension(best.filePath).toLowerCase();
      final extCurr = p.extension(current.filePath).toLowerCase();

      final isLosslessBest = const ['.flac', '.wav', '.alac', '.ape'].contains(extBest);
      final isLosslessCurr = const ['.flac', '.wav', '.alac', '.ape'].contains(extCurr);

      if (isLosslessBest && !isLosslessCurr) return best;
      if (!isLosslessBest && isLosslessCurr) return current;

      // If formats are of equal lossless/lossy tier, prefer the larger file size
      return (current.fileSize > best.fileSize) ? current : best;
    });
  }
}
