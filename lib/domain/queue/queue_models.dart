import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:nordplayer/domain/models/composite_models.dart';

/// Engine-agnostic domain representation of playback loop / repeat mode.
enum LoopMode {
  /// Playback stops after reaching the end of the queue.
  off,

  /// Playback wraps around to the beginning of the queue after reaching the end.
  all,

  /// The active track repeats continuously until toggled off.
  single;

  /// Cycles to the next mode in standard order: off -> all -> single -> off.
  LoopMode cycle() {
    return switch (this) {
      LoopMode.off => LoopMode.all,
      LoopMode.all => LoopMode.single,
      LoopMode.single => LoopMode.off,
    };
  }
}

/// Represents the origin tier of a track in the playback queue.
enum QueueSource {
  /// Belonging to the original album, playlist, or library context being played.
  context,

  /// Explicitly queued by the user to play next with high priority.
  userNext,

  /// Appended by the user to the queue.
  userQueue,
}

/// Sorting criteria available for in-memory queue reordering.
enum QueueSortCriteria {
  /// Alphabetical by track title.
  title,

  /// Alphabetical by primary contributing artist.
  artist,

  /// Alphabetical by album title.
  album,

  /// By track duration in milliseconds.
  duration,

  /// Reverts to the original album/playlist context sequence.
  originalOrder,
}

/// Unique ID generator for queue items.
///
/// Combines microsecond timestamp with sequence and random noise to ensure
/// 100% collision-free IDs across fast batch queue additions.
final Random _random = Random();
int _seqCounter = 0;

String generateQueueItemId() {
  final now = DateTime.now().microsecondsSinceEpoch;
  final seq = (_seqCounter++ % 10000).toString().padLeft(4, '0');
  final noise = _random.nextInt(0xFFFFFF).toRadixString(16).padLeft(6, '0');
  return '$now-$seq-$noise';
}

/// Represents an individual item in the active playback queue.
///
/// Distinct from [TrackWithArtists] by having its own unique [id] and [originalOrder],
/// allowing the same track to appear multiple times in the queue without key collisions.
@immutable
class const QueueItem({
  /// Unique identifier for this specific instance in the queue.
  required final String id,

  /// Underlying domain track entity with artist and album metadata.
  required final TrackWithArtists track,

  /// Origin tier (context, userNext, userQueue).
  final QueueSource source = QueueSource.context,

  /// The original unshuffled index from the originating album/playlist.
  required final int originalOrder,

  /// Timestamp when this item was queued.
  required final DateTime addedAt,
}) {
  /// Factory creating a fresh [QueueItem] with an auto-generated unique ID.
  factory QueueItem.create({
    required TrackWithArtists track,
    QueueSource source = QueueSource.context,
    required int originalOrder,
    DateTime? addedAt,
  }) {
    return QueueItem(
      id: generateQueueItemId(),
      track: track,
      source: source,
      originalOrder: originalOrder,
      addedAt: addedAt ?? DateTime.now(),
    );
  }

  QueueItem copyWith({
    String? id,
    TrackWithArtists? track,
    QueueSource? source,
    int? originalOrder,
    DateTime? addedAt,
  }) {
    return QueueItem(
      id: id ?? this.id,
      track: track ?? this.track,
      source: source ?? this.source,
      originalOrder: originalOrder ?? this.originalOrder,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is QueueItem && runtimeType == other.runtimeType && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'QueueItem(id: $id, track: ${track.track.title}, order: $originalOrder, source: $source)';
}
