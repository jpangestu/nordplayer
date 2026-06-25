import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:nordplayer/services/audio_fingerprinter.dart';

void main() {
  group('AudioFingerprinter raw comparison tests', () {
    final fingerprinter = AudioFingerprinter();

    test('popcount calculates correct number of set bits', () {
      // Accessing private helper via custom mock or test execution isn't strictly necessary
      // since we can verify it through compareRawFingerprints. But we can test it directly
      // if we test the public comparison outputs.
      // Let's verify comparing identical inputs gives 100% (1.0).
      
      // Since overlap of length 5 is less than the minimum overlap of 15,
      // it should return 0.0. Let's make mock lists of at least 15 elements.
      final fpIdentical1 = List<int>.generate(20, (i) => i * 12345);
      final fpIdentical2 = List<int>.generate(20, (i) => i * 12345);
      
      expect(fingerprinter.compareRawFingerprints(fpIdentical1, fpIdentical2), closeTo(1.0, 0.0001));
    });

    test('parseRawFingerprint handles binary deserialization', () {
      final ints = [1, 2, 3, 4, 5];
      final uint32list = Uint32List.fromList(ints);
      final bytes = uint32list.buffer.asUint8List();
      
      expect(fingerprinter.parseRawFingerprint(bytes), ints);
      expect(fingerprinter.parseRawFingerprint(null), isNull);
      expect(fingerprinter.parseRawFingerprint(Uint8List(0)), isNull);
    });

    test('compareRawFingerprints correctly aligns and scores shifted matching fingerprints', () {
      // Generate a baseline raw fingerprint list of 30 frames
      final baseline = List<int>.generate(30, (i) => (i * 9876543) ^ 0x5A5A5A5A);
      
      // identical list
      expect(fingerprinter.compareRawFingerprints(baseline, baseline), closeTo(1.0, 0.0001));

      // shifted by 5 frames
      final shifted = List<int>.generate(35, (i) {
        if (i < 5) return 0; // offset padding
        return baseline[i - 5];
      });

      // compareRawFingerprints should shift and align them, yielding 1.0 (or very close depending on padding)
      final similarity = fingerprinter.compareRawFingerprints(baseline, shifted);
      // Expected: the overlapping 25 frames should align perfectly and yield 1.0 match rate for that region
      expect(similarity, closeTo(1.0, 0.0001));
    });

    test('compareRawFingerprints handles slight differences (quality variation)', () {
      // 20 identical frames
      final fp1 = List<int>.generate(20, (i) => 0xFFFFFFFF);
      
      // fp2 has 2 bits flipped in each frame (30 / 32 match rate)
      final fp2 = List<int>.generate(20, (i) => 0xFFFFFFFC); // FFC = 11111111111111111111111111111100

      // Match rate should be 30 / 32 = 0.9375
      final similarity = fingerprinter.compareRawFingerprints(fp1, fp2);
      expect(similarity, closeTo(0.9375, 0.0001));
    });

    test('compareRawFingerprints handles completely different inputs', () {
      final fp1 = List<int>.generate(20, (i) => 0xAAAAAAAA);
      final fp2 = List<int>.generate(20, (i) => 0x55555555);

      // Completely inverted bits, so similarity should be 0.0
      final similarity = fingerprinter.compareRawFingerprints(fp1, fp2);
      expect(similarity, closeTo(0.0, 0.0001));
    });

    test('compareRawFingerprints enforces minimum overlap length', () {
      final fp1 = List<int>.generate(10, (i) => 1);
      final fp2 = List<int>.generate(10, (i) => 1);

      // Overlap len is 10, which is less than 15. Should return 0.0.
      expect(fingerprinter.compareRawFingerprints(fp1, fp2), 0.0);
    });
  });
}
