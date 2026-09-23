import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nordplayer/core/database/app_database.dart';
import 'package:nordplayer/features/settings/library_indexer/ignored_paths_viewmodel.dart';

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

    test('initial state loads and returns sorted ignored paths', () async {
      final vm = container.read(ignoredPathsViewModelProvider.notifier);
      await vm.loadIgnoredPaths();

      final state = container.read(ignoredPathsViewModelProvider);
      expect(state.isLoading, isFalse);
      expect(state.paths.length, equals(2));
      expect(state.paths[0].filePath, equals('/music/a_track.mp3'));
      expect(state.paths[1].filePath, equals('/music/z_track.mp3'));
      expect(state.showList, isTrue);
      expect(state.showRestoreAll, isTrue);
      expect(state.showEmptyMessage, isFalse);
    });

    test('restorePath updates optimistic state and removes path from database', () async {
      final vm = container.read(ignoredPathsViewModelProvider.notifier);
      await vm.loadIgnoredPaths();

      final initialPaths = container.read(ignoredPathsViewModelProvider).paths;
      final target = initialPaths.first;

      await vm.restorePath(target);

      final state = container.read(ignoredPathsViewModelProvider);
      expect(state.manuallyRestoredPaths, contains(target.filePath));
      expect(state.filteredPaths.length, equals(1));
      expect(state.filteredPaths.first.filePath, equals('/music/z_track.mp3'));

      final dbRemaining = await db.select(db.ignoredPaths).get();
      expect(dbRemaining.length, equals(1));
      expect(dbRemaining.first.filePath, equals('/music/z_track.mp3'));
    });

    test('restoreAll optimistically marks all restored and deletes from database', () async {
      final vm = container.read(ignoredPathsViewModelProvider.notifier);
      await vm.loadIgnoredPaths();

      final initialPaths = container.read(ignoredPathsViewModelProvider).paths;
      await vm.restoreAll(initialPaths);

      final state = container.read(ignoredPathsViewModelProvider);
      expect(state.filteredPaths, isEmpty);
      expect(state.showEmptyMessage, isTrue);

      final dbRemaining = await db.select(db.ignoredPaths).get();
      expect(dbRemaining, isEmpty);
    });

    test('reignorePaths inserts paths back into database and updates state', () async {
      final vm = container.read(ignoredPathsViewModelProvider.notifier);
      await vm.loadIgnoredPaths();

      await vm.reignorePaths(['/music/new_ignored.flac']);

      final state = container.read(ignoredPathsViewModelProvider);
      expect(state.paths.any((p) => p.filePath == '/music/new_ignored.flac'), isTrue);

      final dbAll = await db.select(db.ignoredPaths).get();
      expect(dbAll.any((p) => p.filePath == '/music/new_ignored.flac'), isTrue);
    });
  });
}
