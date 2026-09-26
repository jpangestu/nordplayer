import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nordplayer/config/app_config.dart';
import 'package:nordplayer/data/database/app_database.dart';
import 'package:nordplayer/data/services/indexer/library_indexer.dart';
import 'package:nordplayer/data/services/indexer/library_watcher.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;
  late LibraryIndexer libraryIndexer;
  late Directory tempDir1;
  late Directory tempDir2;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    container = ProviderContainer(overrides: [appDatabaseProvider.overrideWithValue(db)]);
    libraryIndexer = container.read(libraryIndexerProvider);
    tempDir1 = Directory.systemTemp.createTempSync('nordplayer_test_dir1_');
    tempDir2 = Directory.systemTemp.createTempSync('nordplayer_test_dir2_');
  });

  tearDown(() async {
    await db.close();
    container.dispose();
    try {
      if (tempDir1.existsSync()) tempDir1.deleteSync(recursive: true);
      if (tempDir2.existsSync()) tempDir2.deleteSync(recursive: true);
    } catch (_) {}
  });

  group('LibraryWatcher Tests', () {
    test('updateConfig handles enabling and disabling folder watching', () {
      final watcher = LibraryWatcher(libraryIndexer);

      // Initially enable watching with tempDir1
      final configWithDir1 = AppConfig(trackDirectories: [tempDir1.path], watchTrackDirectories: true);
      watcher.updateConfig(configWithDir1);

      // Now update config adding tempDir2 and removing tempDir1
      final configWithDir2 = AppConfig(trackDirectories: [tempDir2.path], watchTrackDirectories: true);
      watcher.updateConfig(configWithDir2);

      // Now disable watching altogether
      final configDisabled = AppConfig(trackDirectories: [tempDir2.path], watchTrackDirectories: false);
      watcher.updateConfig(configDisabled);

      watcher.dispose();
    });

    test('watchTrackDirectory skips non-existent directories gracefully', () {
      final watcher = LibraryWatcher(libraryIndexer);

      final nonExistentDir = '${tempDir1.path}/does_not_exist_xyz';
      watcher.watchTrackDirectory(nonExistentDir);

      // Should not throw or crash
      watcher.dispose();
    });

    test('stopWatchingTrackDirectory handles untracked directory gracefully', () {
      final watcher = LibraryWatcher(libraryIndexer);

      // Stopping directory that was never watched
      watcher.stopWatchingTrackDirectory('/unknown/path');
      watcher.dispose();
    });
  });
}
