import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nordplayer/services/logger.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

final audioFingerprinterProvider = Provider<AudioFingerprinter>((ref) {
  return AudioFingerprinter();
});

class FingerprintResult {
  FingerprintResult({required this.rawFingerprint, required this.durationMs});
  final List<int> rawFingerprint;
  final int durationMs;

  Uint8List get fingerprintBytes {
    final uint32list = Uint32List.fromList(rawFingerprint);
    return uint32list.buffer.asUint8List();
  }
}

class AudioFingerprinter with LoggerMixin {
  AudioFingerprinter();

  String? _fpcalcPath;
  Future<void>? _initFuture;

  Future<String?> get fpcalcPath async {
    _initFuture ??= _ensureInitialized();
    await _initFuture;
    return _fpcalcPath;
  }

  Future<FingerprintResult?> calculateFingerprint(String filePath) async {
    final execPath = await fpcalcPath;
    if (execPath == null) {
      log.w('fpcalc is not initialized. Skipping fingerprint calculation.');
      return null;
    }

    try {
      final res = await Process.run(execPath, ['-json', '-raw', filePath]);
      if (res.exitCode != 0) {
        log.w('fpcalc execution failed on $filePath: ${res.stderr}');
        return null;
      }

      final parsed = jsonDecode(res.stdout);
      if (parsed is Map<String, dynamic>) {
        final duration = parsed['duration'];
        final fingerprint = parsed['fingerprint'];
        if (fingerprint is List && duration != null) {
          return FingerprintResult(
            rawFingerprint: List<int>.from(fingerprint),
            durationMs: (duration is num) ? (duration * 1000).round() : 0,
          );
        }
      }
    } catch (e) {
      log.w('Failed to calculate fingerprint for $filePath: $e');
    }
    return null;
  }

  int _popcount(int x) {
    x = x & 0xFFFFFFFF; // Ensure 32-bit
    x -= ((x >> 1) & 0x55555555);
    x = (((x >> 2) & 0x33333333) + (x & 0x33333333));
    x = (((x >> 4) + x) & 0x0F0F0F0F);
    x += (x >> 8);
    x += (x >> 16);
    return (x & 0x0000003F);
  }

  List<int>? parseRawFingerprint(Uint8List? bytes) {
    if (bytes == null || bytes.isEmpty) return null;
    if (bytes.offsetInBytes % 4 != 0) {
      final alignedBytes = Uint8List.fromList(bytes);
      return Uint32List.view(alignedBytes.buffer);
    }
    return Uint32List.view(bytes.buffer, bytes.offsetInBytes, bytes.lengthInBytes ~/ 4);
  }

  double compareRawFingerprints(List<int> fp1, List<int> fp2) {
    if (fp1.isEmpty || fp2.isEmpty) return 0.0;

    const int maxOffset = 40; 
    double maxSimilarity = 0.0;

    final int len1 = fp1.length;
    final int len2 = fp2.length;

    for (int offset = -maxOffset; offset <= maxOffset; offset++) {
      final int start1 = math.max(0, offset);
      final int start2 = math.max(0, -offset);
      final int overlapLen = math.min(len1 - start1, len2 - start2);

      if (overlapLen < 15) continue;

      int matchingBits = 0;
      for (int i = 0; i < overlapLen; i++) {
        final int val1 = fp1[start1 + i];
        final int val2 = fp2[start2 + i];
        final int diffBits = val1 ^ val2;
        matchingBits += (32 - _popcount(diffBits));
      }

      final double similarity = matchingBits / (overlapLen * 32);
      if (similarity > maxSimilarity) {
        maxSimilarity = similarity;
      }
    }

    return maxSimilarity;
  }

  Future<void> _ensureInitialized() async {
    // 1. Check if fpcalc is in PATH
    try {
      final res = await Process.run('fpcalc', ['-version']);
      if (res.exitCode == 0) {
        _fpcalcPath = 'fpcalc';
        log.i('Found system fpcalc in PATH.');
        return;
      }
    } catch (_) {}

    // 2. Check if fpcalc is already downloaded in Application Support Directory
    final appSupportDir = await getApplicationSupportDirectory();
    final binDir = Directory(p.join(appSupportDir.path, 'bin'));
    final exeName = Platform.isWindows ? 'fpcalc.exe' : 'fpcalc';
    final targetPath = p.join(binDir.path, exeName);
    final targetFile = File(targetPath);

    if (await targetFile.exists()) {
      try {
        final res = await Process.run(targetPath, ['-version']);
        if (res.exitCode == 0) {
          _fpcalcPath = targetPath;
          log.i('Found bundled fpcalc at $targetPath');
          return;
        }
      } catch (_) {}
    }

    // 3. Download and extract fpcalc
    log.i('fpcalc not found. Downloading AcoustID fpcalc binary...');
    try {
      await binDir.create(recursive: true);
      final url = _getDownloadUrl();
      final tempDir = await Directory.systemTemp.createTemp('fpcalc_install');
      final archiveName = Platform.isWindows ? 'fpcalc.zip' : 'fpcalc.tar.gz';
      final archivePath = p.join(tempDir.path, archiveName);

      log.i('Downloading fpcalc from $url...');
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();
      if (response.statusCode != 200) {
        throw Exception('Failed to download fpcalc: HTTP ${response.statusCode}');
      }
      final file = File(archivePath);
      final sink = file.openWrite();
      await response.pipe(sink);
      await sink.close();
      log.i('Download complete. Extracting archive...');

      final extractDir = p.join(tempDir.path, 'extracted');
      await Directory(extractDir).create(recursive: true);

      if (Platform.isWindows) {
        // Use PowerShell to extract zip
        final extractRes = await Process.run('powershell', [
          '-NoProfile',
          '-NonInteractive',
          '-Command',
          'Expand-Archive -Path "$archivePath" -DestinationPath "$extractDir" -Force'
        ]);
        if (extractRes.exitCode != 0) {
          throw Exception('Failed to extract ZIP via PowerShell: ${extractRes.stderr}');
        }
        
        final extractedExe = File(p.join(extractDir, 'chromaprint-fpcalc-1.6.0-windows-x86_64', 'fpcalc.exe'));
        if (!await extractedExe.exists()) {
          throw Exception('fpcalc.exe not found in extracted archive.');
        }
        await extractedExe.copy(targetPath);
      } else {
        // Use tar to extract tar.gz
        final extractRes = await Process.run('tar', [
          '-xzf',
          archivePath,
          '-C',
          extractDir
        ]);
        if (extractRes.exitCode != 0) {
          throw Exception('Failed to extract TAR via tar: ${extractRes.stderr}');
        }
        
        final platformDir = Platform.isMacOS
            ? 'chromaprint-fpcalc-1.6.0-macos-universal'
            : 'chromaprint-fpcalc-1.6.0-linux-x86_64';
            
        final extractedExe = File(p.join(extractDir, platformDir, 'fpcalc'));
        if (!await extractedExe.exists()) {
          throw Exception('fpcalc not found in extracted archive.');
        }
        await extractedExe.copy(targetPath);
        
        // Make executable
        await Process.run('chmod', ['+x', targetPath]);
      }

      // Cleanup
      await tempDir.delete(recursive: true);

      // Verify the installed executable
      final testRes = await Process.run(targetPath, ['-version']);
      if (testRes.exitCode == 0) {
        _fpcalcPath = targetPath;
        log.i('Successfully installed fpcalc version 1.6.0 at $targetPath');
      } else {
        throw Exception('Sanity check failed for installed fpcalc: ${testRes.stderr}');
      }
    } catch (e, s) {
      log.e('Failed to install fpcalc: $e', error: e, stackTrace: s);
      _fpcalcPath = null;
    }
  }

  String _getDownloadUrl() {
    const version = '1.6.0';
    if (Platform.isWindows) {
      return 'https://github.com/acoustid/chromaprint/releases/download/v$version/chromaprint-fpcalc-$version-windows-x86_64.zip';
    } else if (Platform.isMacOS) {
      return 'https://github.com/acoustid/chromaprint/releases/download/v$version/chromaprint-fpcalc-$version-macos-universal.tar.gz';
    } else if (Platform.isLinux) {
      return 'https://github.com/acoustid/chromaprint/releases/download/v$version/chromaprint-fpcalc-$version-linux-x86_64.tar.gz';
    }
    throw UnsupportedError('Unsupported platform: ${Platform.operatingSystem}');
  }
}
