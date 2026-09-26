import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nordplayer/data/services/indexer/chromaprint_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ChromaprintService & AudioFingerprintResult Tests', () {
    test('AudioFingerprintResult calculates fingerprintBytes accurately', () {
      final raw = [0x12345678, 0x9ABCDEF0];
      final result = AudioFingerprintResult(rawAudioFingerprint: raw, durationMs: 3000);

      expect(result.durationMs, 3000);
      expect(result.rawAudioFingerprint, raw);

      final bytes = result.fingerprintBytes;
      expect(bytes.lengthInBytes, 8);

      final parsed = ChromaprintService.parseRawAudioFingerprint(bytes);
      expect(parsed, raw);
    });

    test('compareRawAudioFingerprints returns 1.0 immediately for identical references', () {
      final shortFp = [1, 2, 3]; // Overlap < 15, normally returns 0.0 for distinct instances
      expect(ChromaprintService.compareRawAudioFingerprints(shortFp, shortFp), 1.0);
    });

    test('compareRawAudioFingerprints returns 0.0 for empty inputs', () {
      final fp = List<int>.generate(20, (i) => i);
      expect(ChromaprintService.compareRawAudioFingerprints([], fp), 0.0);
      expect(ChromaprintService.compareRawAudioFingerprints(fp, []), 0.0);
      expect(ChromaprintService.compareRawAudioFingerprints([], []), 0.0);
    });

    test('compareRawAudioFingerprints enforces 15-element minimum overlap for distinct instances', () {
      final fp1 = List<int>.generate(10, (i) => i * 10);
      final fp2 = List<int>.generate(10, (i) => i * 10);

      expect(identical(fp1, fp2), false);
      expect(ChromaprintService.compareRawAudioFingerprints(fp1, fp2), 0.0);
    });

    test('compareRawAudioFingerprints aligns shifted matching fingerprints', () {
      final baseline = List<int>.generate(30, (i) => (i * 9876543) ^ 0x5A5A5A5A);
      final shifted = List<int>.generate(35, (i) {
        if (i < 5) return 0;
        return baseline[i - 5];
      });

      final similarity = ChromaprintService.compareRawAudioFingerprints(baseline, shifted);
      expect(similarity, closeTo(1.0, 0.0001));
    });

    test('parseRawAudioFingerprint handles unaligned byte offsets', () {
      // Allocate a larger buffer with unaligned offset
      final fullBuffer = Uint8List(17);
      // Fill bytes starting at odd offset 1
      final rawInts = [0x11223344, 0x55667788];
      final u32 = Uint32List.fromList(rawInts);
      fullBuffer.setRange(1, 9, u32.buffer.asUint8List());

      // Create a sublist view with offsetInBytes == 1 (not a multiple of 4)
      final unalignedView = Uint8List.sublistView(fullBuffer, 1, 9);
      expect(unalignedView.offsetInBytes % 4, isNot(0));

      final parsed = ChromaprintService.parseRawAudioFingerprint(unalignedView);
      expect(parsed, rawInts);
    });

    test('parseRawAudioFingerprint returns null for null or empty buffer', () {
      expect(ChromaprintService.parseRawAudioFingerprint(null), isNull);
      expect(ChromaprintService.parseRawAudioFingerprint(Uint8List(0)), isNull);
    });

    test('Custom fpcalc path constructor persists path', () async {
      final customService = ChromaprintService('/custom/bin/fpcalc');
      expect(await customService.fpcalcPath, '/custom/bin/fpcalc');
    });
  });
}
