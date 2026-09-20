import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nordplayer/services/indexer/chromaprint_service.dart';

void main() {
  group('AudioFingerprinter raw comparison tests', () {
    test('popcount calculates correct number of set bits', () {
      final fpIdentical1 = List<int>.generate(20, (i) => i * 12345);
      final fpIdentical2 = List<int>.generate(20, (i) => i * 12345);

      expect(ChromaprintService.compareRawAudioFingerprints(fpIdentical1, fpIdentical2), closeTo(1.0, 0.0001));
    });

    test('parseRawFingerprint handles binary deserialization', () {
      final ints = [1, 2, 3, 4, 5];
      final uint32list = Uint32List.fromList(ints);
      final bytes = uint32list.buffer.asUint8List();

      expect(ChromaprintService.parseRawAudioFingerprint(bytes), ints);
      expect(ChromaprintService.parseRawAudioFingerprint(null), isNull);
      expect(ChromaprintService.parseRawAudioFingerprint(Uint8List(0)), isNull);
    });

    test('compareRawFingerprints correctly aligns and scores shifted matching fingerprints', () {
      // Generate a baseline raw fingerprint list of 30 frames
      final baseline = List<int>.generate(30, (i) => (i * 9876543) ^ 0x5A5A5A5A);

      // identical list
      expect(ChromaprintService.compareRawAudioFingerprints(baseline, baseline), closeTo(1.0, 0.0001));

      // shifted by 5 frames
      final shifted = List<int>.generate(35, (i) {
        if (i < 5) return 0; // offset padding
        return baseline[i - 5];
      });

      // compareRawFingerprints should shift and align them, yielding 1.0 (or very close depending on padding)
      final similarity = ChromaprintService.compareRawAudioFingerprints(baseline, shifted);
      // Expected: the overlapping 25 frames should align perfectly and yield 1.0 match rate for that region
      expect(similarity, closeTo(1.0, 0.0001));
    });

    test('compareRawFingerprints handles slight differences (quality variation)', () {
      // 20 identical frames
      final fp1 = List<int>.generate(20, (i) => 0xFFFFFFFF);

      // fp2 has 2 bits flipped in each frame (30 / 32 match rate)
      final fp2 = List<int>.generate(20, (i) => 0xFFFFFFFC); // FFC = 11111111111111111111111111111100

      // Match rate should be 30 / 32 = 0.9375
      final similarity = ChromaprintService.compareRawAudioFingerprints(fp1, fp2);
      expect(similarity, closeTo(0.9375, 0.0001));
    });

    test('compareRawFingerprints handles completely different inputs', () {
      final fp1 = List<int>.generate(20, (i) => 0xAAAAAAAA);
      final fp2 = List<int>.generate(20, (i) => 0x55555555);

      // Completely inverted bits, so similarity should be 0.0
      final similarity = ChromaprintService.compareRawAudioFingerprints(fp1, fp2);
      expect(similarity, closeTo(0.0, 0.0001));
    });

    test('compareRawFingerprints enforces minimum overlap length', () {
      final fp1 = List<int>.generate(10, (i) => 1);
      final fp2 = List<int>.generate(10, (i) => 1);

      // Overlap len is 10, which is less than 15. Should return 0.0.
      expect(ChromaprintService.compareRawAudioFingerprints(fp1, fp2), 0.0);
    });
  });
}
