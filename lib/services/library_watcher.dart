import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nordplayer/models/app_config.dart';
import 'package:nordplayer/services/config_service.dart';
import 'package:nordplayer/services/library_indexer.dart';
import 'package:nordplayer/services/logger.dart';
import 'package:path/path.dart' as p;
import 'package:watcher/watcher.dart';

final libraryWatcherProvider = Provider<LibraryWatcher>((ref) {
  final libraryIndexer = ref.watch(libraryIndexerProvider);

  final watcher = LibraryWatcher(libraryIndexer);

  ref.listen<AsyncValue<AppConfig>>(
    configServiceProvider,
    (previous, next) {
      if (next is AsyncData<AppConfig>) {
        watcher.updateConfig(next.value);
      }
    },
    fireImmediately: true,
  );

  ref.onDispose(() => watcher.dispose());
  return watcher;
});

class LibraryWatcher with LoggerMixin {
  LibraryWatcher(this._libraryIndexer);

  final LibraryIndexer _libraryIndexer;

  final Map<String, StreamSubscription<WatchEvent>> _subscriptions = {};

  // A map to keep track of pending files to prevent premature parsing
  final Map<String, Timer> _debouncers = {};

  /// Synchronizes directory watchers when the application configuration is updated.
  ///
  /// Cancels all subscriptions if directory watching is disabled, stops watchers for
  /// removed folders, and starts watching newly added folders.
  void updateConfig(AppConfig newConfig) {
    if (!newConfig.watchTrackDirectories) {
      if (_subscriptions.isNotEmpty) {
        log.i("Directory watching disabled. Canceling all active subscriptions.");
        dispose();
      }
      return;
    }

    // Stop watching folders that are no longer in the list
    final currentlyWatched = List<String>.from(_subscriptions.keys);
    for (final folderPath in currentlyWatched) {
      if (!newConfig.trackDirectories.contains(folderPath)) {
        stopWatchingTrackDirectory(folderPath);
      }
    }

    // Start watching folders that are in the list but not yet watched
    for (final folderPath in newConfig.trackDirectories) {
      watchTrackDirectory(folderPath);
    }
  }

  void watchTrackDirectory(String trackDirectory) {
    if (_subscriptions.containsKey(trackDirectory)) return;

    if (!Directory(trackDirectory).existsSync()) return;

    final watcher = DirectoryWatcher(trackDirectory);

    _subscriptions[trackDirectory] = watcher.events.listen(
      (WatchEvent event) {
        _handleFileSystemEvent(event);
      },
      onError: (e) {
        log.e("Error when trying to listen for changes in $trackDirectory: $e");
      },
    );

    log.i("Start listening for changes in directory: $trackDirectory");
  }

  void stopWatchingTrackDirectory(String trackDirectory) {
    _subscriptions[trackDirectory]?.cancel();
    _subscriptions.remove(trackDirectory);
    log.i("Stopped watching directory: $trackDirectory");
  }

  void _handleFileSystemEvent(WatchEvent event) {
    final path = event.path;
    final ext = p.extension(path).toLowerCase();

    // Ignore non-music files
    if (!_libraryIndexer.supportedExtensions.contains(ext)) return;

    switch (event.type) {
      case ChangeType.ADD:
      case ChangeType.MODIFY:
        _debounceFileProcessing(path);
        break;
      case ChangeType.REMOVE:
        log.d("File marked as missing: $path");

        if (_debouncers.containsKey(path)) {
          _debouncers[path]?.cancel();
          _debouncers.remove(path);
        }

        _libraryIndexer.markTrackAsMissing(path);
        break;
    }
  }

  /// Verifies file stabilization before processing.
  ///
  /// Since OS file events (MODIFY/ADD) can trigger while a file is still being written, this function polls the file
  /// size until it stops changing to ensure the file is complete and unlocked.
  void _debounceFileProcessing(String path) {
    if (_debouncers.containsKey(path)) {
      _debouncers[path]?.cancel();
      _debouncers.remove(path);
    }

    _debouncers[path] = Timer(const Duration(milliseconds: 500), () async {
      _debouncers.remove(path);

      final file = File(path);
      int lastSize = -1;
      int retries = 0;
      const maxRetries = 60; // Max wait: 30 seconds (60 * 500ms)

      while (retries < maxRetries) {
        try {
          if (!await file.exists()) {
            log.w("File disappeared before we could process it: $path");
            return;
          }

          final currentSize = await file.length();

          // If the file size is greater than 0 AND hasn't changed since last check,
          // the OS most likely has finished copying/downloading the file!
          if (currentSize > 0 && currentSize == lastSize) {
            log.i("File stabilization complete. Ready to process: $path");

            // Attempt to acquire a read lock to verify the OS has released the file.
            // This prevents 'File in Use' exceptions during metadata extraction,
            // particularly on Windows or during slow I/O operations.
            final randomAccess = await file.open(mode: FileMode.read);
            await randomAccess.close();

            await _libraryIndexer.processSingleFile(file);
            return;
          }

          lastSize = currentSize;
        } catch (e) {
          log.d("File $path is locked or unreadable, retrying...");
        }

        retries++;
        await Future.delayed(const Duration(milliseconds: 500));
      }

      log.e("Timeout waiting for file to be ready: $path");
    });
  }

  void dispose() {
    for (final sub in _subscriptions.values) {
      sub.cancel();
    }
    _subscriptions.clear();

    for (final timer in _debouncers.values) {
      timer.cancel();
    }
    _debouncers.clear();
  }
}
