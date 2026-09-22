import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nordplayer/core/utils/datetime_extension.dart';
import 'package:nordplayer/core/utils/int_extension.dart';
import 'package:nordplayer/domain/models/models.dart';
import 'package:nordplayer/features/playlists/playlist_detail_ui_state.dart';
import 'package:nordplayer/features/playlists/playlist_detail_viewmodel.dart';
import 'package:nordplayer/features/tracks/widgets/track_context_menu.dart';
import 'package:nordplayer/widgets/album_art_stack.dart';
import 'package:nordplayer/widgets/animated_equalizer_icon.dart';
import 'package:nordplayer/widgets/app_icon.dart';
import 'package:nordplayer/widgets/frosted_glass.dart';
import 'package:nordplayer/widgets/music_tile.dart';
import 'package:nordplayer/widgets/sliver_resizable_table.dart';

/// Pure presentation View for the Playlist Detail screen, observing [PlaylistDetailUiState].
class PlaylistDetailView extends ConsumerWidget {
  final int playlistId;

  const PlaylistDetailView({super.key, required this.playlistId});

  Widget _buildCell(
    BuildContext context,
    String columnId,
    TrackWithArtists track,
    int index,
    PlaylistDetailUiState uiState,
  ) {
    switch (columnId) {
      case 'index':
        final isActiveTrack = uiState.activeTrackPath == track.track.filePath;
        if (isActiveTrack) {
          return AnimatedEqualizerIcon(
            color: Theme.of(context).colorScheme.primary,
            size: 16,
            isPlaying: uiState.isAudioPlaying,
          );
        }
        return Text(
          "${index + 1}",
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6)),
        );
      case 'title_artist':
        final isPlaying = uiState.activeTrackPath == track.track.filePath;
        return MusicTile(
          selected: isPlaying,
          albumArtPath: track.album.albumArtPath,
          title: track.track.title,
          artists: track.artists.map((a) => a.name).toList(),
          padding: EdgeInsets.zero,
        );
      case 'album':
        return Text(track.album.title, maxLines: 1, overflow: TextOverflow.ellipsis);
      case 'path':
        return Text(track.track.filePath, maxLines: 1, overflow: TextOverflow.ellipsis);
      case 'date_added':
        return Text(track.track.dateAdded.toRelativeTime(), maxLines: 1, overflow: TextOverflow.ellipsis);
      case 'duration':
        return Text(track.track.durationMs.toDurationString());
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final uiState = ref.watch(playlistDetailViewModelProvider(playlistId));
    final viewModel = ref.read(playlistDetailViewModelProvider(playlistId).notifier);

    final playlistDetailColumns = uiState.columns
        .map(
          (config) => TableColumn<TrackWithArtists>.fromConfig(
            config: config,
            cellBuilder: (context, track, index) => _buildCell(context, config.id, track, index, uiState),
          ),
        )
        .toList();

    if (uiState.isLoading) {
      return Scaffold(
        backgroundColor: uiState.isAdaptiveBg ? Colors.transparent : theme.colorScheme.surface,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (uiState.errorMessage != null) {
      return Scaffold(
        backgroundColor: uiState.isAdaptiveBg ? Colors.transparent : theme.colorScheme.surface,
        body: Center(child: Text('Error: ${uiState.errorMessage}')),
      );
    }

    if (uiState.isEmpty) {
      return Scaffold(
        backgroundColor: uiState.isAdaptiveBg ? Colors.transparent : theme.colorScheme.surface,
        body: Column(
          children: [
            PlaylistDetailViewHeader(playlistId: playlistId, uiState: uiState),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Playlist is still empty", style: theme.textTheme.titleLarge),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () {
                      context.go('/tracks');
                    },
                    icon: const AppIcon(Icons.add_circle_outline),
                    label: const Text("Add Some Tracks"),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: uiState.isAdaptiveBg ? Colors.transparent : theme.colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: PlaylistDetailViewHeader(playlistId: playlistId, uiState: uiState),
          ),
          SliverResizableTable(
            items: uiState.tracks,
            columns: playlistDetailColumns,
            selectedIndices: uiState.selectedIndices,
            rowHeight: 66.0,
            tablePadding: const EdgeInsets.only(left: 24, top: 8, bottom: 24, right: 24),
            isAdaptive: uiState.isAdaptiveBg,
            headerBlur: uiState.adaptiveBgPanelBlur,
            headerThemeOverlay: uiState.adaptiveBgThemeOverlay,
            onRowClick: (index, {required isCtrl, required isShift}) {
              viewModel.selectTrack(index, isCtrlSelect: isCtrl, isShiftSelect: isShift);
            },
            onRowDoubleClick: (index) {
              viewModel.playTrack(index);
            },
            onRowRightClick: (index, globalPosition) {
              if (!uiState.selectedIndices.contains(index)) {
                viewModel.selectSingle(index);
              }

              final updatedSelection = ref.read(playlistDetailViewModelProvider(playlistId)).selectedIndices;
              final sortedIndices = updatedSelection.toList()..sort();
              final List<TrackWithArtists> selectedTracks = sortedIndices.map((i) => uiState.tracks[i]).toList();

              TrackContextMenu.show(
                context: context,
                ref: ref,
                isAdaptive: uiState.isAdaptiveBg,
                globalPosition: globalPosition,
                tracks: uiState.tracks,
                clickedIndex: index,
                selectedTracks: selectedTracks,
                playbackContextType: 'playlist',
                playbackContextId: playlistId,
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Header widget displaying album art collage, playlist name, and aggregate stats.
class PlaylistDetailViewHeader extends ConsumerWidget {
  final int playlistId;
  final PlaylistDetailUiState uiState;

  const PlaylistDetailViewHeader({super.key, required this.playlistId, required this.uiState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final playlistName = uiState.playlist?.name ?? '';
    final totalDurationMs = uiState.totalDurationMs;
    final trackCount = uiState.trackCount;

    return FrostedGlass(
      backgroundColor: uiState.isAdaptiveBg
          ? theme.colorScheme.surfaceContainer.withValues(alpha: uiState.adaptiveBgThemeOverlay)
          : theme.colorScheme.surface,
      blurSigma: uiState.adaptiveBgPanelBlur,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: uiState.isAdaptiveBg
            ? const BoxDecoration()
            : BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    theme.colorScheme.surfaceContainer.withValues(alpha: 1.0),
                    theme.colorScheme.surface.withValues(alpha: 1.0),
                  ],
                ),
              ),
        child: Padding(
          padding: const EdgeInsets.only(top: 0.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                height: 220,
                width: 244,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: AlbumArtStack(imageUrls: uiState.albumArtCovers, size: 180, maxLayers: 5, sliceWidth: 16),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      playlistName,
                      style: theme.textTheme.headlineMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text('$trackCount Tracks, ${totalDurationMs.toTotalDurationString()}'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
