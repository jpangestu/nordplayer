import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nordplayer/core/database/app_database.dart';
import 'package:nordplayer/features/settings/ignored_paths_viewmodel.dart';

void main() {
  group('IgnoredPathsViewModel', () {
    late AppDatabase db;
    late ProviderContainer container;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
        ],
      );

      // Seed ignored paths
      await db.into(db.ignoredPaths).insert(
            IgnoredPathsCompanion.insert(filePath: '/music/z_track.mp3'),
          );
      await db.into(db.ignoredPaths).insert(
            IgnoredPathsCompanion.insert(filePath: '/music/a_track.mp3'),
          );
    });

    tearDown(() async {
      await db.close();
      container.dispose();
    });

    test('ignoredPathsProvider returns sorted ignored paths', () async {
      final paths = await container.read(ignoredPathsProvider.future);
      expect(paths.length, equals(2));
      expect(paths[0].filePath, equals('/music/a_track.mp3'));
      expect(paths[1].filePath, equals('/music/z_track.mp3'));
    });

    test('restorePath removes single path from database', () async {
      final initialPaths = await container.read(ignoredPathsProvider.future);
      final target = initialPaths.first;

      final vm = container.read(ignoredPathsViewModelProvider);
      await vm.restorePath(target);

      final updated = await container.read(ignoredPathsProvider.future);
      expect(updated.length, equals(1));
      expect(updated.first.filePath, equals('/music/z_track.mp3'));
    });

    test('restoreAll removes all paths from database', () async {
      final initialPaths = await container.read(ignoredPathsProvider.future);
      final vm = container.read(ignoredPathsViewModelProvider);

      await vm.restoreAll(initialPaths);

      final updated = await container.read(ignoredPathsProvider.future);
      expect(updated, isEmpty);
    });

    test('reignorePaths inserts paths back into database', () async {
      final vm = container.read(ignoredPathsViewModelProvider);
      await vm.reignorePaths(['/music/new_ignored.flac']);

      final updated = await container.read(ignoredPathsProvider.future);
      expect(updated.any((p) => p.filePath == '/music/new_ignored.flac'), isTrue);
    });
  });
}
