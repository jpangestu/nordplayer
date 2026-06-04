import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Get the configuration directory path based on platform standards.
/// - Windows: AppData/Roaming/Nordplayer
/// - Linux: ~/.config/nordplayer
/// - Others: Default Application Support Directory
Future<Directory> getConfigDirectory() async {
  if (Platform.isLinux) {
    final xdgConfig = Platform.environment['XDG_CONFIG_HOME'];
    if (xdgConfig != null && xdgConfig.isNotEmpty) {
      return Directory(p.join(xdgConfig, 'nordplayer'));
    }
    final home = Platform.environment['HOME'];
    if (home != null) {
      return Directory(p.join(home, '.config', 'nordplayer'));
    }
  }
  return await getApplicationSupportDirectory();
}

/// Get the database directory path based on platform standards.
/// - Windows: AppData/Local/Nordplayer (machine-local)
/// - Others: Default Application Support Directory (e.g. ~/.local/share on Linux)
Future<Directory> getDatabaseDirectory() async {
  if (Platform.isWindows) {
    final localAppData = Platform.environment['LOCALAPPDATA'];
    if (localAppData != null) {
      return Directory(p.join(localAppData, 'Nordplayer'));
    }
  }
  return await getApplicationSupportDirectory();
}
