import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nordplayer/core/database/app_database.dart';
import 'package:nordplayer/core/models/selection_state.dart';
import 'package:nordplayer/core/services/config_service.dart';
import 'package:nordplayer/core/services/logger.dart';
import 'package:nordplayer/core/utils/datetime_extension.dart';
import 'package:nordplayer/core/utils/int_extension.dart';
import 'package:nordplayer/data/repositories/repositories.dart';
import 'package:nordplayer/pages/pages_context_menu.dart';
import 'package:nordplayer/routes/router.dart';
import 'package:nordplayer/services/player_service.dart';
import 'package:nordplayer/widgets/animated_equalizer_icon.dart';
import 'package:nordplayer/widgets/clickable_text.dart';
import 'package:nordplayer/widgets/music_tile.dart';
import 'package:nordplayer/widgets/sliver_resizable_table.dart';

/// Computes up to 5 unique album art paths for the tracks page header collage.
final libraryAlbumArtProvider = Provider<List<String>>((ref) {
  final libraryAsync = ref.watch(libraryStreamProvider);
  final libraryTracks = libraryAsync.value ?? [];

  if (libraryTracks.isEmpty) return const [];

  final wallCovers = <String>[];
  final seenWallCovers = <String>{};

  for (final track in libraryTracks) {
    final artPath = track.album.albumArtPath;
    if (artPath != null && artPath.isNotEmpty && !seenWallCovers.contains(artPath)) {
      seenWallCovers.add(artPath);
      wallCovers.add(artPath);
    }
    if (wallCovers.length >= 5) break;
  }

  return wallCovers;
});

/// Manages table column configurations (widths, ordering, visibility) for the all-tracks table.
final tracksPageColumnsProvider =
    NotifierProvider<TracksPageColumnsNotifier, List<TableColumn<TrackWithArtists>>>(
      TracksPageColumnsNotifier.new,
    );

class TracksPageColumnsNotifier extends Notifier<List<TableColumn<TrackWithArtists>>> {
  @override
  List<TableColumn<TrackWithArtists>> build() => _initialColumns;

  void toggleVisibility(String columnId) {
    state = state.map((col) {
      if (col.id == columnId) {
        return col.copyWith(isVisible: !col.isVisible);
      }
      return col;
    }).toList();
  }

  static final List<TableColumn<TrackWithArtists>> _initialColumns = [
    TableColumn<TrackWithArtists>(
      id: 'index',
      label: "#",
      width: 60,
      minWidth: 60,
      alignment: Alignment.centerRight,
      cellBuilder: (context, track, index) {
        return Consumer(
          builder: (context, ref, child) {
            final isActiveTrack = ref.watch(currentTrackProvider)?.track.filePath == track.track.filePath;

            if (isActiveTrack) {
              final isAudioPlaying = ref.watch(isPlayingProvider);

              return AnimatedEqualizerIcon(
                color: Theme.of(context).colorScheme.primary,
                size: 16,
                isPlaying: isAudioPlaying,
              );
            }
            return Text(
              "${index + 1}",
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6)),
            );
          },
        );
      },
    ),
    TableColumn<TrackWithArtists>(
      id: 'title_artist',
      label: "Title/Artist",
      flex: 5,
      minWidth: 150,
      cellBuilder: (context, track, index) {
        return Consumer(
          builder: (context, ref, child) {
            final isPlaying = ref.watch(currentTrackProvider)?.track.filePath == track.track.filePath;
            return MusicTile(
              selected: isPlaying,
              albumArtPath: track.album.albumArtPath,
              title: track.track.title,
              artists: track.artists.map((a) => a.name).toList(),
              padding: EdgeInsets.zero,
            );
          },
        );
      },
    ),
    TableColumn<TrackWithArtists>(
      id: 'album',
      label: "Album",
      flex: 3,
      minWidth: 100,
      cellBuilder: (context, track, index) {
        return ClickableText(
          text: track.album.title,
          onTap: () {
            final basePath = Routes.albumsPage;
            final targetId = track.album.id;
            context.go('$basePath/$targetId');
          },
        );
      },
    ),
    TableColumn<TrackWithArtists>(
      id: 'path',
      label: 'Path',
      flex: 3,
      minWidth: 120,
      isVisible: false,
      cellBuilder: (context, track, index) {
        return Text(track.track.filePath, maxLines: 1, overflow: TextOverflow.ellipsis);
      },
    ),
    TableColumn<TrackWithArtists>(
      id: 'date_added',
      label: "Date Added",
      width: 110,
      minWidth: 110,
      alignment: .centerRight,
      isVisible: false,
      cellBuilder: (context, track, index) {
        return Text(track.track.dateAdded.toRelativeTime(), maxLines: 1, overflow: TextOverflow.ellipsis);
      },
    ),
    TableColumn<TrackWithArtists>(
      id: 'duration',
      label: 'Duration',
      width: 90,
      minWidth: 90,
      alignment: Alignment.centerRight,
      cellBuilder: (context, track, index) {
        return Text(track.track.durationMs.toDurationString());
      },
    ),
    TableColumn<TrackWithArtists>(
      id: 'context_menu',
      label: '',
      width: 75,
      minWidth: 75,
      alignment: Alignment.centerRight,
      cellBuilder: (context, track, index) {
        return Consumer(
          builder: (context, ref, child) {
            return Listener(
              onPointerDown: (event) {
                // Sync Selection
                final selectionNotifier = ref.read(selectedTracksIndexProvider('all_tracks').notifier);
                if (!ref.read(selectedTracksIndexProvider('all_tracks')).contains(index)) {
                  selectionNotifier.selectTrack(index, isCtrlSelect: false, isShiftSelect: false);
                }

                final tracks = ref.read(libraryStreamProvider).value ?? [];
                final selectedIndices = ref.read(selectedTracksIndexProvider('all_tracks')).toList()..sort();
                final selectedTracks = selectedIndices
                    .where((i) => i >= 0 && i < tracks.length)
                    .map((i) => tracks[i])
                    .toList();

                TrackContextMenu.show(
                  context: context,
                  ref: ref,
                  isAdaptive: ref.read(configServiceProvider).adaptiveBg,
                  globalPosition: event.position,
                  tracks: tracks,
                  clickedIndex: index,
                  selectedTracks: selectedTracks,
                  playbackContextType: 'all_tracks',
                );
              },
              child: IconButton(icon: const Icon(Icons.more_horiz), onPressed: () {}),
            );
          },
        );
      },
    ),
  ];
}

/// ViewModel coordinating track actions and playback dispatch for the tracks page.
class TracksViewModel(final Ref _ref) with LoggerMixin {
  PlayerService get _playerService => _ref.read(playerServiceProvider);

  /// Plays the track at [index] in the context of the full [tracks] list.
  void playTrack(List<TrackWithArtists> tracks, int index) {
    if (tracks.isEmpty || index < 0 || index >= tracks.length) return;
    _playerService.setPlaylist(
      playbackContextType: 'all_tracks',
      playbackContextId: null,
      tracksToPlay: tracks,
      initialIndex: index,
    );
  }

  /// Plays the selected tracks as an ad-hoc playlist.
  void playAsPlaylist(
    List<TrackWithArtists> selectedTracks, {
    required int clickedIndex,
    required List<TrackWithArtists> allTracks,
  }) {
    if (selectedTracks.isEmpty) return;

    if (selectedTracks.length == 1) {
      playTrack(allTracks, clickedIndex);
      return;
    }

    final startingQueueIndex = selectedTracks.indexWhere(
      (t) => t.track.filePath == allTracks[clickedIndex].track.filePath,
    );

    _playerService.setPlaylist(
      playbackContextType: 'play_as_playlist',
      playbackContextId: null,
      tracksToPlay: selectedTracks,
      initialIndex: startingQueueIndex == -1 ? 0 : startingQueueIndex,
    );
  }
}

/// Riverpod provider exposing [TracksViewModel].
final tracksViewModelProvider = Provider<TracksViewModel>((ref) => TracksViewModel(ref));
