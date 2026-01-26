import 'package:drift/drift.dart';
import 'package:suara/database/app_database.dart';
import 'package:suara/services/library_scanner.dart';

final _db = Database();

// Get all music paths
Future<List<String>> getMusicPaths() async {
  final folders = await _db.select(_db.folders).get();
  return folders.map((f) => f.path).toList();
}

// Saves folder -> Triggers Scan
Future<void> addPath(String newPath) async {
  // Save to Database
  await _db
      .into(_db.folders)
      .insert(
        FoldersCompanion(path: Value(newPath), isEnabled: const Value(true)),
        mode: InsertMode.insertOrIgnore,
      );

  // Trigger Scan immediately
  await _scanSpecificFolder(newPath);
}

Future<void> removePath(String pathToRemove) async {
  // Remove the folder from the configuration
  await (_db.delete(
    _db.folders,
  )..where((tbl) => tbl.path.equals(pathToRemove))).go();

  // Delete all songs that lived inside that folder
  // Use a LIKE query with a wildcard '%' at the end.
  await (_db.delete(
    _db.songs,
  )..where((tbl) => tbl.path.like('$pathToRemove%'))).go();

  print("Removed folder and all its songs: $pathToRemove");
}

Future<void> _scanSpecificFolder(String path) async {
  final knownFiles = await _db.getPathTimestampMap();

  // We create a config for JUST this one folder
  final config = ScanConfiguration([path], knownFiles);

  // Run the Isolate
  final result = await scanLibrary(config);

  // Update DB
  if (result.newOrUpdatedSongs.isNotEmpty) {
    await _db.insertSongs(result.newOrUpdatedSongs);
  }
  // (We don't need to handle deletes here, because adding a folder
  // shouldn't delete files from other folders)
}

Future<void> syncLibrary() async {
  final List<String> paths = await getMusicPaths();

  if (paths.isEmpty) return;

  print("SYNC: Starting Library Sync...");
  final stopwatch = Stopwatch()..start();

  // Get the Cache State (Map<Path, Timestamp>)
  final knownFiles = await _db.getPathTimestampMap();

  // Run the Isolate
  final config = ScanConfiguration(paths, knownFiles);
  final result = await scanLibrary(config);

  stopwatch.stop();
  print("SYNC: Scan finished in ${stopwatch.elapsedMilliseconds}ms.");
  print("SYNC: Found ${result.newOrUpdatedSongs.length} new/edited songs.");
  print("SYNC: Found ${result.deletedPaths.length} deleted songs.");

  // Write Changes to Database
  if (result.deletedPaths.isNotEmpty) {
    await _db.deleteSpecificSongs(result.deletedPaths);
  }

  if (result.newOrUpdatedSongs.isNotEmpty) {
    await _db.insertSongs(result.newOrUpdatedSongs);
  }
}
