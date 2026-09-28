import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nordplayer/data/repositories/playlist_repository.dart';
import 'package:nordplayer/data/repositories/ui_preferences_repository.dart';
import 'package:nordplayer/data/services/audio/playback_controller.dart';
import 'package:nordplayer/data/services/system/platform_service.dart' show showInFolder;
import 'package:nordplayer/domain/models/composite_models.dart';
import 'package:nordplayer/domain/models/playback_context.dart';
import 'package:nordplayer/routing/router.dart';
import 'package:nordplayer/ui/playlists/playlists_viewmodel.dart';
import 'package:nordplayer/ui/playlists/widgets/playlist_dialogs.dart';
import 'package:nordplayer/ui/queue/queue_viewmodel.dart';
import 'package:nordplayer/ui/shared/themes/icon_sets/app_icon_set.dart';
import 'package:nordplayer/ui/shared/ui/app_icon.dart';
import 'package:nordplayer/ui/shared/ui/context_menu.dart';
import 'package:nordplayer/ui/shared/ui/nord_snack_bar.dart';
import 'package:nordplayer/ui/shared/ui/selection_state.dart';

class TrackContextMenu {
  /// Shows the standard right-click menu for music tracks.
  static void show({
    required BuildContext context,
    required WidgetRef ref,
    required bool isAdaptive,
    required Offset globalPosition,
    required List<TrackWithArtists> tracks,
    required int clickedIndex,
    required List<TrackWithArtists> selectedTracks,
    required String playbackContextType,
    int? playbackContextId,
    String? playbackContextTitle,
    PlaybackContext? playbackContext,
    bool isInQueue = false,
  }) {
    final appIconSet = ref.read(appIconProvider);

    ContextMenu.show(
      isAdaptive: isAdaptive,
      context: context,
      globalPosition: globalPosition,
      actionMenus: [
        ContextMenuActions(
          icon: appIconSet.play,
          label: selectedTracks.length == 1 ? 'Play' : 'Play as playlist',
          onTap: () {
            if (selectedTracks.length == 1) {
              ref
                  .read(playbackControllerProvider)
                  .setPlaylist(
                    context: playbackContext,
                    playbackContextType: playbackContextType,
                    playbackContextId: playbackContextId,
                    playbackContextTitle: playbackContextTitle,
                    tracksToPlay: tracks,
                    initialIndex: clickedIndex,
                  );
            } else {
              // Keep the playlist perfectly sorted by library index
              final playlistToPlay = selectedTracks;

              // Find where the right-clicked track lives inside this sorted list
              final startingQueueIndex = playlistToPlay.indexWhere(
                (t) => t.track.filePath == tracks[clickedIndex].track.filePath,
              );

              // Pass the sorted list, but tell the player to start at the clicked track
              ref
                  .read(playbackControllerProvider)
                  .setPlaylist(
                    playbackContextType: 'play_as_playlist',
                    playbackContextId: null,
                    tracksToPlay: playlistToPlay,
                    initialIndex: startingQueueIndex == -1 ? 0 : startingQueueIndex,
                  );
            }
          },
        ),
        // Only show "Play Next" if we aren't already looking at the queue
        if (!isInQueue)
          ContextMenuActions(
            icon: appIconSet.playNext,
            label: 'Play Next',
            onTap: () {
              ref.read(playbackControllerProvider).playNext(selectedTracks);

              final showQueue = ref.read(uiPreferencesRepositoryProvider).currentPreferences.showQueue;

              showQueue
                  ? showNordSnackBar(message: 'Added ${selectedTracks.length} track(s) to queue', type: .general)
                  : showNordSnackBar(
                      message: 'Added ${selectedTracks.length} track(s) to queue',
                      type: .general,
                      actionLabel: 'View Queue',
                      onAction: (snackBarContext) {
                        ref.read(uiPreferencesRepositoryProvider).setShowQueue(true);
                      },
                    );
            },
          ),

        // Only show "Add to queue" if we aren't already looking at the queue
        if (!isInQueue)
          ContextMenuActions(
            icon: appIconSet.addToQueue,
            label: 'Add to queue',
            onTap: () {
              ref.read(playbackControllerProvider).addToQueue(selectedTracks);

              final showQueue = ref.read(uiPreferencesRepositoryProvider).currentPreferences.showQueue;

              showQueue
                  ? showNordSnackBar(message: 'Added ${selectedTracks.length} track(s) to queue', type: .general)
                  : showNordSnackBar(
                      message: 'Added ${selectedTracks.length} track(s) to queue',
                      type: .general,
                      actionLabel: 'View Queue',
                      onAction: (snackBarContext) {
                        ref.read(uiPreferencesRepositoryProvider).setShowQueue(true);
                      },
                    );
            },
          ),

        // Show "Remove from queue" if we ARE looking at the queue
        if (isInQueue)
          ContextMenuActions(
            icon: appIconSet.removeFromQueue,
            label: 'Remove from queue',
            onTap: () {
              final selectionSet = ref.read(selectedTracksIndexProvider('queue_page'));
              if (selectionSet.isNotEmpty) {
                ref.read(queueViewModelProvider.notifier).removeSelectedTracks(selectionSet.toList());
              } else {
                ref.read(queueViewModelProvider.notifier).removeTrack(clickedIndex);
              }
            },
          ),
        ContextSubMenuAction(
          icon: appIconSet.add,
          label: 'Add to playlist',
          children: [ContextMenuCustomWidget(child: SearchablePlaylistContextSubMenu(tracksToAdd: selectedTracks))],
        ),
        ContextMenuDivider(),
        if (clickedIndex >= 0 && clickedIndex < tracks.length)
          ContextMenuActions(
            icon: appIconSet.showInfolder,
            label: 'Show in folder',
            onTap: () async {
              final path = tracks[clickedIndex].track.filePath;
              await showInFolder(path);
            },
          ),
      ],
    );
  }
}

class SearchTracksContextMenu {
  /// Shows a simplified right-click menu for track. Used in search result panel
  /// No selection here
  static void show({
    required BuildContext context,
    required WidgetRef ref,
    required bool isAdaptive,
    required Offset globalPosition,
    required List<TrackWithArtists> tracks,
    required int indexToPlay,
    required String playbackContextType,
    int? playbackContextId,
    String? playbackContextTitle,
    PlaybackContext? playbackContext,
    bool isInQueue = false,
  }) {
    final appIconSet = ref.read(appIconProvider);

    ContextMenu.show(
      isAdaptive: isAdaptive,
      context: context,
      globalPosition: globalPosition,
      actionMenus: [
        ContextMenuActions(
          icon: appIconSet.play,
          label: 'Play',
          onTap: () {
            ref
                .read(playbackControllerProvider)
                .setPlaylist(
                  context: playbackContext,
                  playbackContextType: playbackContextType,
                  playbackContextId: playbackContextId,
                  playbackContextTitle: playbackContextTitle,
                  tracksToPlay: tracks,
                  initialIndex: indexToPlay,
                );
          },
        ),

        if (!isInQueue)
          ContextMenuActions(
            icon: LucideIcons.listStart,
            label: 'Play Next',
            onTap: () {
              ref.read(playbackControllerProvider).playNext([tracks[indexToPlay]]);

              final showQueue = ref.read(uiPreferencesRepositoryProvider).currentPreferences.showQueue;

              showQueue
                  ? showNordSnackBar(message: 'Added 1 track to queue', type: .general)
                  : showNordSnackBar(
                      message: 'Added 1 track to queue',
                      type: .general,
                      actionLabel: 'View Queue',
                      onAction: (snackBarContext) {
                        ref.read(uiPreferencesRepositoryProvider).setShowQueue(true);
                      },
                    );
            },
          ),

        if (!isInQueue)
          ContextMenuActions(
            icon: appIconSet.addToQueue,
            label: 'Add to queue',
            onTap: () {
              ref.read(playbackControllerProvider).addToQueue([tracks[indexToPlay]]);

              final showQueue = ref.read(uiPreferencesRepositoryProvider).currentPreferences.showQueue;

              showQueue
                  ? showNordSnackBar(message: 'Added 1 track to queue', type: .general)
                  : showNordSnackBar(
                      message: 'Added 1 track to queue',
                      type: .general,
                      actionLabel: 'View Queue',
                      onAction: (snackBarContext) {
                        ref.read(uiPreferencesRepositoryProvider).setShowQueue(true);
                      },
                    );
            },
          ),

        ContextSubMenuAction(
          icon: appIconSet.add,
          label: 'Add to playlist',
          children: [
            ContextMenuCustomWidget(child: SearchablePlaylistContextSubMenu(tracksToAdd: [tracks[indexToPlay]])),
          ],
        ),
      ],
    );
  }
}

/// Context sub-menu for add to playlist table row context menu
class SearchablePlaylistContextSubMenu extends ConsumerStatefulWidget {
  final List<TrackWithArtists> tracksToAdd;

  const SearchablePlaylistContextSubMenu({super.key, required this.tracksToAdd});

  @override
  ConsumerState<SearchablePlaylistContextSubMenu> createState() => _SearchablePlaylistMenuState();
}

class _SearchablePlaylistMenuState extends ConsumerState<SearchablePlaylistContextSubMenu> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final playlistsWithDetails = ref.watch(playlistsStreamProvider);
    final appIconSet = ref.read(appIconProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // -- SEARCH BOX --
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: SizedBox(
            height: 32,
            child: TextField(
              autofocus: true,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Find a playlist',
                prefixIcon: AppIcon(appIconSet.search, size: 16),
                contentPadding: EdgeInsets.zero,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide.none),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              ),
              onChanged: (val) => setState(() => _query = val),
            ),
          ),
        ),

        // -- NEW PLAYLIST BUTTON --
        InkWell(
          onTap: () async {
            ContextMenu.closeAll();
            await showCreatePlaylistDialogAndAddTracks(context, widget.tracksToAdd);
          },
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                AppIcon(appIconSet.add, size: 20),
                const SizedBox(width: 12),
                const Text('New playlist', style: TextStyle(fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ),

        Divider(height: 9, color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),

        // -- PLAYLIST LISTS --
        playlistsWithDetails.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, st) => const Padding(padding: EdgeInsets.all(16), child: Text('Error loading playlists')),
          data: (playlistsWithDetailsData) {
            final filtered = playlistsWithDetailsData
                .where((p) => p.playlist.name.toLowerCase().contains(_query.toLowerCase()))
                .toList();

            if (filtered.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'No playlists found.',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                ),
              );
            }

            return ConstrainedBox(
              // Constrain this list so it scrolls independently if needed
              constraints: const BoxConstraints(maxHeight: 250),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final playlist = filtered[index].playlist;
                  return InkWell(
                    onTap: () async {
                      final vm = ref.read(playlistsViewModelProvider.notifier);
                      final trackIds = widget.tracksToAdd.map((t) => t.track.id).toList();
                      await vm.addTracksToPlaylist(playlist.id, trackIds);

                      ContextMenu.closeAll();

                      showNordSnackBar(
                        message: 'Added to ${playlist.name}',
                        type: .general,
                        actionLabel: 'View',
                        onAction: (snackBarContext) {
                          snackBarContext.go('${Routes.playlistsPage}/${playlist.id}');
                        },
                      );
                    },
                    child: Container(
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      alignment: Alignment.centerLeft,
                      child: Text(playlist.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}
