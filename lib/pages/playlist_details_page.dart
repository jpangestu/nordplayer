import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nordplayer/database/app_database.dart';
import 'package:nordplayer/services/config_service.dart';
import 'package:nordplayer/services/player_service.dart';
import 'package:nordplayer/widgets/album_art_stack.dart';
import 'package:nordplayer/widgets/album_art_wall.dart';
import 'package:nordplayer/widgets/context_menu.dart';
import 'package:nordplayer/widgets/shortcuts.dart';
import 'package:nordplayer/widgets/sliver_resizable_table_layout.dart';
import 'package:nordplayer/pages/library_page.dart';

class PlaylistDetailPage extends ConsumerWidget {
  final int playlistId;

  const PlaylistDetailPage({super.key, required this.playlistId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    // Watch the specific playlist using the family provider
    final playlistAsync = ref.watch(playlistWithTracksProvider(playlistId));
    final tableColumns = ref.watch(libraryTableColumnsProvider);

    // Isolate selection state to this specific playlist instance
    final tableId = 'playlist_$playlistId';
    final selectedIndices = ref.watch(selectedTracksIndexProvider(tableId));

    return Shortcuts(
      shortcuts: <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): const PlaySelectedIntent(),
        SingleActivator(LogicalKeyboardKey.numpadEnter):
            const PlaySelectedIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          PlaySelectedIntent: PlaySelectedAction(
            ref: ref,
            tableId: tableId,
            playbackContextType: 'playlist',
            playbackContextId: playlistId,
            getTracks: () =>
                ref
                    .read(playlistWithTracksProvider(playlistId))
                    .value
                    ?.tracks ??
                [],
          ),
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
            extendBodyBehindAppBar: true,
            body: playlistAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
              data: (data) {
                final playlist = data.playlist;
                final tracks = data.tracks;

                return CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 280,
                        child: PlaylistHeroHeader(
                          playlist: playlist,
                          tracks: tracks,
                        ),
                      ),
                    ),

                    if (tracks.isEmpty)
                      SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "This playlist is empty",
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Right-click tracks in your Library to add them here.",
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.6,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              FilledButton.icon(
                                onPressed: () => context.go('/library'),
                                icon: const Icon(Icons.music_note),
                                label: const Text("Go to Library"),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      SliverInteractiveTable<TrackWithArtists>(
                        items: tracks,
                        columns: tableColumns,
                        selectedIndices: selectedIndices,
                        rowHeight: 66.0,
                        onColumnsResized: (newWidths) {
                          ref
                              .read(libraryTableColumnsProvider.notifier)
                              .updateColumnWidths(newWidths);
                        },
                        onHeaderRightClick: (globalPosition) {
                          ContextMenu.show(
                            context: context,
                            globalPosition: globalPosition,
                            actionMenus: [
                              ContextMenuCustomWidget(
                                child: ColumnToggleContextMenu(),
                              ),
                            ],
                          );
                        },
                        onRowClick:
                            (index, {required isCtrl, required isShift}) {
                              ref
                                  .read(
                                    selectedTracksIndexProvider(
                                      tableId,
                                    ).notifier,
                                  )
                                  .selectTrack(
                                    index,
                                    isCtrlSelect: isCtrl,
                                    isShiftSelect: isShift,
                                  );
                            },
                        onRowDoubleClick: (index) {
                          ref
                              .read(playerServiceProvider)
                              .setPlaylist(
                                playbackContextType: 'playlist',
                                playbackContextId: playlist.id,
                                tracksToPlay: tracks,
                                initialIndex: index,
                              );
                        },
                        onRowRightClick: (index, globalPosition) {
                          final selectionNotifier = ref.read(
                            selectedTracksIndexProvider(tableId).notifier,
                          );
                          final currentSelection = ref.read(
                            selectedTracksIndexProvider(tableId),
                          );

                          if (!currentSelection.contains(index)) {
                            selectionNotifier.selectTrack(
                              index,
                              isCtrlSelect: false,
                              isShiftSelect: false,
                            );
                          }

                          final updatedSelection = ref.read(
                            selectedTracksIndexProvider(tableId),
                          );
                          final sortedIndices = updatedSelection.toList()
                            ..sort();
                          final List<TrackWithArtists> selectedTracks =
                              sortedIndices.map((i) => tracks[i]).toList();

                          TrackContextMenu.show(
                            context: context,
                            ref: ref,
                            isAdaptive: ref
                                .watch(configServiceProvider)
                                .requireValue
                                .adaptiveBg,
                            globalPosition: globalPosition,
                            allTracks: tracks,
                            clickedIndex: index,
                            selectedTracks: selectedTracks,
                            // Pass the context dynamically!
                            playbackContextType: 'playlist',
                            playbackContextId: playlist.id,
                          );
                        },
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class PlaylistHeroHeader extends ConsumerWidget {
  final PlaylistData playlist;
  final List<TrackWithArtists> tracks;

  const PlaylistHeroHeader({
    super.key,
    required this.playlist,
    required this.tracks,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final nowPlayingAlbumArt = ref.watch(current5TracksAlbumArtInQueueProvider);

    // Dynamically pull up to 30 unique covers from this specific playlist
    final Set<String> uniqueCovers = {};
    for (final t in tracks) {
      if (t.album.albumArtPath?.isNotEmpty == true) {
        uniqueCovers.add(t.album.albumArtPath!);
      }
      if (uniqueCovers.length >= 30) break;
    }
    final playlistCovers = uniqueCovers.toList();

    // Check if this playlist is the one currently playing
    final isPlayingThisPlaylist =
        ref
            .watch(playbackContextProvider)
            ?.isPlaying('playlist', playlist.id) ??
        false;

    final int totalMs = tracks.fold(
      0,
      (sum, track) => sum + track.track.durationMs,
    );
    final Duration totalDuration = Duration(milliseconds: totalMs);

    String formatTotalDuration(Duration d) {
      final hours = d.inHours;
      final minutes = d.inMinutes % 60;
      return hours > 0 ? '$hours hr $minutes min' : '$minutes min';
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          color: theme.colorScheme.surfaceContainer,
          child: AlbumArtWall(imageUrls: playlistCovers),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 60),
                child: SizedBox(
                  width: 244,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: AlbumArtStack(
                      imageUrls: isPlayingThisPlaylist
                          ? nowPlayingAlbumArt
                          : playlistCovers,
                      size: 180,
                      maxLayers: 5,
                      sliceWidth: 16,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 24, top: 140, right: 16),
                child: Column(
                  crossAxisAlignment: .start,
                  children: [
                    Text(
                      playlist.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${tracks.length} Tracks - ${formatTotalDuration(totalDuration)}',
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
