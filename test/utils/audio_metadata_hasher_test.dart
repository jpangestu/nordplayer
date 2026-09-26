import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nordplayer/utils/audio_metadata_hasher.dart';

void main() {
  group('AudioMetadataHasher', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('nord_hasher_test_');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('calculates consistent hash for mp3 file with ID3v2 header', () {
      final file = File('${tempDir.path}/test.mp3');
      // Minimal ID3v2.3 header (10 bytes) + 4 dummy bytes
      file.writeAsBytesSync([
        0x49, 0x44, 0x33, // 'ID3'
        0x03, 0x00, // version 2.3
        0x00, // flags
        0x00, 0x00, 0x00, 0x04, // synchsafe size = 4
        0x01, 0x02, 0x03, 0x04, // tag payload
      ]);

      final hash1 = AudioMetadataHasher.calculateHash(file);
      final hash2 = AudioMetadataHasher.calculateHash(file);

      expect(hash1, equals(hash2));
      expect(hash1, contains('_14')); // size = 14
    });

    test('calculates consistent hash for flac file with fLaC signature', () {
      final file = File('${tempDir.path}/test.flac');
      // 'fLaC' signature + last metadata block header (4 bytes) + 4 dummy bytes
      file.writeAsBytesSync([
        0x66, 0x4C, 0x61, 0x43, // 'fLaC'
        0x80, // isLast = true (0x80), type = 0
        0x00, 0x00, 0x04, // block length = 4
        0xAA, 0xBB, 0xCC, 0xDD, // metadata
      ]);

      final hash1 = AudioMetadataHasher.calculateHash(file);
      final hash2 = AudioMetadataHasher.calculateHash(file);

      expect(hash1, equals(hash2));
      expect(hash1, contains('_12'));
    });

    test('calculates consistent hash for wav file with RIFF/WAVE header', () {
      final file = File('${tempDir.path}/test.wav');
      // RIFF header
      file.writeAsBytesSync([
        0x52, 0x49, 0x46, 0x46, // 'RIFF'
        0x10, 0x00, 0x00, 0x00, // file size - 8
        0x57, 0x41, 0x56, 0x45, // 'WAVE'
        0x64, 0x61, 0x74, 0x61, // 'data' chunk
        0x00, 0x00, 0x00, 0x00, // chunk size = 0
      ]);

      final hash = AudioMetadataHasher.calculateHash(file);
      expect(hash, contains('_20'));
    });

    test('falls back gracefully when file cannot be read', () {
      final nonExistentFile = File('${tempDir.path}/non_existent.mp3');
      final hash = AudioMetadataHasher.calculateHash(nonExistentFile);
      expect(hash, isNotEmpty);
      expect(hash, contains('_0'));
    });
  });
}
