import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nordplayer/core/database/app_database.dart';
import 'package:nordplayer/data/repositories/repositories.dart';
import 'package:nordplayer/features/playlists/viewmodels/playlist_detail_viewmodel.dart';
import 'package:nordplayer/pages/pages_context_menu.dart';
import 'package:nordplayer/pages/pages_helper.dart';
import 'package:nordplayer/core/services/config_service.dart';
import 'package:nordplayer/services/player_service.dart';
import 'package:nordplayer/core/utils/int_extension.dart';

export 'package:nordplayer/features/playlists/viewmodels/playlist_detail_viewmodel.dart';
import 'package:nordplayer/widgets/album_art_stack.dart';
import 'package:nordplayer/widgets/app_icon.dart';
import 'package:nordplayer/widgets/frosted_glass.dart';
import 'package:nordplayer/widgets/sliver_resizable_table.dart';

class PlaylistDetailPage extends ConsumerWidget {
  final int playlistId;

  const PlaylistDetailPage({super.key, required this.playlistId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final appConfig = ref.watch(configServiceProvider);
    // final appIconSet = ref.watch(appIconProvider);
    final playlistWithTracks = ref.watch(playlistWithTracksProvider(playlistId));
    final playlistDetailColumn = ref.watch(playlistDetailPageColumnsProvider);
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
                PlaylistDetailPageHeader(playlistId: playlistId, playlistWithTracks: data),
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
                child: PlaylistDetailPageHeader(playlistId: playlistId, playlistWithTracks: data),
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
                      .read(playerServiceProvider)
                      .setPlaylist(
                        playbackContextType: 'playlist',
                        playbackContextId: playlistId,
                        tracksToPlay: data.tracks,
                        initialIndex: index,
                      );
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

class PlaylistDetailPageHeader extends ConsumerWidget {
  final int playlistId;
  final PlaylistWithTracks playlistWithTracks;
  const PlaylistDetailPageHeader({super.key, required this.playlistId, required this.playlistWithTracks});

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
