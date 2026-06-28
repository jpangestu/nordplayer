import 'dart:typed_data';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nordplayer/database/app_database.dart';
import 'package:nordplayer/services/audio_fingerprinter.dart';
import 'package:nordplayer/services/duplicate_detector.dart';
import 'package:nordplayer/utils/string_extension.dart';

void main() {
  late AppDatabase db;
  late AudioFingerprinter fingerprinter;
  late DuplicateDetector detector;
  late ProviderContainer container;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory(setup: (database) {
      database.execute('PRAGMA foreign_keys = ON;');
    }));
    fingerprinter = AudioFingerprinter();
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        audioFingerprinterProvider.overrideWithValue(fingerprinter),
      ],
    );
    detector = container.read(duplicateDetectorProvider);
  });

  tearDown(() async {
    await db.close();
    container.dispose();
  });

  // Helper to convert raw integers into Uint8List bytes
  Uint8List makeBytes(List<int> rawFingerprint) {
    final uint32list = Uint32List.fromList(rawFingerprint);
    return uint32list.buffer.asUint8List();
  }

  group('DuplicateDetector Tests', () {
    test('findDuplicates finds and groups duplicate tracks correctly', () async {
      // 1. Insert seed artist and album
      await db.into(db.artists).insert(
            ArtistsCompanion.insert(id: const Value(1), name: 'Avenged Sevenfold'),
          );
      await db.into(db.albums).insert(
            AlbumsCompanion.insert(
              id: const Value(1),
              title: 'Life Is But a Dream...',
              year: const Value(2023),
            ),
          );

      // 2. Insert tracks
      // songA: Cosmic (CD quality, flac)
      final cosmicCdFingerprint = makeBytes(List<int>.generate(20, (i) => i * 100));
      await db.into(db.tracks).insert(
            TracksCompanion.insert(
              id: const Value(1),
              title: 'Cosmic',
              durationMs: const Value(300000), // 5:00
              fileHash: 'hash_cosmic_cd',
              filePath: 'C:/Music/Avenged Sevenfold/Cosmic_cd.flac',
              fileSize: const Value(30000000), // 30 MB
              artistId: 1,
              albumId: 1,
              audioFingerprint: Value(cosmicCdFingerprint),
            ),
          );

      // songB: Cosmic (High-Res quality, flac) - duration within +3 seconds, identical fingerprint
      await db.into(db.tracks).insert(
            TracksCompanion.insert(
              id: const Value(2),
              title: 'Cosmic',
              durationMs: const Value(303000), // 5:03
              fileHash: 'hash_cosmic_hi_res',
              filePath: 'C:/Music/Avenged Sevenfold/Cosmic_hi_res.flac',
              fileSize: const Value(50000000), // 50 MB
              artistId: 1,
              albumId: 1,
              audioFingerprint: Value(cosmicCdFingerprint),
            ),
          );

      // songC: Cosmic (MP3 quality) - duration within +1 seconds, identical fingerprint
      await db.into(db.tracks).insert(
            TracksCompanion.insert(
              id: const Value(3),
              title: 'Cosmic',
              durationMs: const Value(301000), // 5:01
              fileHash: 'hash_cosmic_mp3',
              filePath: 'C:/Music/Avenged Sevenfold/Cosmic.mp3',
              fileSize: const Value(7000000), // 7 MB
              artistId: 1,
              albumId: 1,
              audioFingerprint: Value(cosmicCdFingerprint),
            ),
          );

      // songD: A Little Piece of Heaven (different song, same duration window)
      final lpohFingerprint = makeBytes(List<int>.generate(20, (i) => i * 9999));
      await db.into(db.tracks).insert(
            TracksCompanion.insert(
              id: const Value(4),
              title: 'A Little Piece of Heaven',
              durationMs: const Value(302000), // 5:02 (within window but different fingerprint)
              fileHash: 'hash_lpoh',
              filePath: 'C:/Music/Avenged Sevenfold/A Little Piece of Heaven.flac',
              fileSize: const Value(35000000),
              artistId: 1,
              albumId: 1,
              audioFingerprint: Value(lpohFingerprint),
            ),
          );

      // 3. Run search
      final groups = await detector.findDuplicates();

      // Expecting exactly 1 group of duplicates (containing Cosmic CD, Cosmic High-Res, and Cosmic MP3)
      // A Little Piece of Heaven should not be grouped.
      expect(groups.length, 1);
      final group = groups.first;
      expect(group.title, 'Cosmic');
      expect(group.tracks.length, 3);
      expect(group.tracks.any((t) => t.id == 1), true);
      expect(group.tracks.any((t) => t.id == 2), true);
      expect(group.tracks.any((t) => t.id == 3), true);

      // Verify quality ranking:
      // Cosmic CD (30MB flac) vs Cosmic High-Res (50MB flac) vs Cosmic MP3 (7MB mp3)
      // High-Res flac should be preferred (lossless and largest size)
      expect(group.preferredTrack.id, 2);
    });

    test('findDuplicates ignores tracks outside the 5-second duration window', () async {
      await db.into(db.artists).insert(
            ArtistsCompanion.insert(id: const Value(1), name: 'Avenged Sevenfold'),
          );
      await db.into(db.albums).insert(
            AlbumsCompanion.insert(
              id: const Value(1),
              title: 'Life Is But a Dream...',
              year: const Value(2023),
            ),
          );

      final fingerprint = makeBytes(List<int>.generate(20, (i) => i * 100));

      // Track 1
      await db.into(db.tracks).insert(
            TracksCompanion.insert(
              id: const Value(1),
              title: 'Cosmic',
              durationMs: const Value(300000), // 5:00
              fileHash: 'hash_cosmic_1',
              filePath: 'C:/Music/Cosmic1.flac',
              fileSize: const Value(30000000),
              artistId: 1,
              albumId: 1,
              audioFingerprint: Value(fingerprint),
            ),
          );

      // Track 2: Same song/fingerprint, but duration is 306,000 (+6 seconds, outside window)
      await db.into(db.tracks).insert(
            TracksCompanion.insert(
              id: const Value(2),
              title: 'Cosmic',
              durationMs: const Value(306000), // 5:06
              fileHash: 'hash_cosmic_2',
              filePath: 'C:/Music/Cosmic2.flac',
              fileSize: const Value(30000000),
              artistId: 1,
              albumId: 1,
              audioFingerprint: Value(fingerprint),
            ),
          );

      final groups = await detector.findDuplicates();
      expect(groups.isEmpty, true); // No duplicates because they are outside duration window
    });

    test('ignorePath cascade deletes track relationships', () async {
      await db.into(db.artists).insert(
            ArtistsCompanion.insert(id: const Value(1), name: 'Artist'),
          );
      await db.into(db.albums).insert(
            AlbumsCompanion.insert(id: const Value(1), title: 'Album'),
          );

      // Insert Track
      await db.into(db.tracks).insert(
            TracksCompanion.insert(
              id: const Value(10),
              title: 'Track to Delete',
              durationMs: const Value(200000),
              fileHash: 'hash_del',
              filePath: 'C:/Music/delete_me.mp3',
              artistId: 1,
              albumId: 1,
            ),
          );

      // Insert TrackArtist relationship
      await db.into(db.trackArtist).insert(
            TrackArtistCompanion.insert(trackId: 10, artistId: 1),
          );

      // Double check it exists
      var trackArtists = await db.select(db.trackArtist).get();
      expect(trackArtists.length, 1);

      // Delete Track via service
      final track = await (db.select(db.tracks)..where((t) => t.id.equals(10))).getSingle();
      await detector.ignorePath(track);

      // Check track is deleted
      final tracksLeft = await db.select(db.tracks).get();
      expect(tracksLeft.isEmpty, true);

      // Verify cascade delete worked on trackArtist relationship
      trackArtists = await db.select(db.trackArtist).get();
      expect(trackArtists.isEmpty, true);

      // Verify track path was inserted into ignored_paths on database-only delete
      final ignoredPaths = await db.select(db.ignoredPaths).get();
      expect(ignoredPaths.length, 1);
      expect(ignoredPaths.first.filePath, 'C:/Music/delete_me.mp3'.normalizePath().toLowerCase());
    });
  });
}
