import 'package:drift/drift.dart';
import 'package:path_provider/path_provider.dart'; // Needed for getApplicationCacheDirectory
import 'package:suara/database/app_database.dart';
import 'package:suara/services/library_scanner.dart';

class LibraryService {
  // Singleton Pattern
  static final LibraryService _instance = LibraryService._internal();
  factory LibraryService() => _instance;
  LibraryService._internal();

  final _db = Database();

  // --- Public Methods ---

  Future<List<String>> getMusicPaths() async {
    final folders = await _db.select(_db.folders).get();
    return folders.map((f) => f.path).toList();
  }

  Future<void> addPath(String newPath) async {
    // Save to Database
    await _db.into(_db.folders).insert(
          FoldersCompanion(
            path: Value(newPath),
            isEnabled: const Value(true),
          ),
          mode: InsertMode.insertOrIgnore,
        );

    // Trigger Scan immediately
    await _scanSpecificFolder(newPath);
  }

  Future<void> removePath(String pathToRemove) async {
    await _db.transaction(() async {
      await (_db.delete(_db.folders)..where((tbl) => tbl.path.equals(pathToRemove))).go();

      // Delete songs starting with this path
      await (_db.delete(_db.songs)..where((tbl) => tbl.path.like('$pathToRemove%'))).go();
    });

    print("Removed folder and all its songs: $pathToRemove");
  }

  Future<void> syncLibrary() async {
    final List<String> paths = await getMusicPaths();
    if (paths.isEmpty) return;

    print("SYNC: Starting Library Sync...");
    final stopwatch = Stopwatch()..start();

    final knownFiles = await _db.getPathTimestampMap();

    // GET CACHE PATH (Main Thread)
    final tempDir = await getApplicationCacheDirectory();
    final cachePath = tempDir.path;

    // PASS IT TO CONFIG
    final config = ScanConfiguration(paths, knownFiles, cachePath);
    
    final result = await scanLibrary(config); // Ensure this matches your scanner function name

    stopwatch.stop();
    print("SYNC: Scan finished in ${stopwatch.elapsedMilliseconds}ms.");

    if (result.deletedPaths.isNotEmpty) {
      await _db.deleteSpecificSongs(result.deletedPaths);
    }

    if (result.newOrUpdatedSongs.isNotEmpty) {
      await _db.insertSongs(result.newOrUpdatedSongs);
    }
  }

  // --- Private Helper ---

  Future<void> _scanSpecificFolder(String path) async {
    final knownFiles = await _db.getPathTimestampMap();

    final tempDir = await getApplicationCacheDirectory();
    final cachePath = tempDir.path;

    final config = ScanConfiguration([path], knownFiles, cachePath);

    final result = await scanLibrary(config);

    if (result.newOrUpdatedSongs.isNotEmpty) {
      await _db.insertSongs(result.newOrUpdatedSongs);
    }
  }
}