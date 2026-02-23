import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nordplayer/services/config_service.dart';
import 'package:path/path.dart' as p;
import 'package:watcher/watcher.dart';
import 'package:nordplayer/models/app_config.dart';
import 'package:nordplayer/services/library_scanner.dart';
import 'package:nordplayer/services/logger.dart';

final libraryWatcherProvider = Provider<LibraryWatcher>((ref) {
  final appConfig = ref.watch(configServiceProvider).requireValue;
  final libraryScanner = ref.watch(libraryScannerProvider);

  return LibraryWatcher(appConfig, libraryScanner);
});

class LibraryWatcher with LoggerMixin {
  final AppConfig _appConfig;
  final LibraryScanner _libraryScanner;

  final Map<String, StreamSubscription<WatchEvent>> _subscriptions = {};

  // A map to keep track of pending files to prevent premature parsing
  final Map<String, Timer> _debouncers = {};

  LibraryWatcher(this._appConfig, this._libraryScanner);

  void startWatching() {
    for (final folderPath in _appConfig.musicPaths) {
      watchFolder(folderPath);
    }
  }

  void watchFolder(String folderPath) {
    if (_subscriptions.containsKey(folderPath)) return;

    if (!Directory(folderPath).existsSync()) return;

    final watcher = DirectoryWatcher(folderPath);

    _subscriptions[folderPath] = watcher.events.listen(
      (WatchEvent event) {
        _handleFileSystemEvent(event);
      },
      onError: (e) {
        log.e("Error when trying to listen for changes in $folderPath: $e");
      },
    );

    log.i("Start listening for changes in directory: $folderPath");
  }

  void _handleFileSystemEvent(WatchEvent event) {
    final path = event.path;
    final ext = p.extension(path).toLowerCase();

    // Ignore non-music files
    if (!_libraryScanner.supportedExtensions.contains(ext)) return;

    switch (event.type) {
      case ChangeType.ADD:
      case ChangeType.MODIFY:
        _debounceFileProcessing(path);
        break;
      case ChangeType.REMOVE:
        log.d("File removed: $path");
        _cancelDebounce(path);
        _libraryScanner.removeTrackByPath(path);
        break;
    }
  }

  void _debounceFileProcessing(String path) {
    _cancelDebounce(path);

    _debouncers[path] = Timer(const Duration(milliseconds: 500), () async {
      _debouncers.remove(path);

      await _processWhenFileIsReady(path);
    });
  }

  /// Verifies file stabilization before processing.
  ///
  /// Since OS file events (MODIFY/ADD) can trigger while a file is still being
  /// written, this function polls the file size until it stops changing to
  /// ensure the file is complete and unlocked.
  Future<void> _processWhenFileIsReady(String path) async {
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

          await _libraryScanner.processSingleFile(file);
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
  }

  void _cancelDebounce(String path) {
    if (_debouncers.containsKey(path)) {
      _debouncers[path]?.cancel();
      _debouncers.remove(path);
    }
  }

  void stopWatchingFolder(String folderPath) {
    _subscriptions[folderPath]?.cancel();
    _subscriptions.remove(folderPath);
    log.i("Stopped watching directory: $folderPath");
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
