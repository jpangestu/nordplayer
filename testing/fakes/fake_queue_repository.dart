import 'package:nordplayer/data/repositories/queue_repository.dart';
import 'package:nordplayer/domain/models/composite_models.dart';
import 'package:nordplayer/domain/models/playback_context.dart';
import 'package:nordplayer/domain/queue/queue_models.dart';

/// In-memory test double for [QueueRepository].
class FakeQueueRepository implements QueueRepository {
  List<TrackWithArtists> savedQueue = [];
  String? savedCurrentTrackPath;
  Duration savedPosition = Duration.zero;
  String savedContextType = '';
  int? savedContextId;
  int? updatedPositionMs;
  QueueState? savedQueueState;
  int? updatedActiveIndex;
  String? updatedActiveTrackPath;
  int? updatedActiveTrackId;
  bool? updatedIsShuffle;
  List<int>? updatedShuffleIndices;
  String? updatedLoopMode;
  double savedVolume = 100.0;
  bool savedIsMuted = false;

  @override
  Future<void> saveQueue(
    List<TrackWithArtists> originalQueue,
    String? currentlyPlayedTrackPath,
    Duration resumePositionMs,
    String playbackContextType,
    int? playbackContextId,
  ) async {
    savedQueue = List.from(originalQueue);
    savedCurrentTrackPath = currentlyPlayedTrackPath;
    savedPosition = resumePositionMs;
    savedContextType = playbackContextType;
    savedContextId = playbackContextId;
  }

  @override
  Future<void> saveQueueState(QueueState state, Duration resumePosition, {double? volume, bool? isMuted}) async {
    savedQueueState = state;
    savedQueue = state.tracks;
    savedCurrentTrackPath = state.currentItem?.track.track.filePath;
    savedPosition = resumePosition;
    savedContextType = state.context.type;
    savedContextId = state.context.id;
    if (volume != null) savedVolume = volume;
    if (isMuted != null) savedIsMuted = isMuted;
  }

  @override
  Future<void> updateActiveTrack(int activeIndex, String? activeTrackPath, {int? activeTrackId}) async {
    updatedActiveIndex = activeIndex;
    updatedActiveTrackPath = activeTrackPath;
    updatedActiveTrackId = activeTrackId;
  }

  @override
  Future<void> updateCurrentPosition(int positionInMs) async {
    updatedPositionMs = positionInMs;
  }

  @override
  Future<void> updateVolume({required double volume, required bool isMuted}) async {
    savedVolume = volume;
    savedIsMuted = isMuted;
  }

  @override
  Future<void> updateShuffleMode({
    required bool isShuffle,
    required List<int> shuffleIndices,
    required int activeIndex,
    String? activeTrackPath,
    int? activeTrackId,
  }) async {
    updatedIsShuffle = isShuffle;
    updatedShuffleIndices = List.from(shuffleIndices);
    updatedActiveIndex = activeIndex;
    updatedActiveTrackPath = activeTrackPath;
    updatedActiveTrackId = activeTrackId;
  }

  @override
  Future<void> updateLoopMode(String loopMode) async {
    updatedLoopMode = loopMode;
  }

  @override
  Future<RestoredQueueState?> restoreQueueState() async {
    if (savedQueueState != null) {
      return RestoredQueueState(
        state: savedQueueState!,
        resumePosition: savedPosition,
        volume: savedVolume,
        isMuted: savedIsMuted,
      );
    }
    if (savedQueue.isNotEmpty) {
      final items = [
        for (var i = 0; i < savedQueue.length; i++) QueueItem.create(track: savedQueue[i], originalOrder: i),
      ];
      return RestoredQueueState(
        state: QueueState(
          items: items,
          shuffleIndices: List.generate(items.length, (i) => i),
          activeIndex: 0,
          isShuffle: false,
          loopMode: LoopMode.off,
          context: PlaybackContext(type: savedContextType, id: savedContextId),
        ),
        resumePosition: savedPosition,
        volume: savedVolume,
        isMuted: savedIsMuted,
      );
    }
    return null;
  }
}

