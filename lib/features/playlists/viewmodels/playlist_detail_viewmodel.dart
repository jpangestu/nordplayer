import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nordplayer/core/database/app_database.dart';
import 'package:nordplayer/core/utils/datetime_extension.dart';
import 'package:nordplayer/core/utils/int_extension.dart';
import 'package:nordplayer/data/repositories/repositories.dart';
import 'package:nordplayer/services/player_service.dart';
import 'package:nordplayer/widgets/animated_equalizer_icon.dart';
import 'package:nordplayer/widgets/music_tile.dart';
import 'package:nordplayer/widgets/sliver_resizable_table.dart';

/// Computes up to 5 unique album art paths for the playlist header collage.
final playlistDetailsAlbumArtProvider = Provider.autoDispose.family<List<String>, int>((ref, playlistId) {
  final playlistTracksAsync = ref.watch(playlistTracksStreamProvider(playlistId));
  final playlistTracks = playlistTracksAsync.value ?? [];

  if (playlistTracks.isEmpty) return const [];

  final wallCovers = <String>[];
  final seenWallCovers = <String>{};

  for (final track in playlistTracks) {
    final artPath = track.album.albumArtPath;
    if (artPath != null && artPath.isNotEmpty && !seenWallCovers.contains(artPath)) {
      seenWallCovers.add(artPath);
      wallCovers.add(artPath);
    }
    if (wallCovers.length >= 5) break;
  }

  return wallCovers;
});

/// Manages table column configurations (widths, ordering, visibility) for the playlist detail view.
final playlistDetailPageColumnsProvider =
    NotifierProvider<PlaylistDetailPageColumnsNotifier, List<TableColumn<TrackWithArtists>>>(
      PlaylistDetailPageColumnsNotifier.new,
    );

class PlaylistDetailPageColumnsNotifier extends Notifier<List<TableColumn<TrackWithArtists>>> {
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
        return Text(track.album.title, maxLines: 1, overflow: TextOverflow.ellipsis);
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
      alignment: Alignment.centerRight,
      isVisible: true,
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
  ];
}
