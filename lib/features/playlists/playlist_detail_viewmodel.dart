import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nordplayer/core/models/table_column_config.dart';
import 'package:nordplayer/data/repositories/repositories.dart';

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
    NotifierProvider<PlaylistDetailPageColumnsNotifier, List<TableColumnConfig>>(
      PlaylistDetailPageColumnsNotifier.new,
    );

class PlaylistDetailPageColumnsNotifier extends Notifier<List<TableColumnConfig>> {
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
      isVisible: true,
    ),
    TableColumnConfig(
      id: 'duration',
      label: 'Duration',
      width: 90,
      minWidth: 90,
      alignment: Alignment.centerRight,
    ),
  ];
}
