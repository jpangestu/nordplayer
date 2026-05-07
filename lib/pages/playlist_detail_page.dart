import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nordplayer/database/app_database.dart';
import 'package:nordplayer/pages/pages_context_menu.dart';
import 'package:nordplayer/pages/pages_helper.dart';
import 'package:nordplayer/services/config_service.dart';
import 'package:nordplayer/services/player_service.dart';
import 'package:nordplayer/utils/datetime_extension.dart';
import 'package:nordplayer/utils/int_extension.dart';
import 'package:nordplayer/widgets/album_art_stack.dart';
import 'package:nordplayer/widgets/animated_equalizer_icon.dart';
import 'package:nordplayer/widgets/app_icon.dart';
import 'package:nordplayer/widgets/frosted_glass.dart';
import 'package:nordplayer/widgets/music_tile.dart';
import 'package:nordplayer/widgets/sliver_resizable_table.dart';

class PlaylistDetailPage extends ConsumerWidget {
  final int playlistId;

  const PlaylistDetailPage({super.key, required this.playlistId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final appConfig = ref.watch(configServiceProvider).requireValue;
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
            Column(
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
    final appConfig = ref.watch(configServiceProvider).requireValue;
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

// ============================================= Provider =============================================================

/// Provider 5 album art for tracks in tracks page
// Change to Provider.family<ReturnType, ArgumentType>
final playlistDetailsAlbumArtProvider = Provider.family<List<String>, int>((ref, playlistId) {
  // Replace the hardcoded 1 with the dynamic playlistId
  final playlistTracksAsync = ref.watch(playlistTracksStreamProvider(playlistId));
  final playlistTracks = playlistTracksAsync.value ?? [];

  if (playlistTracks.isEmpty) return [];

  final List<String> wallCovers = [];
  final Set<String> seenWallCovers = {};

  final randomLibrary = [...playlistTracks]..shuffle();

  for (final track in randomLibrary) {
    final artPath = track.album.albumArtPath;
    if (artPath != null && artPath.isNotEmpty && !seenWallCovers.contains(artPath)) {
      seenWallCovers.add(artPath);
      wallCovers.add(artPath);
    }
    if (wallCovers.length >= 5) break;
  }

  return wallCovers;
});

final playlistDetailPageColumnsProvider =
    NotifierProvider<PlaylistDetailPageColumnsNotifier, List<TableColumn<TrackWithArtists>>>(
      PlaylistDetailPageColumnsNotifier.new,
    );

class PlaylistDetailPageColumnsNotifier extends Notifier<List<TableColumn<TrackWithArtists>>> {
  @override
  List<TableColumn<TrackWithArtists>> build() {
    return _initialColumns;
  }

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
      alignment: .centerRight,
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
