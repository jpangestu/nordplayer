import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nordplayer/domain/models/models.dart';
import 'package:nordplayer/core/models/selection_state.dart';
import 'package:nordplayer/data/repositories/playlist_repository.dart';
import 'package:nordplayer/features/playlists/playlist_detail_viewmodel.dart';
import 'package:nordplayer/features/playlists/playlists_viewmodel.dart';
import 'package:nordplayer/features/tracks/widgets/track_context_menu.dart';
import 'package:nordplayer/core/system/config_service.dart';
import 'package:nordplayer/core/utils/datetime_extension.dart';
import 'package:nordplayer/core/utils/int_extension.dart';
import 'package:nordplayer/services/audio/player_service.dart';
import 'package:nordplayer/widgets/album_art_stack.dart';
import 'package:nordplayer/widgets/animated_equalizer_icon.dart';
import 'package:nordplayer/widgets/app_icon.dart';
import 'package:nordplayer/widgets/frosted_glass.dart';
import 'package:nordplayer/widgets/music_tile.dart';
import 'package:nordplayer/widgets/sliver_resizable_table.dart';

export 'package:nordplayer/features/playlists/playlist_detail_viewmodel.dart';

class PlaylistDetailView extends ConsumerWidget {
  final int playlistId;

  const PlaylistDetailView({super.key, required this.playlistId});

  Widget _buildCell(BuildContext context, String columnId, TrackWithArtists track, int index) {
    switch (columnId) {
      case 'index':
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
      case 'title_artist':
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
    final appConfig = ref.watch(configServiceProvider);
    // final appIconSet = ref.watch(appIconProvider);
    final playlistWithTracks = ref.watch(playlistWithTracksProvider(playlistId));
    final columnConfigs = ref.watch(playlistDetailPageColumnsProvider);
    final playlistDetailColumn = columnConfigs
        .map(
          (config) => TableColumn<TrackWithArtists>.fromConfig(
            config: config,
            cellBuilder: (context, track, index) => _buildCell(context, config.id, track, index),
          ),
        )
        .toList();
    final selectedIndices = ref.watch(selectedTracksIndexProvider('playlist'));

    return Scaffold(
      backgroundColor: appConfig.adaptiveBg ? Colors.transparent : Theme.of(context).colorScheme.surface,
      body: playlistWithTracks.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (data) {
          if (data.isEmpty) {
            return Column(
              children: [
                PlaylistDetailViewHeader(playlistId: playlistId, playlistWithTracks: data),
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
            );
          }

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: PlaylistDetailViewHeader(playlistId: playlistId, playlistWithTracks: data),
              ),

              SliverResizableTable(
                items: data.tracks,
                columns: playlistDetailColumn,
                selectedIndices: selectedIndices,
                rowHeight: 66.0,
                tablePadding: const EdgeInsets.only(left: 24, top: 8, bottom: 24, right: 24),
                isAdaptive: appConfig.adaptiveBg,
                headerBlur: appConfig.adaptiveBgPanelBlur,
                headerThemeOverlay: appConfig.adaptiveBgThemeOverlay,
                onRowClick: (index, {required isCtrl, required isShift}) {
                  ref
                      .read(selectedTracksIndexProvider('playlist').notifier)
                      .selectTrack(index, isCtrlSelect: isCtrl, isShiftSelect: isShift);
                },
                onRowDoubleClick: (index) {
                  ref
                      .read(playlistsViewModelProvider)
                      .playPlaylist(tracks: data.tracks, playlistId: playlistId, initialIndex: index);
                },
                onRowRightClick: (index, globalPosition) {
                  final selectionNotifier = ref.read(selectedTracksIndexProvider('playlist').notifier);
                  final currentSelection = ref.read(selectedTracksIndexProvider('playlist'));

                  if (!currentSelection.contains(index)) {
                    selectionNotifier.selectTrack(index, isCtrlSelect: false, isShiftSelect: false);
                  }

                  final updatedSelection = ref.read(selectedTracksIndexProvider('playlist'));
                  final sortedIndices = updatedSelection.toList()..sort();

                  final List<TrackWithArtists> selectedTracks = sortedIndices.map((i) => data.tracks[i]).toList();

                  TrackContextMenu.show(
                    context: context,
                    ref: ref,
                    isAdaptive: appConfig.adaptiveBg,
                    globalPosition: globalPosition,
                    tracks: data.tracks,
                    clickedIndex: index,
                    selectedTracks: selectedTracks,
                    playbackContextType: 'playlist',
                    playbackContextId: playlistId,
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class PlaylistDetailViewHeader extends ConsumerWidget {
  final int playlistId;
  final PlaylistWithTracks playlistWithTracks;
  const PlaylistDetailViewHeader({super.key, required this.playlistId, required this.playlistWithTracks});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final appConfig = ref.watch(configServiceProvider);
    final playlistDetailAlbumArt = ref.watch(playlistDetailsAlbumArtProvider(playlistId));
    final nowPlayingAlbumArt = ref.watch(current5TracksAlbumArtInQueueProvider);

    final int totalDurationMs = playlistWithTracks.tracks.fold(0, (sum, track) => sum + track.track.durationMs);

    return FrostedGlass(
      backgroundColor: appConfig.adaptiveBg
          ? theme.colorScheme.surfaceContainer.withValues(alpha: appConfig.adaptiveBgThemeOverlay)
          : theme.colorScheme.surface,
      blurSigma: appConfig.adaptiveBgPanelBlur,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: appConfig.adaptiveBg
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
                  alignment: .centerLeft,
                  child: AlbumArtStack(
                    imageUrls: ref.read(playbackContextProvider)?.type == 'playlist'
                        ? nowPlayingAlbumArt
                        : playlistDetailAlbumArt,
                    size: 180,
                    maxLayers: 5,
                    sliceWidth: 16,
                  ),
                ),
              ),
              Padding(
                padding: const .only(left: 24),
                child: Column(
                  mainAxisAlignment: .center,
                  crossAxisAlignment: .start,
                  children: [
                    Text(
                      playlistWithTracks.playlist.name,
                      style: theme.textTheme.headlineMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 4),

                    Text('${playlistWithTracks.tracks.length} Tracks, ${totalDurationMs.toTotalDurationString()}'),
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
