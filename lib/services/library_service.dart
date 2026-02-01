import 'package:drift/drift.dart';
import 'package:path_provider/path_provider.dart';
import 'package:suara/database/app_database.dart';
import 'package:suara/services/library_scanner.dart'; // Ensure this imports the NEW scanner

class LibraryService {
  static final LibraryService _instance = LibraryService._internal();
  factory LibraryService() => _instance;
  LibraryService._internal();

  final _db = Database();

  // CONCURRENCY LOCK: Prevents multiple scans from running simultaneously
  bool _isScanning = false;

  // ===========================================================================
  // FOLDER MANAGEMENT
  // ===========================================================================

  /// Returns a list of absolute paths currently being watched by the app.
  Future<List<String>> getMusicPaths() async {
    final folders = await _db.select(_db.folders).get();
    return folders.map((f) => f.path).toList();
  }

  /// Adds a new folder to the watch list and immediately triggers a scan for it.
  Future<void> addPath(String newPath) async {
    await _db
        .into(_db.folders)
        .insert(
          FoldersCompanion(path: Value(newPath), isEnabled: const Value(true)),
          mode: InsertMode.insertOrIgnore, // InsertOrIgnore prevents duplicates
        );

    // Trigger a targeted scan for this new folder
    await _scanSpecificFolder(newPath);
  }

  /// Removes a folder and cascades the deletion to all songs inside it.
  Future<void> removePath(String pathToRemove) async {
    await _db.transaction(() async {
      await (_db.delete(
        _db.folders,
      )..where((tbl) => tbl.path.equals(pathToRemove))).go();

      await (_db.delete(
        _db.songs,
      )..where((tbl) => tbl.path.like('$pathToRemove%'))).go();
    });
  }

  // ===========================================================================
  // SYNC LOGIC (The Stream Consumer)
  // ===========================================================================

  /// Scans ALL registered folders for changes.
  ///
  /// This is typically called on app startup or "Pull to Refresh".
  /// It compares file timestamps to avoid re-parsing unchanged files.
  Future<void> syncLibrary() async {
    // If a scan is already running (e.g., from a previous tab switch), abort.
    if (_isScanning) {
      print("SYNC: Scan already in progress. Skipping.");
      return;
    }
    _isScanning = true;

    try {
      final List<String> paths = await getMusicPaths();
      if (paths.isEmpty) return;

      print("SYNC: Starting Streamed Library Sync...");
      final stopwatch = Stopwatch()..start();

      final knownFiles = await _db.getPathTimestampMap();
      final tempDir = await getApplicationCacheDirectory();

      // TODO: Connect to User Prefs
      final splitArtist = true;

      // THE STREAM LISTENER (The "Conveyor Belt")
      // 'await for' pauses execution here only until the NEXT batch arrives.
      //
      // Mechanism:
      // 1. Isolate sends a batch of 50 songs.
      // 2. This loop wakes up, inserts them, and updates the UI immediately.
      // 3. This loop pauses again, letting the Main Thread breathe while the Isolate works.
      //
      // Result: The user sees the library growing in real-time without UI jank.
      final stream = scanLibraryStream(
        paths,
        knownFiles,
        tempDir.path,
        splitArtist,
      );

      // This loop runs every time the Isolate sends a batch (approx every 50 songs)
      await for (final event in stream) {
        if (event is ScanBatch) {
          // A. Insert the batch immediately
          // The UI will update instantly via the Database Stream
          await _db.insertScannedSongs(event.songs);
        } else if (event is ScanDone) {
          // B. Handle Deletions at the end
          if (event.deletedPaths.isNotEmpty) {
            await _db.deleteSpecificSongs(event.deletedPaths);
          }
        }
      }

      stopwatch.stop();
      print("SYNC: Finished in ${stopwatch.elapsedMilliseconds}ms.");
    } catch (e) {
      print("SYNC ERROR: $e");
    } finally {
      // Always reset scan status, even if the scan crashes.
      _isScanning = false;
    }
  }

  // ===========================================================================
  // PRIVATE HELPERS
  // ===========================================================================

  Future<void> _scanSpecificFolder(String path) async {
    // We don't necessarily need the lock here since adding a folder
    // is a deliberate user action, but it's safer to respect it or handle it.
    // For now, we'll allow it to run parallel or just reuse the logic.

    final knownFiles = await _db.getPathTimestampMap();
    final tempDir = await getApplicationCacheDirectory();
    // TODO: Connect to User Prefs
    final splitArtist = true;

    final stream = scanLibraryStream(
      [path],
      knownFiles,
      tempDir.path,
      splitArtist,
    );

    await for (final event in stream) {
      if (event is ScanBatch) {
        await _db.insertScannedSongs(event.songs);
      }
      // Don't handle deletions for a single-folder add
    }
  }
}
