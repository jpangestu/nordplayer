import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nordplayer/core/services/background_task_service.dart';
import 'package:nordplayer/core/services/config_service.dart';
import 'package:nordplayer/features/settings/library_indexer_viewmodel.dart';
import 'package:nordplayer/services/library_indexer/library_indexer.dart';
import 'package:nordplayer/services/library_watcher.dart';

class FakeLibraryIndexer extends Fake implements LibraryIndexer {
  bool scanCalled = false;
  bool reindexCalled = false;
  bool fingerprintCalled = false;
  String? lastMarkedMissingPath;

  @override
  Future<void> scanLibrary({void Function(int processed, int total)? onProgress}) async {
    scanCalled = true;
  }

  @override
  Future<void> reindexTracks({void Function(int processed, int total)? onProgress}) async {
    reindexCalled = true;
  }

  @override
  Future<void> generateMissingFingerprints({void Function(int processed, int total)? onProgress}) async {
    fingerprintCalled = true;
  }

  @override
  Future<void> markTracksInDirectoryAsMissing(String path) async {
    lastMarkedMissingPath = path;
  }
}

class FakeLibraryWatcher extends Fake implements LibraryWatcher {
  String? lastStoppedPath;

  @override
  void stopWatchingTrackDirectory(String path) {
    lastStoppedPath = path;
  }
}

void main() {
  group('LibraryIndexerViewModel', () {
    late FakeLibraryIndexer fakeIndexer;
    late FakeLibraryWatcher fakeWatcher;
    late Directory tempDir;
    late ProviderContainer container;

    setUp(() async {
      fakeIndexer = FakeLibraryIndexer();
      fakeWatcher = FakeLibraryWatcher();
      tempDir = await Directory.systemTemp.createTemp('nordplayer_indexer_test_');

      container = ProviderContainer(
        overrides: [
          initialAppConfigProvider.overrideWithValue(
            AppConfig(trackDirectories: ['/music/folder1'], artistDelimiters: [';', '/'], artistExclusions: ['AC/DC']),
          ),
          configDirectoryProvider.overrideWithValue(tempDir),
          libraryIndexerProvider.overrideWithValue(fakeIndexer),
          libraryWatcherProvider.overrideWithValue(fakeWatcher),
        ],
      );
    });

    tearDown(() async {
      container.dispose();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('addFolders adds new unique paths and triggers scan', () async {
      final vm = container.read(libraryIndexerViewModelProvider);
      final changed = await vm.addFolders(['/music/folder2', '/music/folder1']);

      expect(changed, isTrue);
      expect(fakeIndexer.scanCalled, isTrue);

      final config = container.read(configServiceProvider);
      expect(config.trackDirectories, equals(['/music/folder1', '/music/folder2']));
    });

    test('addFolders returns false when no new paths are added', () async {
      final vm = container.read(libraryIndexerViewModelProvider);
      final changed = await vm.addFolders(['/music/folder1']);

      expect(changed, isFalse);
      expect(fakeIndexer.scanCalled, isFalse);
    });

    test('removeFolder updates config, stops watcher, and marks tracks missing', () async {
      final vm = container.read(libraryIndexerViewModelProvider);
      await vm.removeFolder('/music/folder1');

      final config = container.read(configServiceProvider);
      expect(config.trackDirectories, isEmpty);
      expect(fakeWatcher.lastStoppedPath, equals('/music/folder1'));
      expect(fakeIndexer.lastMarkedMissingPath, equals('/music/folder1'));
    });

    test('addDelimiter adds unique delimiter and rejects duplicate or empty', () {
      final vm = container.read(libraryIndexerViewModelProvider);

      expect(vm.addDelimiter(''), isFalse);
      expect(vm.addDelimiter(';'), isFalse);
      expect(vm.addDelimiter(' feat. '), isTrue);

      final config = container.read(configServiceProvider);
      expect(config.artistDelimiters, contains('feat.'));
    });

    test('removeDelimiter and resetDelimitersToDefault work properly', () {
      final vm = container.read(libraryIndexerViewModelProvider);
      vm.removeDelimiter(';');

      var config = container.read(configServiceProvider);
      expect(config.artistDelimiters, equals(['/']));

      vm.resetDelimitersToDefault();
      config = container.read(configServiceProvider);
      expect(config.artistDelimiters, equals(AppConfig.defaultArtistDelimiters));
    });

    test('addExclusion validates duplicates case-insensitively and updates config', () {
      final vm = container.read(libraryIndexerViewModelProvider);

      expect(vm.addExclusion(''), isFalse);
      expect(vm.addExclusion('ac/dc'), isFalse);
      expect(vm.addExclusion('Guns N\' Roses'), isTrue);

      final config = container.read(configServiceProvider);
      expect(config.artistExclusions, contains('Guns N\' Roses'));
    });

    test('removeExclusion and resetExclusionsToDefault work properly', () {
      final vm = container.read(libraryIndexerViewModelProvider);
      vm.removeExclusion('AC/DC');

      var config = container.read(configServiceProvider);
      expect(config.artistExclusions, isEmpty);

      vm.resetExclusionsToDefault();
      config = container.read(configServiceProvider);
      expect(config.artistExclusions, equals(AppConfig.defaultArtistExclusions));
    });

    test('toggleWatchFolders updates watchTrackDirectories setting', () {
      final vm = container.read(libraryIndexerViewModelProvider);
      vm.toggleWatchFolders(false);
      expect(container.read(configServiceProvider).watchTrackDirectories, isFalse);

      vm.toggleWatchFolders(true);
      expect(container.read(configServiceProvider).watchTrackDirectories, isTrue);
    });

    test('triggerScan, triggerReindex, and triggerFingerprint dispatch to indexer', () {
      final vm = container.read(libraryIndexerViewModelProvider);

      expect(vm.triggerScan(), isTrue);
      expect(fakeIndexer.scanCalled, isTrue);

      expect(vm.triggerReindex(), isTrue);
      expect(fakeIndexer.reindexCalled, isTrue);

      expect(vm.triggerFingerprint(), isTrue);
      expect(fakeIndexer.fingerprintCalled, isTrue);
    });

    test('task status providers and isTaskRunning reflect active background tasks', () {
      expect(container.read(isLibraryScanningProvider), isFalse);
      expect(container.read(isLibraryReindexingProvider), isFalse);
      expect(container.read(isLibraryFingerprintingProvider), isFalse);
      expect(container.read(isAnyLibraryTaskRunningProvider), isFalse);
      expect(container.read(libraryIndexerViewModelProvider).isTaskRunning, isFalse);

      final bgService = container.read(backgroundTaskServiceProvider.notifier);
      bgService.startTask(id: 'library-scan', name: 'Scan');

      expect(container.read(isLibraryScanningProvider), isTrue);
      expect(container.read(isAnyLibraryTaskRunningProvider), isTrue);
      expect(container.read(libraryIndexerViewModelProvider).isTaskRunning, isTrue);

      bgService.completeTask('library-scan');
      expect(container.read(isLibraryScanningProvider), isFalse);
      expect(container.read(isAnyLibraryTaskRunningProvider), isFalse);
    });
  });
}
