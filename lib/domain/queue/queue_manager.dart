import 'dart:math';

import 'package:nordplayer/domain/models/composite_models.dart';
import 'package:nordplayer/domain/models/playback_context.dart';
import 'package:nordplayer/domain/queue/queue_models.dart';
import 'package:nordplayer/utils/string_extension.dart';

/// Pure Dart sequencing engine responsible for queue state, two-tier priority,
/// non-destructive shuffle mapping, in-memory sorting, and gapless lookaheads.
class QueueManager({Random? random}) {
  final Random _random = random ?? Random();

  List<QueueItem> _items = [];
  List<int> _shuffleIndices = [];
  int _activeIndex = -1;
  bool _isShuffle = false;
  LoopMode _loopMode = LoopMode.off;
  PlaybackContext _context = const ManualPlaybackContext();

  // ========================================== Getters ==========================================

  /// The active sequential queue of items as perceived by the user.
  ///
  /// Returns items in natural sequence when [isShuffle] is false, or mapped
  /// through [_shuffleIndices] when [isShuffle] is true.
  List<QueueItem> get displayQueue {
    if (!_isShuffle) return List.unmodifiable(_items);
    return List.unmodifiable([for (final idx in _shuffleIndices) _items[idx]]);
  }

  /// The raw, un-shuffled queue items.
  List<QueueItem> get rawItems => List.unmodifiable(_items);

  /// The active index in [displayQueue].
  int get activeIndex => _activeIndex;

  /// The active index in [displayQueue] (alias for activeIndex).
  int get currentIndex => _activeIndex;

  /// The currently active [QueueItem], if one is selected.
  QueueItem? get currentItem =>
      (_activeIndex >= 0 && _activeIndex < displayQueue.length) ? displayQueue[_activeIndex] : null;

  /// The currently active [TrackWithArtists], if one is selected.
  TrackWithArtists? get currentTrack => currentItem?.track;

  /// Backward-compatible list of track entities in active display order.
  List<TrackWithArtists> get displayTracks => displayQueue.map((item) => item.track).toList();

  /// The upcoming [QueueItem] that will play next after [currentItem].
  ///
  /// Takes [loopMode] into account for gapless pre-buffering.
  QueueItem? get nextItem {
    if (displayQueue.isEmpty) return null;
    if (_loopMode == LoopMode.single) return currentItem;

    if (_activeIndex + 1 < displayQueue.length) {
      return displayQueue[_activeIndex + 1];
    }
    if (_loopMode == LoopMode.all) {
      return displayQueue.first;
    }
    return null;
  }

  /// File path of the next upcoming track for gapless lookahead, if available.
  String? get nextTrackFilePath => nextItem?.track.track.filePath;

  /// Immutable snapshot of current queue state.
  QueueState get state => QueueState(
    items: List.unmodifiable(_items),
    shuffleIndices: List.unmodifiable(_shuffleIndices),
    activeIndex: _activeIndex,
    isShuffle: _isShuffle,
    loopMode: _loopMode,
    context: _context,
  );

  /// Whether shuffle mode is active.
  bool get isShuffle => _isShuffle;

  /// Current loop/repeat mode.
  LoopMode get loopMode => _loopMode;

  /// Originating context (Album, Playlist, Library, Search).
  PlaybackContext get context => _context;

  /// Returns true if the queue has zero items.
  bool get isEmpty => _items.isEmpty;

  /// Returns true if the queue has at least one item.
  bool get isNotEmpty => _items.isNotEmpty;

  /// Total count of items in the queue.
  int get length => _items.length;

  /// Calculates upcoming album art paths (up to 5 items) for stacked player bar covers.
  List<String> get upcomingCoverArts {
    if (displayQueue.isEmpty || _activeIndex < 0) return const [];
    final covers = <String>[];
    for (int i = 0; i < displayQueue.length && covers.length < 5; i++) {
      int targetIdx = _activeIndex + i;
      if (targetIdx >= displayQueue.length) {
        if (_loopMode == LoopMode.all) {
          targetIdx = targetIdx % displayQueue.length;
        } else {
          break;
        }
      }
      final art = displayQueue[targetIdx].track.album.albumArtPath ?? '';
      covers.add(art);
    }
    return covers;
  }

  // ========================================== Queue Mutations ==========================================

  /// Restores complete queue state from a persisted snapshot.
  void restoreFromState(QueueState state) {
    _items = List.of(state.items);
    _shuffleIndices = state.shuffleIndices.isNotEmpty
        ? List.of(state.shuffleIndices)
        : List.generate(_items.length, (i) => i);
    _isShuffle = state.isShuffle;
    _loopMode = state.loopMode;
    _context = state.context;
    _activeIndex = (state.activeIndex >= 0 && state.activeIndex < displayQueue.length)
        ? state.activeIndex
        : (_items.isNotEmpty ? 0 : -1);
  }

  /// Initializes or replaces the queue with a list of tracks.
  void setQueue(
    List<TrackWithArtists> tracks, {
    int initialIndex = 0,
    PlaybackContext context = const ManualPlaybackContext(),
    bool shuffle = false,
  }) {
    _context = context;
    _isShuffle = shuffle;

    if (tracks.isEmpty) {
      clear();
      return;
    }

    _items = [
      for (int i = 0; i < tracks.length; i++)
        QueueItem.create(track: tracks[i], originalOrder: i, source: QueueSource.context),
    ];

    final clampedInitial = initialIndex.clamp(0, tracks.length - 1);

    if (_isShuffle) {
      _shuffleIndices = _generatePermutation(_items.length);
      // Ensure the chosen track starts at index 0 of the shuffled sequence
      final posInShuffle = _shuffleIndices.indexOf(clampedInitial);
      if (posInShuffle != -1 && posInShuffle != 0) {
        final temp = _shuffleIndices[0];
        _shuffleIndices[0] = _shuffleIndices[posInShuffle];
        _shuffleIndices[posInShuffle] = temp;
      }
      _activeIndex = 0;
    } else {
      _shuffleIndices = List.generate(_items.length, (i) => i);
      _activeIndex = clampedInitial;
    }
  }

  /// Inserts tracks immediately after the currently active track (High-priority "Up Next").
  void playNext(List<TrackWithArtists> tracks) {
    if (tracks.isEmpty) return;

    if (_items.isEmpty) {
      setQueue(tracks, initialIndex: 0, context: _context);
      return;
    }

    final insertDisplayPos = _activeIndex + 1;
    final newItems = [
      for (int i = 0; i < tracks.length; i++)
        QueueItem.create(track: tracks[i], originalOrder: _items.length + i, source: QueueSource.userNext),
    ];

    if (_isShuffle) {
      // In shuffle mode: append items to raw list, insert their new indices into shuffle map
      final startIndex = _items.length;
      _items.addAll(newItems);
      for (int i = 0; i < newItems.length; i++) {
        _shuffleIndices.insert(insertDisplayPos + i, startIndex + i);
      }
    } else {
      _items.insertAll(insertDisplayPos, newItems);
      _shuffleIndices = List.generate(_items.length, (i) => i);
    }
  }

  /// Appends tracks to the end of the queue.
  void addToQueue(List<TrackWithArtists> tracks) {
    if (tracks.isEmpty) return;

    if (_items.isEmpty) {
      setQueue(tracks, initialIndex: 0, context: _context);
      return;
    }

    final newItems = [
      for (int i = 0; i < tracks.length; i++)
        QueueItem.create(track: tracks[i], originalOrder: _items.length + i, source: QueueSource.userQueue),
    ];

    final startIndex = _items.length;
    _items.addAll(newItems);

    if (_isShuffle) {
      for (int i = 0; i < newItems.length; i++) {
        _shuffleIndices.add(startIndex + i);
      }
    } else {
      _shuffleIndices = List.generate(_items.length, (i) => i);
    }
  }

  /// Removes the track at [displayIndex] in the current [displayQueue].
  void removeAt(int displayIndex) {
    if (displayIndex < 0 || displayIndex >= displayQueue.length) return;

    if (_isShuffle) {
      final rawIndex = _shuffleIndices.removeAt(displayIndex);
      _items.removeAt(rawIndex);
      // Adjust all references in _shuffleIndices that shifted due to raw removal
      for (int i = 0; i < _shuffleIndices.length; i++) {
        if (_shuffleIndices[i] > rawIndex) {
          _shuffleIndices[i]--;
        }
      }
    } else {
      _items.removeAt(displayIndex);
      _shuffleIndices = List.generate(_items.length, (i) => i);
    }

    // Adjust active index
    if (_items.isEmpty) {
      _activeIndex = -1;
    } else if (displayIndex < _activeIndex) {
      _activeIndex--;
    } else if (displayIndex == _activeIndex) {
      if (_activeIndex >= displayQueue.length) {
        _activeIndex = displayQueue.length - 1;
      }
    }
  }

  /// Removes all queue items matching [filePath].
  void removeTrackByPath(String filePath) {
    final normalized = filePath.normalizePath().toLowerCase();
    for (int i = displayQueue.length - 1; i >= 0; i--) {
      if (displayQueue[i].track.track.filePath.normalizePath().toLowerCase() == normalized) {
        removeAt(i);
      }
    }
  }

  /// Removes all queue items matching any path in [filePaths].
  void removeTracksByPaths(Set<String> filePaths) {
    if (filePaths.isEmpty) return;
    final normalizedSet = filePaths.map((p) => p.normalizePath().toLowerCase()).toSet();
    for (int i = displayQueue.length - 1; i >= 0; i--) {
      if (normalizedSet.contains(displayQueue[i].track.track.filePath.normalizePath().toLowerCase())) {
        removeAt(i);
      }
    }
  }

  /// Removes items at the given display [indices].
  void removeIndices(List<int> indices) {
    if (indices.isEmpty) return;
    final sortedDesc = List<int>.from(indices)..sort((a, b) => b.compareTo(a));
    for (final index in sortedDesc) {
      removeAt(index);
    }
  }

  /// Reorders an item from [oldDisplayIndex] to [newDisplayIndex] in [displayQueue].
  void reorder(int oldDisplayIndex, int newDisplayIndex) {
    if (oldDisplayIndex < 0 || oldDisplayIndex >= displayQueue.length) return;
    final clampedNew = newDisplayIndex.clamp(0, displayQueue.length - 1);
    if (oldDisplayIndex == clampedNew) return;

    if (_isShuffle) {
      final moved = _shuffleIndices.removeAt(oldDisplayIndex);
      _shuffleIndices.insert(clampedNew, moved);
    } else {
      final moved = _items.removeAt(oldDisplayIndex);
      _items.insert(clampedNew, moved);
      _shuffleIndices = List.generate(_items.length, (i) => i);
    }

    // Adjust active index
    if (oldDisplayIndex == _activeIndex) {
      _activeIndex = clampedNew;
    } else if (oldDisplayIndex < _activeIndex && clampedNew >= _activeIndex) {
      _activeIndex--;
    } else if (oldDisplayIndex > _activeIndex && clampedNew <= _activeIndex) {
      _activeIndex++;
    }
  }

  // ========================================== Sequencing & Shuffle ==========================================

  /// Toggles shuffle mode non-destructively, preserving the currently playing track.
  void toggleShuffle() {
    if (_items.isEmpty) return;

    final activeItem = currentItem;
    _isShuffle = !_isShuffle;

    if (_isShuffle) {
      _shuffleIndices = _generatePermutation(_items.length);
      if (activeItem != null) {
        final rawIndex = _items.indexOf(activeItem);
        final posInShuffle = _shuffleIndices.indexOf(rawIndex);
        if (posInShuffle != -1 && posInShuffle != 0) {
          final temp = _shuffleIndices[0];
          _shuffleIndices[0] = _shuffleIndices[posInShuffle];
          _shuffleIndices[posInShuffle] = temp;
        }
      }
      _activeIndex = 0;
    } else {
      _shuffleIndices = List.generate(_items.length, (i) => i);
      if (activeItem != null) {
        _activeIndex = _items.indexOf(activeItem);
        if (_activeIndex == -1) _activeIndex = 0;
      }
    }
  }

  /// Sets the loop mode.
  void setLoopMode(LoopMode mode) {
    _loopMode = mode;
  }

  /// Sorts the queue in-memory, automatically anchoring the currently playing track.
  ///
  /// Sorting establishes a deterministic explicit order and disables shuffle.
  void sortBy(QueueSortCriteria criteria, {bool ascending = true}) {
    if (_items.isEmpty) return;

    final activeItem = currentItem;

    _items.sort((a, b) {
      final comparison = switch (criteria) {
        QueueSortCriteria.title => a.track.track.title.toLowerCase().compareTo(b.track.track.title.toLowerCase()),
        QueueSortCriteria.artist => (a.track.artists.firstOrNull?.name ?? '').toLowerCase().compareTo(
          (b.track.artists.firstOrNull?.name ?? '').toLowerCase(),
        ),
        QueueSortCriteria.album => a.track.album.title.toLowerCase().compareTo(b.track.album.title.toLowerCase()),
        QueueSortCriteria.duration => a.track.track.durationMs.compareTo(b.track.track.durationMs),
        QueueSortCriteria.originalOrder => a.originalOrder.compareTo(b.originalOrder),
      };
      return ascending ? comparison : -comparison;
    });

    _isShuffle = false;
    _shuffleIndices = List.generate(_items.length, (i) => i);

    if (activeItem != null) {
      _activeIndex = _items.indexOf(activeItem);
      if (_activeIndex == -1) _activeIndex = 0;
    }
  }

  /// Reverts sorting back to original context sequence order.
  void revertSort() => sortBy(QueueSortCriteria.originalOrder);

  /// Jumps directly to [displayIndex].
  void jumpTo(int displayIndex) {
    if (_items.isEmpty) return;
    _activeIndex = displayIndex.clamp(0, displayQueue.length - 1);
  }

  /// Advances to the next track according to sequencing and [loopMode].
  ///
  /// Returns the newly active [QueueItem], or `null` if the queue has finished.
  QueueItem? advanceNext() {
    if (_items.isEmpty) return null;

    if (_loopMode == LoopMode.single) {
      return currentItem;
    }

    if (_activeIndex + 1 < displayQueue.length) {
      _activeIndex++;
      return currentItem;
    }

    if (_loopMode == LoopMode.all) {
      _activeIndex = 0;
      return currentItem;
    }

    return null;
  }

  /// Steps to the previous track, or restarts the active track if played > 3 seconds.
  ///
  /// Returns the newly active [QueueItem], or `null` if the queue is empty.
  QueueItem? stepPrevious({Duration currentPosition = Duration.zero}) {
    if (_items.isEmpty) return null;

    // Standard music player behavior: restart song if past 3 seconds
    if (currentPosition.inSeconds >= 3) {
      return currentItem;
    }

    if (_activeIndex > 0) {
      _activeIndex--;
      return currentItem;
    }

    if (_loopMode == LoopMode.all) {
      _activeIndex = displayQueue.length - 1;
      return currentItem;
    }

    return currentItem;
  }

  /// Resets the queue manager to empty.
  void clear() {
    _items = [];
    _shuffleIndices = [];
    _activeIndex = -1;
  }

  /// Restores complete state from persistence (e.g. SQLite startup restoration).
  void restoreRawState({
    required List<QueueItem> items,
    required int activeIndex,
    required bool isShuffle,
    required LoopMode loopMode,
    required PlaybackContext context,
  }) {
    _items = List.from(items);
    _isShuffle = isShuffle;
    _loopMode = loopMode;
    _context = context;

    if (_items.isEmpty) {
      clear();
      return;
    }

    _shuffleIndices = List.generate(_items.length, (i) => i);
    _activeIndex = activeIndex.clamp(0, _items.length - 1);
  }

  // ========================================== Helpers ==========================================

  List<int> _generatePermutation(int length) {
    final list = List.generate(length, (i) => i);
    for (int i = list.length - 1; i > 0; i--) {
      final j = _random.nextInt(i + 1);
      final temp = list[i];
      list[i] = list[j];
      list[j] = temp;
    }
    return list;
  }
}
