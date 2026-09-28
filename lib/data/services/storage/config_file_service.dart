import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

/// Stateless service responsible for atomic file read, write, and backup operations.
class const ConfigFileService() {
  bool exists(File file) => file.existsSync();

  Future<String> readAsString(File file) => file.readAsString();

  String readAsStringSync(File file) => file.readAsStringSync();

  /// Writes content to disk atomically via a temporary file replacement with Windows fallback.
  Future<void> writeAtomic(File file, String content) async {
    final tempFile = File('${file.path}.tmp');
    await tempFile.writeAsString(content, flush: true);
    try {
      try {
        await tempFile.rename(file.path);
      } on FileSystemException {
        // Fallback to copy and delete if target is locked or across volumes on Windows
        await tempFile.copy(file.path);
        await tempFile.delete();
      }
    } catch (_) {
      // Direct write fallback
      await file.writeAsString(content, flush: true);
      if (tempFile.existsSync()) {
        await tempFile.delete();
      }
    }
  }

  /// Synchronously writes content to disk atomically with Windows fallback.
  void writeAtomicSync(File file, String content) {
    final tempFile = File('${file.path}.tmp');
    tempFile.writeAsStringSync(content, flush: true);
    try {
      try {
        tempFile.renameSync(file.path);
      } on FileSystemException {
        tempFile.copySync(file.path);
        tempFile.deleteSync();
      }
    } catch (_) {
      file.writeAsStringSync(content, flush: true);
      if (tempFile.existsSync()) {
        tempFile.deleteSync();
      }
    }
  }

  /// Creates a timestamped backup of the given file in [backupDir].
  Future<void> backupFile(File file, Directory backupDir, {String prefix = 'invalid_config'}) async {
    if (!file.existsSync()) return;
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final backupPath = p.join(backupDir.path, '$prefix.$timestamp.json');
      await file.copy(backupPath);
    } catch (_) {
      // Best-effort backup
    }
  }
}

/// Riverpod provider for [ConfigFileService].
final configFileServiceProvider = Provider<ConfigFileService>((ref) {
  return const ConfigFileService();
});
