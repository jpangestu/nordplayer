import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:nordplayer/domain/models/album.dart';
import 'package:nordplayer/domain/models/artist.dart';
import 'package:nordplayer/domain/models/composite_models.dart';
import 'package:nordplayer/domain/models/playback_context.dart';
import 'package:nordplayer/domain/models/track.dart';
import 'package:nordplayer/domain/queue/queue_manager.dart';
import 'package:nordplayer/domain/queue/queue_models.dart';

TrackWithArtists _makeTrack(int id, String title, {int durationMs = 200000, String? path, String? albumArt}) {
  return TrackWithArtists(
    track: Track(
      id: id,
      title: title,
      filePath: path ?? '/music/$id.mp3',
      durationMs: durationMs,
      albumId: 1,
      artistId: 1,
      fileHash: 'hash_$id',
      dateAdded: DateTime.fromMillisecondsSinceEpoch(0),
    ),
    album: Album(id: 1, title: 'Album 1', albumArtPath: albumArt ?? '/art/$id.jpg'),
    artists: [const Artist(id: 1, name: 'Artist 1')],
  );
}

void main() {
  group('QueueManager', () {
    late QueueManager manager;
    late List<TrackWithArtists> tracks;

    setUp(() {
      manager = QueueManager(random: Random(42)); // Seeded for deterministic test runs
      tracks = [
        _makeTrack(1, 'Bravo', durationMs: 180000),
        _makeTrack(2, 'Alpha', durationMs: 240000),
        _makeTrack(3, 'Charlie', durationMs: 120000),
        _makeTrack(4, 'Delta', durationMs: 300000),
      ];
    });

    test('initial state when empty', () {
      expect(manager.isEmpty, isTrue);
      expect(manager.length, equals(0));
      expect(manager.currentItem, isNull);
      expect(manager.nextItem, isNull);
      expect(manager.activeIndex, equals(-1));
      expect(manager.displayQueue, isEmpty);
    });

    test('setQueue initializes items with correct originalOrder and activeIndex', () {
      const context = AlbumPlaybackContext(id: 10, title: 'Test Album');
      manager.setQueue(tracks, initialIndex: 1, context: context);

      expect(manager.isNotEmpty, isTrue);
      expect(manager.length, equals(4));
      expect(manager.activeIndex, equals(1));
      expect(manager.currentItem?.track.track.title, equals('Alpha'));
      expect(manager.context, equals(context));
      expect(manager.isShuffle, isFalse);

      final items = manager.displayQueue;
      for (int i = 0; i < items.length; i++) {
        expect(items[i].originalOrder, equals(i));
        expect(items[i].source, equals(QueueSource.context));
      }
    });

    test('setQueue with shuffle pins the initialIndex to position 0', () {
      manager.setQueue(tracks, initialIndex: 2, shuffle: true);

      expect(manager.isShuffle, isTrue);
      expect(manager.activeIndex, equals(0));
      expect(manager.currentItem?.track.track.title, equals('Charlie'));
      expect(manager.displayQueue.length, equals(4));
    });

    group('Sequencing & Transitions', () {
      setUp(() {
        manager.setQueue(tracks, initialIndex: 0);
      });

      test('advanceNext advances through queue and stops when loopMode is off', () {
        manager.setLoopMode(LoopMode.off);

        expect(manager.advanceNext()?.track.track.title, equals('Alpha'));
        expect(manager.advanceNext()?.track.track.title, equals('Charlie'));
        expect(manager.advanceNext()?.track.track.title, equals('Delta'));
        expect(manager.advanceNext(), isNull); // Reached end
      });

      test('advanceNext wraps to start when loopMode is all', () {
        manager.setLoopMode(LoopMode.all);
        manager.jumpTo(3); // At 'Delta'

        final next = manager.advanceNext();
        expect(next?.track.track.title, equals('Bravo'));
        expect(manager.activeIndex, equals(0));
      });

      test('advanceNext repeats same item when loopMode is single', () {
        manager.setLoopMode(LoopMode.single);
        manager.jumpTo(1);

        final next = manager.advanceNext();
        expect(next?.track.track.title, equals('Alpha'));
        expect(manager.activeIndex, equals(1));
      });

      test('stepPrevious restarts current song if position >= 3 seconds', () {
        manager.jumpTo(2); // 'Charlie'
        final prev = manager.stepPrevious(currentPosition: const Duration(seconds: 4));
        expect(prev?.track.track.title, equals('Charlie'));
        expect(manager.activeIndex, equals(2));
      });

      test('stepPrevious moves to previous track if position < 3 seconds', () {
        manager.jumpTo(2); // 'Charlie'
        final prev = manager.stepPrevious(currentPosition: const Duration(seconds: 1));
        expect(prev?.track.track.title, equals('Alpha'));
        expect(manager.activeIndex, equals(1));
      });

      test('stepPrevious wraps to last item if at index 0 and loopMode is all', () {
        manager.setLoopMode(LoopMode.all);
        manager.jumpTo(0);

        final prev = manager.stepPrevious(currentPosition: Duration.zero);
        expect(prev?.track.track.title, equals('Delta'));
        expect(manager.activeIndex, equals(3));
      });

      test('nextItem correctly anticipates upcoming track for gapless', () {
        manager.setLoopMode(LoopMode.off);
        manager.jumpTo(0);
        expect(manager.nextItem?.track.track.title, equals('Alpha'));

        manager.jumpTo(3);
        expect(manager.nextItem, isNull);

        manager.setLoopMode(LoopMode.all);
        expect(manager.nextItem?.track.track.title, equals('Bravo'));
      });
    });

    group('Queue Priority: playNext & addToQueue', () {
      setUp(() {
        manager.setQueue(tracks, initialIndex: 1); // Playing 'Alpha' at index 1
      });

      test('playNext inserts immediately after active track marked as userNext', () {
        final newTrack = _makeTrack(99, 'Next Song');
        manager.playNext([newTrack]);

        expect(manager.length, equals(5));
        expect(manager.activeIndex, equals(1)); // Current still at index 1
        expect(manager.displayQueue[2].track.track.title, equals('Next Song'));
        expect(manager.displayQueue[2].source, equals(QueueSource.userNext));
      });

      test('addToQueue appends to the end marked as userQueue', () {
        final newTrack = _makeTrack(100, 'Queued Song');
        manager.addToQueue([newTrack]);

        expect(manager.length, equals(5));
        expect(manager.displayQueue.last.track.track.title, equals('Queued Song'));
        expect(manager.displayQueue.last.source, equals(QueueSource.userQueue));
      });
    });

    group('Removals & Reordering', () {
      setUp(() {
        manager.setQueue(tracks, initialIndex: 2); // 'Charlie' at index 2
      });

      test('removeAt removes track and adjusts activeIndex if before active', () {
        manager.removeAt(0); // Remove 'Bravo'

        expect(manager.length, equals(3));
        expect(manager.activeIndex, equals(1)); // Shifted from 2 to 1
        expect(manager.currentItem?.track.track.title, equals('Charlie'));
      });

      test('removeAt clamped when removing currently active track', () {
        manager.removeAt(2); // Remove active 'Charlie'

        expect(manager.length, equals(3));
        expect(manager.activeIndex, equals(2)); // Now points to 'Delta'
        expect(manager.currentItem?.track.track.title, equals('Delta'));
      });

      test('removeTrackByPath purges deleted file paths', () {
        manager.removeTrackByPath('/music/2.mp3');

        expect(manager.length, equals(3));
        expect(manager.displayQueue.any((i) => i.track.track.filePath == '/music/2.mp3'), isFalse);
      });

      test('reorder moves item and preserves active track tracking', () {
        // Move item at 0 ('Bravo') to 2
        manager.reorder(0, 2);

        expect(manager.displayQueue[2].track.track.title, equals('Bravo'));
        // Active item was index 2 ('Charlie'), it shifted down to index 1
        expect(manager.currentItem?.track.track.title, equals('Charlie'));
        expect(manager.activeIndex, equals(1));
      });
    });

    group('Non-Destructive Shuffle', () {
      setUp(() {
        manager.setQueue(tracks, initialIndex: 2); // 'Charlie'
      });

      test('toggling shuffle on pins active track at 0', () {
        manager.toggleShuffle();

        expect(manager.isShuffle, isTrue);
        expect(manager.activeIndex, equals(0));
        expect(manager.currentItem?.track.track.title, equals('Charlie'));
        expect(manager.displayQueue.length, equals(4));
      });

      test('toggling shuffle off restores original context order with zero position loss', () {
        manager.toggleShuffle(); // on
        manager.toggleShuffle(); // off

        expect(manager.isShuffle, isFalse);
        expect(manager.currentItem?.track.track.title, equals('Charlie'));
        expect(manager.activeIndex, equals(2)); // Restored to index 2

        expect(manager.displayQueue[0].track.track.title, equals('Bravo'));
        expect(manager.displayQueue[1].track.track.title, equals('Alpha'));
        expect(manager.displayQueue[2].track.track.title, equals('Charlie'));
        expect(manager.displayQueue[3].track.track.title, equals('Delta'));
      });
    });

    group('In-Memory Sorting', () {
      setUp(() {
        manager.setQueue(tracks, initialIndex: 0); // 'Bravo' at index 0
      });

      test('sortBy Title A-Z anchors active track', () {
        // Before sort: Bravo(0), Alpha(1), Charlie(2), Delta(3)
        // After sort A-Z: Alpha(0), Bravo(1), Charlie(2), Delta(3)
        manager.sortBy(QueueSortCriteria.title, ascending: true);

        expect(manager.displayQueue[0].track.track.title, equals('Alpha'));
        expect(manager.displayQueue[1].track.track.title, equals('Bravo'));
        expect(manager.displayQueue[2].track.track.title, equals('Charlie'));
        expect(manager.displayQueue[3].track.track.title, equals('Delta'));

        // 'Bravo' was playing at index 0; it is now at index 1
        expect(manager.currentItem?.track.track.title, equals('Bravo'));
        expect(manager.activeIndex, equals(1));
        expect(manager.isShuffle, isFalse);
      });

      test('sortBy Duration anchors active track', () {
        // Durations: Charlie(120k), Bravo(180k), Alpha(240k), Delta(300k)
        manager.jumpTo(2); // 'Charlie'
        manager.sortBy(QueueSortCriteria.duration, ascending: true);

        expect(manager.displayQueue[0].track.track.title, equals('Charlie'));
        expect(manager.displayQueue[1].track.track.title, equals('Bravo'));
        expect(manager.displayQueue[2].track.track.title, equals('Alpha'));
        expect(manager.displayQueue[3].track.track.title, equals('Delta'));

        expect(manager.currentItem?.track.track.title, equals('Charlie'));
        expect(manager.activeIndex, equals(0));
      });

      test('sortBy originalOrder reverts custom sort to context sequence', () {
        manager.sortBy(QueueSortCriteria.title, ascending: false);
        manager.sortBy(QueueSortCriteria.originalOrder);

        expect(manager.displayQueue[0].track.track.title, equals('Bravo'));
        expect(manager.displayQueue[1].track.track.title, equals('Alpha'));
        expect(manager.displayQueue[2].track.track.title, equals('Charlie'));
        expect(manager.displayQueue[3].track.track.title, equals('Delta'));
      });
    });

    test('upcomingCoverArts computes rolling cover paths up to 5', () {
      manager.setQueue(tracks, initialIndex: 0);
      final covers = manager.upcomingCoverArts;

      expect(covers.length, equals(4));
      expect(covers[0], equals('/art/1.jpg'));
      expect(covers[1], equals('/art/2.jpg'));
      expect(covers[2], equals('/art/3.jpg'));
      expect(covers[3], equals('/art/4.jpg'));
    });

    group('Critical Bug Regressions', () {
      test('displayQueue does not throw RangeError on stale or out-of-bounds shuffleIndices', () {
        manager.setQueue(tracks, initialIndex: 0);
        manager.restoreRawState(
          items: tracks.map((t) => QueueItem.create(track: t, originalOrder: 0)).toList(),
          shuffleIndices: [0, 999, 1, -5, 2],
          activeIndex: 0,
          isShuffle: true,
          loopMode: LoopMode.off,
          context: const ManualPlaybackContext(),
        );

        // Accessing displayQueue should safely discard out-of-bounds indices and not throw RangeError.
        // restoreRawState heals invalid indices by regenerating a valid permutation for the items.
        expect(() => manager.displayQueue, returnsNormally);
        expect(manager.displayQueue.length, equals(4));
      });

      test('toggling or setting shuffle on empty queue preserves shuffle preference', () {
        expect(manager.isEmpty, isTrue);
        expect(manager.isShuffle, isFalse);

        manager.setShuffle(true);
        expect(manager.isShuffle, isTrue);

        manager.toggleShuffle();
        expect(manager.isShuffle, isFalse);
      });

      test('restoreFromState repairs corrupted shuffleIndices when restoring', () {
        final corruptedState = QueueState(
          items: tracks.map((t) => QueueItem.create(track: t, originalOrder: 0)).toList(),
          shuffleIndices: [0, 10], // Length doesn't match items.length
          activeIndex: 5, // Out of bounds
          isShuffle: true,
          loopMode: LoopMode.off,
          context: const ManualPlaybackContext(),
        );

        manager.restoreFromState(corruptedState);

        expect(manager.isShuffle, isTrue);
        expect(manager.displayQueue.length, equals(tracks.length));
        expect(manager.activeIndex, equals(0)); // Clamped to valid range
      });
    });
  });
}
