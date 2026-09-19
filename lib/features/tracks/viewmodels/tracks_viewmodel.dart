import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nordplayer/core/database/app_database.dart';
import 'package:nordplayer/core/models/table_column_config.dart';
import 'package:nordplayer/core/services/logger.dart';
import 'package:nordplayer/data/repositories/repositories.dart';
import 'package:nordplayer/services/player_service.dart';

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
    NotifierProvider<TracksPageColumnsNotifier, List<TableColumnConfig>>(
      TracksPageColumnsNotifier.new,
    );

class TracksPageColumnsNotifier extends Notifier<List<TableColumnConfig>> {
  @override
  List<TableColumnConfig> build() => _initialColumns;

  void toggleVisibility(String columnId) {
    state = state.map((col) {
      if (col.id == columnId) {
        return col.copyWith(isVisible: !col.isVisible);
      }
      return col;
    }).toList();
  }

  static const List<TableColumnConfig> _initialColumns = [
    TableColumnConfig(
      id: 'index',
      label: "#",
      width: 60,
      minWidth: 60,
      alignment: Alignment.centerRight,
    ),
    TableColumnConfig(
      id: 'title_artist',
      label: "Title/Artist",
      flex: 5,
      minWidth: 150,
    ),
    TableColumnConfig(
      id: 'album',
      label: "Album",
      flex: 3,
      minWidth: 100,
    ),
    TableColumnConfig(
      id: 'path',
      label: 'Path',
      flex: 3,
      minWidth: 120,
      isVisible: false,
    ),
    TableColumnConfig(
      id: 'date_added',
      label: "Date Added",
      width: 110,
      minWidth: 110,
      alignment: Alignment.centerRight,
      isVisible: false,
    ),
    TableColumnConfig(
      id: 'duration',
      label: 'Duration',
      width: 90,
      minWidth: 90,
      alignment: Alignment.centerRight,
    ),
    TableColumnConfig(
      id: 'context_menu',
      label: '',
      width: 75,
      minWidth: 75,
      alignment: Alignment.centerRight,
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
