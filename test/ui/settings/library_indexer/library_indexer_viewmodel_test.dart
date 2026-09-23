import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nordplayer/data/services/system/background_task_service.dart';
import 'package:nordplayer/data/services/system/config_service.dart';
import 'package:nordplayer/data/repositories/config_repository.dart';
import 'package:nordplayer/ui/settings/library_indexer/library_indexer_viewmodel.dart';
import 'package:nordplayer/data/services/indexer/library_indexer.dart';
import 'package:nordplayer/data/services/indexer/library_watcher.dart';

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

class FakeConfigRepository implements ConfigRepository {
  final StreamController<AppConfig> _configController = StreamController<AppConfig>.broadcast();
  AppConfig _config;

  FakeConfigRepository(this._config);

  @override
  AppConfig get currentConfig => _config;

  @override
  Stream<AppConfig> watchConfig() => _configController.stream;

  @override
  void updateConfig(AppConfig newConfig) {
    _config = newConfig;
    _configController.add(newConfig);
  }

  @override
  Future<void> flush() async {}

  void dispose() {
    _configController.close();
  }
}

void main() {
  group('LibraryIndexerViewModel', () {
    late FakeLibraryIndexer fakeIndexer;
    late FakeLibraryWatcher fakeWatcher;
    late FakeConfigRepository fakeConfigRepo;
    late ProviderContainer container;

    setUp(() {
      fakeIndexer = FakeLibraryIndexer();
      fakeWatcher = FakeLibraryWatcher();
      fakeConfigRepo = FakeConfigRepository(
        AppConfig(
          trackDirectories: ['/music/folder1'],
          watchTrackDirectories: true,
          artistDelimiters: [';', '/'],
          artistExclusions: ['AC/DC'],
          adaptiveBg: false,
        ),
      );

      container = ProviderContainer(
        overrides: [
          configRepositoryProvider.overrideWithValue(fakeConfigRepo),
          libraryIndexerProvider.overrideWithValue(fakeIndexer),
          libraryWatcherProvider.overrideWithValue(fakeWatcher),
        ],
      );
    });

    tearDown(() {
      container.dispose();
      fakeConfigRepo.dispose();
    });

    test('initial state reflects configuration and task statuses', () {
      final state = container.read(libraryIndexerViewModelProvider);
      expect(state.trackDirectories, equals(['/music/folder1']));
      expect(state.watchTrackDirectories, isTrue);
      expect(state.artistDelimiters, equals([';', '/']));
      expect(state.artistExclusions, equals(['AC/DC']));
      expect(state.isScanning, isFalse);
      expect(state.isReindexing, isFalse);
      expect(state.isFingerprinting, isFalse);
      expect(state.isAnyTaskRunning, isFalse);
      expect(state.adaptiveBg, isFalse);
    });

    test('addFolders adds new unique paths and triggers scan', () async {
      final vm = container.read(libraryIndexerViewModelProvider.notifier);
      final changed = await vm.addFolders(['/music/folder2', '/music/folder1']);

      expect(changed, isTrue);
      expect(fakeIndexer.scanCalled, isTrue);

      await Future<void>.delayed(Duration.zero);
      final state = container.read(libraryIndexerViewModelProvider);
      expect(state.trackDirectories, equals(['/music/folder1', '/music/folder2']));
    });

    test('addFolders returns false when no new paths are added', () async {
      final vm = container.read(libraryIndexerViewModelProvider.notifier);
      final changed = await vm.addFolders(['/music/folder1']);

      expect(changed, isFalse);
      expect(fakeIndexer.scanCalled, isFalse);
    });

    test('removeFolder updates config, stops watcher, and marks tracks missing', () async {
      final vm = container.read(libraryIndexerViewModelProvider.notifier);
      await vm.removeFolder('/music/folder1');

      await Future<void>.delayed(Duration.zero);
      final state = container.read(libraryIndexerViewModelProvider);
      expect(state.trackDirectories, isEmpty);
      expect(fakeWatcher.lastStoppedPath, equals('/music/folder1'));
      expect(fakeIndexer.lastMarkedMissingPath, equals('/music/folder1'));
    });

    test('addDelimiter adds unique delimiter and rejects duplicate or empty', () async {
      final vm = container.read(libraryIndexerViewModelProvider.notifier);

      expect(vm.addDelimiter(''), isFalse);
      expect(vm.addDelimiter(';'), isFalse);
      expect(vm.addDelimiter(' feat. '), isTrue);

      await Future<void>.delayed(Duration.zero);
      final state = container.read(libraryIndexerViewModelProvider);
      expect(state.artistDelimiters, contains('feat.'));
    });

    test('removeDelimiter and resetDelimitersToDefault work properly', () async {
      final vm = container.read(libraryIndexerViewModelProvider.notifier);
      vm.removeDelimiter(';');

      await Future<void>.delayed(Duration.zero);
      var state = container.read(libraryIndexerViewModelProvider);
      expect(state.artistDelimiters, equals(['/']));

      vm.resetDelimitersToDefault();
      await Future<void>.delayed(Duration.zero);
      state = container.read(libraryIndexerViewModelProvider);
      expect(state.artistDelimiters, equals(AppConfig.defaultArtistDelimiters));
    });

    test('addExclusion validates duplicates case-insensitively and updates config', () async {
      final vm = container.read(libraryIndexerViewModelProvider.notifier);

      expect(vm.addExclusion(''), isFalse);
      expect(vm.addExclusion('ac/dc'), isFalse);
      expect(vm.addExclusion('Guns N\' Roses'), isTrue);

      await Future<void>.delayed(Duration.zero);
      final state = container.read(libraryIndexerViewModelProvider);
      expect(state.artistExclusions, contains('Guns N\' Roses'));
    });

    test('removeExclusion and resetExclusionsToDefault work properly', () async {
      final vm = container.read(libraryIndexerViewModelProvider.notifier);
      vm.removeExclusion('AC/DC');

      await Future<void>.delayed(Duration.zero);
      var state = container.read(libraryIndexerViewModelProvider);
      expect(state.artistExclusions, isEmpty);

      vm.resetExclusionsToDefault();
      await Future<void>.delayed(Duration.zero);
      state = container.read(libraryIndexerViewModelProvider);
      expect(state.artistExclusions, equals(AppConfig.defaultArtistExclusions));
    });

    test('toggleWatchFolders updates watchTrackDirectories setting', () async {
      final vm = container.read(libraryIndexerViewModelProvider.notifier);
      vm.toggleWatchFolders(false);

      await Future<void>.delayed(Duration.zero);
      expect(container.read(libraryIndexerViewModelProvider).watchTrackDirectories, isFalse);

      vm.toggleWatchFolders(true);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(libraryIndexerViewModelProvider).watchTrackDirectories, isTrue);
    });

    test('triggerScan, triggerReindex, and triggerFingerprint dispatch to indexer', () {
      final vm = container.read(libraryIndexerViewModelProvider.notifier);

      expect(vm.triggerScan(), isTrue);
      expect(fakeIndexer.scanCalled, isTrue);

      expect(vm.triggerReindex(), isTrue);
      expect(fakeIndexer.reindexCalled, isTrue);

      expect(vm.triggerFingerprint(), isTrue);
      expect(fakeIndexer.fingerprintCalled, isTrue);
    });

    test('state reflects active background tasks and blocks triggers', () {
      final vm = container.read(libraryIndexerViewModelProvider.notifier);
      expect(container.read(libraryIndexerViewModelProvider).isAnyTaskRunning, isFalse);

      final bgService = container.read(backgroundTaskServiceProvider.notifier);
      bgService.startTask(id: 'library-scan', name: 'Scan');

      final scanningState = container.read(libraryIndexerViewModelProvider);
      expect(scanningState.isScanning, isTrue);
      expect(scanningState.isAnyTaskRunning, isTrue);

      // Triggers should be rejected when a task is running
      fakeIndexer.scanCalled = false;
      expect(vm.triggerScan(), isFalse);
      expect(fakeIndexer.scanCalled, isFalse);

      bgService.completeTask('library-scan');
      final completedState = container.read(libraryIndexerViewModelProvider);
      expect(completedState.isScanning, isFalse);
      expect(completedState.isAnyTaskRunning, isFalse);
    });

    test('customExclusions and activeDefaultExclusions helper properties work', () {
      fakeConfigRepo.updateConfig(
        fakeConfigRepo.currentConfig.copyWith(
          artistExclusions: ['Earth, Wind & Fire', 'My Custom Band'],
        ),
      );

      final state = container.read(libraryIndexerViewModelProvider);
      expect(state.customExclusions, equals(['My Custom Band']));
      expect(state.activeDefaultExclusions, equals(['Earth, Wind & Fire']));
    });
  });
}
