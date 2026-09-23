import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Stateless service responsible for atomic file read and write operations.
class ConfigFileService {
  const ConfigFileService();

  bool exists(File file) => file.existsSync();

  Future<String> readAsString(File file) => file.readAsString();

  String readAsStringSync(File file) => file.readAsStringSync();

  /// Writes content to disk atomically via a temporary file replacement.
  Future<void> writeAtomic(File file, String content) async {
    final tempFile = File('${file.path}.tmp');
    await tempFile.writeAsString(content, flush: true);
    if (await file.exists()) {
      await file.delete();
    }
    await tempFile.rename(file.path);
  }

  /// Synchronously writes content to disk atomically.
  void writeAtomicSync(File file, String content) {
    final tempFile = File('${file.path}.tmp');
    tempFile.writeAsStringSync(content, flush: true);
    if (file.existsSync()) {
      file.deleteSync();
    }
    tempFile.renameSync(file.path);
  }
}

/// Riverpod provider for [ConfigFileService].
final configFileServiceProvider = Provider<ConfigFileService>((ref) {
  return const ConfigFileService();
});
