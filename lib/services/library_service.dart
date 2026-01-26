import 'package:drift/drift.dart';
import 'package:path_provider/path_provider.dart';
import 'package:suara/database/app_database.dart';
import 'package:suara/services/library_scanner.dart';

/// The "Manager" class.
/// Orchestrates the communication between the UI, the Database, and the Background Scanner.
class LibraryService {
  // ===========================================================================
  // SINGLETON SETUP
  // ===========================================================================
  
  static final LibraryService _instance = LibraryService._internal();
  factory LibraryService() => _instance;
  LibraryService._internal();

  final _db = Database();

  // ===========================================================================
  // FOLDER MANAGEMENT (Paths)
  // ===========================================================================

  /// Returns a list of absolute paths currently being watched by the app.
  Future<List<String>> getMusicPaths() async {
    final folders = await _db.select(_db.folders).get();
    return folders.map((f) => f.path).toList();
  }

  /// Adds a new folder to the watch list and immediately triggers a scan for it.
  Future<void> addPath(String newPath) async {
    // 1. Save to Database (InsertOrIgnore prevents duplicates)
    await _db.into(_db.folders).insert(
          FoldersCompanion(
            path: Value(newPath),
            isEnabled: const Value(true),
          ),
          mode: InsertMode.insertOrIgnore,
        );

    // 2. Trigger Scan immediately so the user sees their music
    await _scanSpecificFolder(newPath);
  }

  /// Removes a folder and cascades the deletion to all songs inside it.
  Future<void> removePath(String pathToRemove) async {
    await _db.transaction(() async {
      // Delete the Folder record
      await (_db.delete(_db.folders)
            ..where((tbl) => tbl.path.equals(pathToRemove)))
          .go();

      // Delete songs that technically reside in that folder path
      // Note: We use 'like' to match subdirectories too.
      await (_db.delete(_db.songs)
            ..where((tbl) => tbl.path.like('$pathToRemove%')))
          .go();
    });

    print("Removed folder and all its songs: $pathToRemove");
  }

  // ===========================================================================
  // SYNC LOGIC (The Heavy Lifter)
  // ===========================================================================

  /// Scans ALL registered folders for changes.
  /// 
  /// This is typically called on app startup or "Pull to Refresh".
  /// It compares file timestamps to avoid re-parsing unchanged files.
  Future<void> syncLibrary() async {
    final List<String> paths = await getMusicPaths();
    if (paths.isEmpty) return;

    print("SYNC: Starting Library Sync...");
    final stopwatch = Stopwatch()..start();

    // --- STEP 1: GATHER CONTEXT ---
    // We need the current DB state and the cache path to pass to the Isolate.
    final knownFiles = await _db.getPathTimestampMap();
    final tempDir = await getApplicationCacheDirectory();
    final cachePath = tempDir.path;

    // TODO: Connect this to real User Preferences later
    final splitArtist = true;

    // --- STEP 2: RUN BACKGROUND SCAN ---
    // We hand off the heavy work to the Isolate (library_scanner.dart).
    final config = ScanConfiguration(paths, knownFiles, cachePath, splitArtist);
    final result = await scanLibrary(config); 

    stopwatch.stop();
    print("SYNC: Scan finished in ${stopwatch.elapsedMilliseconds}ms.");

    // --- STEP 3: APPLY CHANGES ---
    
    // A. Handle Deletions (Files removed from disk)
    if (result.deletedPaths.isNotEmpty) {
      await _db.deleteSpecificSongs(result.deletedPaths);
    }

    // B. Handle Updates (New or Changed files)
    if (result.newOrUpdatedSongs.isNotEmpty) {
      await _db.insertScannedSongs(result.newOrUpdatedSongs);
    }
  }

  // ===========================================================================
  // PRIVATE HELPERS
  // ===========================================================================

  Future<void> _scanSpecificFolder(String path) async {
    final knownFiles = await _db.getPathTimestampMap();
    final tempDir = await getApplicationCacheDirectory();
    
    // TODO: Connect this to real User Preferences later
    final splitArtist = true;

    final config = ScanConfiguration(
      [path], 
      knownFiles, 
      tempDir.path, 
      splitArtist,
    );

    final result = await scanLibrary(config);

    if (result.newOrUpdatedSongs.isNotEmpty) {
      await _db.insertScannedSongs(result.newOrUpdatedSongs);
    }
  }
}