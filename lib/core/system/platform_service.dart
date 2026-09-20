import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nordplayer/core/system/logger.dart';

/// Platform-level operating system actions (file manager integration, system dialogs).
class PlatformService with LoggerMixin {
  const PlatformService();

  /// Reveals the file at [filePath] inside the platform's default file manager
  /// (Explorer on Windows, Finder on macOS, DBus/xdg-open on Linux).
  Future<void> showInFolder(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      log.w('Cannot reveal in file manager - file does not exist: $filePath');
      return;
    }

    try {
      if (Platform.isWindows) {
        final winPath = filePath.replaceAll('/', r'\');
        await Process.run('explorer.exe', ['/select,', winPath]);
      } else if (Platform.isMacOS) {
        await Process.run('open', ['-R', filePath]);
      } else if (Platform.isLinux) {
        try {
          await Process.run('dbus-send', [
            '--session',
            '--dest=org.freedesktop.FileManager1',
            '--type=method_call',
            '/org/freedesktop/FileManager1',
            'org.freedesktop.FileManager1.ShowItems',
            'array:string:file://$filePath',
            'string:',
          ]);
        } catch (dbusError) {
          log.d('DBus show items failed, falling back to xdg-open: $dbusError');
          final folderPath = file.parent.path;
          await Process.run('xdg-open', [folderPath]);
        }
      }
    } catch (e, st) {
      log.e('Failed to reveal file in file manager: $filePath', error: e, stackTrace: st);
    }
  }
}

/// Riverpod provider exposing the singleton [PlatformService].
final platformServiceProvider = Provider<PlatformService>((ref) => const PlatformService());

/// Standalone convenience helper for callers without direct `Ref` access.
Future<void> showInFolder(String filePath) => const PlatformService().showInFolder(filePath);
