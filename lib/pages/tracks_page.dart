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
import 'package:nordplayer/widgets/context_menu.dart';
import 'package:nordplayer/widgets/frosted_glass.dart';
import 'package:nordplayer/widgets/music_tile.dart';
import 'package:nordplayer/widgets/sliver_resizable_table.dart';

class Tracks extends ConsumerStatefulWidget {
  const Tracks({super.key});

  @override
  ConsumerState<Tracks> createState() => _TracksState();
}

class _TracksState extends ConsumerState<Tracks> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appConfig = ref.watch(configServiceProvider).requireValue;

    final libraryAsync = ref.watch(libraryStreamProvider);
    final selectedIndices = ref.watch(selectedTracksIndexProvider('all_tracks'));
    final tracksPageTableColumns = ref.watch(tracksPageColumnsProvider);

    return Scaffold(
      backgroundColor: appConfig.adaptiveBg ? Colors.transparent : Theme.of(context).colorScheme.surface,
      body: libraryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error loading tracks: $error')),
        data: (tracks) {
          if (tracks.isEmpty) {
            return Column(
              children: [
                TracksPageHeader(tracks: tracks),

                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Your library is empty",
                        style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Scan your local folders to set up your music library.",
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: () {
                          context.go('/settings/library-management');
                        },
                        icon: const AppIcon(Icons.create_new_folder),
                        label: const Text("Add Music Folders"),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: TracksPageHeader(tracks: tracks)),

              SliverResizableTable(
                items: tracks,
                columns: tracksPageTableColumns,
                selectedIndices: selectedIndices,
                rowHeight: 66.0,
                tablePadding: const EdgeInsets.only(left: 24, top: 8, bottom: 24, right: 24),
                isAdaptive: appConfig.adaptiveBg,
                headerBlur: appConfig.adaptiveBgPanelBlur,
                headerThemeOverlay: appConfig.adaptiveBgThemeOverlay,
                onHeaderRightClick: (globalPosition) {
                  ContextMenu.show(
                    context: context,
                    isAdaptive: appConfig.adaptiveBg,
                    globalPosition: globalPosition,
                    actionMenus: [ContextMenuCustomWidget(child: const HeaderColumnSelectorMenu())],
                  );
                },
                onRowClick: (index, {required isCtrl, required isShift}) {
                  ref
                      .read(selectedTracksIndexProvider('all_tracks').notifier)
                      .selectTrack(index, isCtrlSelect: isCtrl, isShiftSelect: isShift);
                },
                onRowDoubleClick: (index) {
                  ref
                      .read(playerServiceProvider)
                      .setPlaylist(
                        playbackContextType: 'all_tracks',
                        playbackContextId: null,
                        tracksToPlay: tracks,
                        initialIndex: index,
                      );
                },
                onRowRightClick: (index, globalPosition) {
                  final selectionNotifier = ref.read(selectedTracksIndexProvider('all_tracks').notifier);
                  final currentSelection = ref.read(selectedTracksIndexProvider('all_tracks'));

                  // If right-clicking an unselected item, select it first and clear others
                  if (!currentSelection.contains(index)) {
                    selectionNotifier.selectTrack(index, isCtrlSelect: false, isShiftSelect: false);
                  }

                  final updatedSelection = ref.read(selectedTracksIndexProvider('all_tracks'));

                  // Convert to list and sort the indices first
                  final sortedIndices = updatedSelection.toList()..sort();
                  final List<TrackWithArtists> selectedTracks = sortedIndices.map((i) => tracks[i]).toList();

                  TrackContextMenu.show(
                    context: context,
                    ref: ref,
                    isAdaptive: appConfig.adaptiveBg,
                    globalPosition: globalPosition,
                    tracks: tracks,
                    clickedIndex: index,
                    selectedTracks: selectedTracks,
                    playbackContextType: 'all_tracks',
                    playbackContextId: null,
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

class TracksPageHeader extends ConsumerWidget {
  final List<TrackWithArtists> tracks;
  const TracksPageHeader({super.key, required this.tracks});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final appConfig = ref.watch(configServiceProvider).requireValue;
    final libraryAlbumArt = ref.watch(libraryAlbumArtProvider);
    final nowPlayingAlbumArt = ref.watch(current5TracksAlbumArtInQueueProvider);

    final int totalDurationMs = tracks.fold(0, (sum, track) => sum + track.track.durationMs);

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
                    imageUrls: ref.read(playbackContextProvider)?.type == 'all_tracks'
                        ? nowPlayingAlbumArt
                        : libraryAlbumArt,
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
                    const Text(
                      'Tracks',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 4),

                    Text('${tracks.length} Tracks, ${totalDurationMs.toTotalDurationString()}'),
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

class HeaderColumnSelectorMenu extends ConsumerWidget {
  const HeaderColumnSelectorMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final columns = ref.watch(tracksPageColumnsProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: columns.map((col) {
        return InkWell(
          onTap: () {
            ref.read(tracksPageColumnsProvider.notifier).toggleVisibility(col.id);
          },
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(
                  col.isVisible ? Icons.check_box : Icons.check_box_outline_blank,
                  size: 20,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                const SizedBox(width: 12),
                Text(
                  col.label.isEmpty ? 'Context Menu' : col.label,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ============================================= Provider =============================================================

/// Provider 5 album art for tracks in tracks page
final libraryAlbumArtProvider = Provider<List<String>>((ref) {
  final libraryAsync = ref.watch(libraryStreamProvider);
  final libraryTracks = libraryAsync.value ?? [];

  if (libraryTracks.isEmpty) return [];

  final List<String> wallCovers = [];
  final Set<String> seenWallCovers = {};

  final randomLibrary = [...libraryTracks]..shuffle();

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

final tracksPageColumnsProvider = NotifierProvider<TracksPageColumnsNotifier, List<TableColumn<TrackWithArtists>>>(
  TracksPageColumnsNotifier.new,
);

class TracksPageColumnsNotifier extends Notifier<List<TableColumn<TrackWithArtists>>> {
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
      id: 'title',
      label: "Title",
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
                final selectedTracks = selectedIndices.map((i) => tracks[i]).toList();

                TrackContextMenu.show(
                  context: context,
                  ref: ref,
                  isAdaptive: ref.read(configServiceProvider).requireValue.adaptiveBg,
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
