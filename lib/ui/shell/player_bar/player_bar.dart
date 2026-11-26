import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nordplayer/config/app_config.dart';
import 'package:nordplayer/ui/shell/adaptive_surface.dart';
import 'package:nordplayer/ui/shell/player_bar/progress_bar.dart';
import 'package:nordplayer/ui/shell/player_bar/track_info.dart';
import 'package:nordplayer/ui/shell/player_bar/volume_slider.dart';

enum _RepeatMode { off, all, one }

typedef _DummyTrack = ({
  String title,
  String artist,
  String album,
  Duration duration,
  ImageProvider? albumArt,
});

const _dummyTracks = <_DummyTrack>[
  (
    title: 'Fjord Drift',
    artist: 'Nordic Signals',
    album: 'Polar Night Sessions',
    duration: Duration(minutes: 4, seconds: 16),
    albumArt: AssetImage('assets/album_art.jpg'),
  ),
  (
    title: 'Midnight Aurora',
    artist: 'Polar Echoes',
    album: 'Frostline',
    duration: Duration(minutes: 3, seconds: 42),
    albumArt: null,
  ),
  (
    title: 'Long Winter Set (Live at Tromsø)',
    artist: 'Arctic Ambient',
    album: 'Northern Transmissions',
    duration: Duration(hours: 1, minutes: 4, seconds: 18),
    albumArt: AssetImage('assets/album_art.jpg'),
  ),
];

class PlayerBar extends ConsumerStatefulWidget {
  const PlayerBar({super.key});

  @override
  ConsumerState<PlayerBar> createState() => _PlayerBarState();
}

class _PlayerBarState extends ConsumerState<PlayerBar> {
  static const _tickInterval = Duration(milliseconds: 200);

  Timer? _timer;
  int _trackIndex = 0;
  Duration _progress = const Duration(seconds: 32);
  bool _isPlaying = false;
  bool _isShuffle = false;
  _RepeatMode _repeatMode = _RepeatMode.off;
  TimeLabelType _timeLabelType = TimeLabelType.totalTime;
  final Set<int> _favoriteTracks = {0};

  double _volume = 75.0;
  double _lastNonZeroVolume = 75.0;
  bool _isMuted = false;

  _DummyTrack get _currentTrack => _dummyTracks[_trackIndex];

  Duration get _buffered {
    final target = _progress + const Duration(seconds: 45);
    return target > _currentTrack.duration ? _currentTrack.duration : target;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      if (!_isPlaying && _progress >= _currentTrack.duration) {
        _progress = Duration.zero;
      }
      _isPlaying = !_isPlaying;
    });
    _syncTimer();
  }

  void _syncTimer() {
    _timer?.cancel();
    if (!_isPlaying) return;

    _timer = Timer.periodic(_tickInterval, (_) {
      if (!mounted) return;
      final next = _progress + _tickInterval;
      if (next >= _currentTrack.duration) {
        _handleTrackEnded();
      } else {
        setState(() => _progress = next);
      }
    });
  }

  void _handleTrackEnded() {
    setState(() {
      switch (_repeatMode) {
        case _RepeatMode.one:
          _progress = Duration.zero;
        case _RepeatMode.all:
          _trackIndex = (_trackIndex + 1) % _dummyTracks.length;
          _progress = Duration.zero;
        case _RepeatMode.off:
          if (_trackIndex < _dummyTracks.length - 1) {
            _trackIndex++;
            _progress = Duration.zero;
          } else {
            _progress = _currentTrack.duration;
            _isPlaying = false;
            _timer?.cancel();
          }
      }
    });
  }

  void _skipPrevious() {
    setState(() {
      if (_progress > const Duration(seconds: 3)) {
        _progress = Duration.zero;
      } else {
        _trackIndex = (_trackIndex - 1 + _dummyTracks.length) % _dummyTracks.length;
        _progress = Duration.zero;
      }
    });
  }

  void _skipNext() {
    setState(() {
      _trackIndex = (_trackIndex + 1) % _dummyTracks.length;
      _progress = Duration.zero;
    });
  }

  void _cycleRepeatMode() {
    setState(() {
      _repeatMode = switch (_repeatMode) {
        _RepeatMode.off => _RepeatMode.all,
        _RepeatMode.all => _RepeatMode.one,
        _RepeatMode.one => _RepeatMode.off,
      };
    });
  }

  void _toggleFavorite() {
    setState(() {
      if (!_favoriteTracks.add(_trackIndex)) {
        _favoriteTracks.remove(_trackIndex);
      }
    });
  }

  void _handleSeek(Duration position) {
    setState(() => _progress = position);
  }

  void _toggleTimeLabelType() {
    setState(() {
      _timeLabelType = _timeLabelType == TimeLabelType.totalTime
          ? TimeLabelType.remainingTime
          : TimeLabelType.totalTime;
    });
  }

  void _handleVolumeChanged(double value) {
    setState(() {
      _volume = value;
      if (value > 0) {
        _lastNonZeroVolume = value;
        _isMuted = false;
      } else {
        _isMuted = true;
      }
    });
  }

  void _toggleMute() {
    setState(() {
      if (_isMuted) {
        _isMuted = false;
        if (_volume <= 0) {
          _volume = _lastNonZeroVolume > 0 ? _lastNonZeroVolume : 50.0;
        }
      } else {
        if (_volume > 0) {
          _lastNonZeroVolume = _volume;
        }
        _isMuted = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final appConfig = ref.watch(appConfigProvider);
    final playerBarSize = ref.watch(appConfig.ui.playerBar.size.provider);
    final colorScheme = Theme.of(context).colorScheme;
    final track = _currentTrack;

    final repeatIcon = _repeatMode == _RepeatMode.one ? LucideIcons.repeat1 : LucideIcons.repeat;
    final repeatTooltip = switch (_repeatMode) {
      _RepeatMode.off => 'Repeat: Off',
      _RepeatMode.all => 'Repeat: All',
      _RepeatMode.one => 'Repeat: One',
    };

    return AdaptiveSurface(
      elevation: .mid,
      height: playerBarSize.height,
      padding: const .symmetric(horizontal: 16),
      child: Row(
        children: [
          // Left: Track info
          Expanded(
            flex: 2,
            child: TrackInfo(
              title: track.title,
              artist: track.artist,
              album: track.album,
              albumArt: track.albumArt,
              albumArtSize: playerBarSize.albumArtSize,
              showAlbum: playerBarSize.showAlbum,
              isFavorite: _favoriteTracks.contains(_trackIndex),
              onFavoriteTap: _toggleFavorite,
              onAlbumArtTap: () {},
              onTitleTap: () {},
              onArtistTap: () {},
              onAlbumTap: () {},
            ),
          ),

          const SizedBox(width: 16),

          // Center: Playback controls + Progress bar
          Expanded(
            flex: 3,
            child: Column(
              mainAxisAlignment: .center,
              crossAxisAlignment: .center,
              children: [
                Row(
                  crossAxisAlignment: .center,
                  mainAxisAlignment: .center,
                  mainAxisSize: .min,
                  children: [
                    IconButton(
                      onPressed: () => setState(() => _isShuffle = !_isShuffle),
                      icon: Icon(
                        LucideIcons.shuffle,
                        color: _isShuffle ? colorScheme.primary : null,
                      ),
                      iconSize: 17,
                      tooltip: _isShuffle ? 'Shuffle: On' : 'Shuffle: Off',
                      visualDensity: .compact,
                    ),
                    IconButton(
                      onPressed: _skipPrevious,
                      icon: const Icon(LucideIcons.skipBack),
                      iconSize: 18,
                      tooltip: 'Previous',
                      visualDensity: .compact,
                    ),
                    IconButton(
                      onPressed: _togglePlayPause,
                      icon: Icon(_isPlaying ? LucideIcons.pause : LucideIcons.play),
                      iconSize: 24,
                      tooltip: _isPlaying ? 'Pause' : 'Play',
                      visualDensity: .compact,
                    ),
                    IconButton(
                      onPressed: _skipNext,
                      icon: const Icon(LucideIcons.skipForward),
                      iconSize: 18,
                      tooltip: 'Next',
                      visualDensity: .compact,
                    ),
                    IconButton(
                      onPressed: _cycleRepeatMode,
                      icon: Icon(
                        repeatIcon,
                        color: _repeatMode != _RepeatMode.off ? colorScheme.primary : null,
                      ),
                      iconSize: 17,
                      tooltip: repeatTooltip,
                      visualDensity: .compact,
                    ),
                  ],
                ),
                ProgressBar(
                  progress: _progress,
                  total: track.duration,
                  buffered: _buffered,
                  timeLabelType: _timeLabelType,
                  onSeek: _handleSeek,
                  onRightTimeLabelTap: _toggleTimeLabelType,
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // Right: Volume slider
          Expanded(
            flex: 2,
            child: Align(
              alignment: .centerRight,
              child: SizedBox(
                width: 160,
                child: VolumeSlider(
                  volume: _volume,
                  isMuted: _isMuted,
                  onChanged: _handleVolumeChanged,
                  onMute: _toggleMute,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
