import 'dart:async';

import 'package:just_audio/just_audio.dart';
import 'package:suara/models/song.dart';
import 'package:suara/widgets/position_data.dart';

class AudioManager {
  static final AudioManager _instance = AudioManager._internal();

  factory AudioManager() {
    return _instance;
  }

  AudioManager._internal();

  final AudioPlayer _player = AudioPlayer();

  // Expose the playing status as a stream
  Stream<bool> get playingStream => _player.playingStream;

  // FULL AI GENERATED
  Stream<PositionData> get positionDataStream {
    // 1. Create a controller to manage the output stream
    StreamController<PositionData>? controller;

    // 2. We need to keep track of subscriptions to cancel them later
    StreamSubscription? positionSub;
    StreamSubscription? bufferSub;
    StreamSubscription? durationSub;

    // 3. The "Switchboard Operator" function
    // Whenever an event comes in, grab the LATEST values from the player
    // and push a new package to the UI.
    void emitData() {
      if (controller != null && !controller.isClosed) {
        controller.add(
          PositionData(
            _player.position,
            _player.bufferedPosition,
            _player.duration ?? Duration.zero,
          ),
        );
      }
    }

    controller = StreamController<PositionData>(
      onListen: () {
        // Start listening to all three separate streams
        positionSub = _player.positionStream.listen((_) => emitData());
        bufferSub = _player.bufferedPositionStream.listen((_) => emitData());
        durationSub = _player.durationStream.listen((_) => emitData());
      },
      onCancel: () {
        // Clean up when the UI stops listening (Performance Awareness!)
        positionSub?.cancel();
        bufferSub?.cancel();
        durationSub?.cancel();
      },
    );

    return controller.stream;
  }

  // 1. The Switchboard: Holds the current 'Song' (or null if nothing is playing)
  final StreamController<Song?> _songController =
      StreamController<Song?>.broadcast();

  // 2. The Public Line: The UI listens to this
  Stream<Song?> get currentSongStream => _songController.stream;

  // 3. Update the play method
  Future<void> play(Song song) async {
    _songController.add(song);

    try {
      await _player.setFilePath(song.path);

      await _player.play();
    } catch (e) {
      print("AUDIO_DEBUG: Error playing audio: $e");
    }
  }

  // Future<void> play(String path) async {
  //   try {
  //     print("AUDIO_DEBUG: Trying to set file path: $path");

  //     // This is usually where it hangs on Linux if GStreamer is unhappy
  //     await _player.setFilePath(path);
  //     print(
  //       "AUDIO_DEBUG: File loaded successfully. Duration: ${_player.duration}",
  //     );

  //     await _player.play();
  //     print("AUDIO_DEBUG: Playing!");
  //   } catch (e) {
  //     print("AUDIO_DEBUG: Error playing audio: $e");
  //   }
  // }

  Future<void> resume() async {
    await _player.play();
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }
}
