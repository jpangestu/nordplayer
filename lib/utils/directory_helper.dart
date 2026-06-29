import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Get the configuration directory path based on platform standards.
/// - Windows: AppData/Roaming/Nordplayer
/// - Linux: ~/.config/nordplayer
/// - Others: Default Application Support Directory
Future<Directory> getConfigDirectory() async {
  Directory dir;
  if (Platform.isLinux) {
    final xdgConfig = Platform.environment['XDG_CONFIG_HOME'];
    if (xdgConfig != null && xdgConfig.isNotEmpty) {
      dir = Directory(p.join(xdgConfig, 'nordplayer'));
    } else {
      final home = Platform.environment['HOME'];
      if (home != null) {
        dir = Directory(p.join(home, '.config', 'nordplayer'));
      } else {
        dir = await getApplicationSupportDirectory();
      }
    }
  } else {
    dir = await getApplicationSupportDirectory();
  }

  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }
  return dir;
}

/// Get the database directory path based on platform standards.
/// - Windows: AppData/Local/Nordplayer (machine-local)
/// - Others: Default Application Support Directory (e.g. ~/.local/share on Linux)
Future<Directory> getDatabaseDirectory() async {
  Directory dir;
  if (Platform.isWindows) {
    final localAppData = Platform.environment['LOCALAPPDATA'];
    if (localAppData != null) {
      dir = Directory(p.join(localAppData, 'Nordplayer'));
    } else {
      dir = await getApplicationSupportDirectory();
    }
  } else {
    dir = await getApplicationSupportDirectory();
  }

  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }
  return dir;
}
