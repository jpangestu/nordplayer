import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nordplayer/database/app_database.dart';
import 'package:nordplayer/pages/pages_helper.dart';
import 'package:nordplayer/routes/router.dart';
import 'package:nordplayer/services/logger.dart';
import 'package:nordplayer/services/player_service.dart';
import 'package:nordplayer/services/preference_service.dart';
import 'package:nordplayer/theming/icon-sets/app_icon_set.dart';
import 'package:nordplayer/widgets/app_icon.dart';
import 'package:nordplayer/widgets/context_menu.dart';
import 'package:nordplayer/widgets/nord_alert_dialog.dart';
import 'package:nordplayer/widgets/nord_snack_bar.dart';

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
                  .read(playerServiceProvider)
                  .setPlaylist(
                    playbackContextType: playbackContextType,
                    playbackContextId: playbackContextId,
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
                  .read(playerServiceProvider)
                  .setPlaylist(
                    playbackContextType: 'play_as_playlist',
                    playbackContextId: null,
                    tracksToPlay: playlistToPlay,
                    initialIndex: startingQueueIndex == -1 ? 0 : startingQueueIndex,
                  );
            }
          },
        ),
        // TODO: maybe make one context menu for each pages? currently this is also used in queue page
        // Only show "Play Next" if we aren't already looking at the queue
        if (playbackContextType != 'queue')
          ContextMenuActions(
            icon: appIconSet.playNext,
            label: 'Play Next',
            onTap: () {
              final playbackContext = ref.read(playbackContextProvider);
              ref
                  .read(playerServiceProvider)
                  .playNext(selectedTracks, playbackContext?.type ?? 'all_tracks', playbackContext?.id);

              if (context.mounted) {
                final showQueue = ref.read(preferenceServiceProvider).showQueue;

                showQueue
                    ? showNordSnackBar(
                        context: context,
                        message: 'Added ${selectedTracks.length} track(s) to queue',
                        type: .general,
                      )
                    : showNordSnackBar(
                        context: context,
                        message: 'Added ${selectedTracks.length} track(s) to queue',
                        type: .general,
                        actionLabel: 'View Queue',
                        onAction: (snackBarContext) {
                          ref.read(preferenceServiceProvider.notifier).setShowQueue(true);
                        },
                      );
              }
            },
          ),

        // Only show "Add to queue" if we aren't already looking at the queue
        if (playbackContextType != 'queue')
          ContextMenuActions(
            icon: appIconSet.addToQueue,
            label: 'Add to queue',
            onTap: () {
              final playbackContext = ref.read(playbackContextProvider);
              ref
                  .read(playerServiceProvider)
                  .addToQueue(selectedTracks, playbackContext?.type ?? 'all_tracks', playbackContext?.id);

              if (context.mounted) {
                final showQueue = ref.read(preferenceServiceProvider).showQueue;

                showQueue
                    ? showNordSnackBar(
                        context: context,
                        message: 'Added ${selectedTracks.length} track(s) to queue',
                        type: .general,
                      )
                    : showNordSnackBar(
                        context: context,
                        message: 'Added ${selectedTracks.length} track(s) to queue',
                        type: .general,
                        actionLabel: 'View Queue',
                        onAction: (snackBarContext) {
                          ref.read(preferenceServiceProvider.notifier).setShowQueue(true);
                        },
                      );
              }
            },
          ),

        // Show "Remove from queue" if we ARE looking at the queue
        if (playbackContextType == 'queue')
          ContextMenuActions(
            icon: appIconSet.removeFromQueue,
            label: 'Remove from queue',
            onTap: () {
              final selectionSet = ref.read(selectedTracksIndexProvider('queue_page'));

              // Convert to list and sort descending for safe remove
              final indicesToRemove = selectionSet.toList()..sort((a, b) => b.compareTo(a));

              // Remove from highest index to lowest so the queue shifting doesn't break the math
              for (final index in indicesToRemove) {
                ref.read(playerServiceProvider).removeTrack(index);
              }

              // Clear the selection so the UI doesn't hold onto invalid, out-of-bounds highlighted rows
              ref.read(selectedTracksIndexProvider('queue_page').notifier).clear();
            },
          ),
        ContextSubMenuAction(
          icon: appIconSet.add,
          label: 'Add to playlist',
          children: [ContextMenuCustomWidget(child: SearchablePlaylistContextSubMenu(tracksToAdd: selectedTracks))],
        ),
        ContextMenuDivider(),
        // ContextMenuActions(
        //   icon: appIconSet.showMetadata,
        //   label: 'Show Metadata',
        //   onTap: () {
        //     unimplemented(context);
        //   }, // TODO: Add Metadata context menu
        // ),
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
  }) {
    final appIconSet = ref.read(appIconProvider);

    ContextMenu.show(
      isAdaptive: isAdaptive,
      context: context,
      globalPosition: globalPosition,
      actionMenus: [
        ContextMenuActions(
          icon: Icons.play_circle,
          label: 'Play',
          onTap: () {
            ref
                .read(playerServiceProvider)
                .setPlaylist(
                  playbackContextType: playbackContextType,
                  playbackContextId: playbackContextId,
                  tracksToPlay: tracks,
                  initialIndex: indexToPlay,
                );
          },
        ),

        ContextMenuActions(
          icon: LucideIcons.listStart,
          label: 'Play Next',
          onTap: () {
            ref.read(playerServiceProvider).playNext([tracks[indexToPlay]], playbackContextType, playbackContextId);

            if (context.mounted) {
              final showQueue = ref.read(preferenceServiceProvider).showQueue;

              showQueue
                  ? showNordSnackBar(context: context, message: 'Added 1 track to queue', type: .general)
                  : showNordSnackBar(
                      context: context,
                      message: 'Added 1 track to queue',
                      type: .general,
                      actionLabel: 'View Queue',
                      onAction: (snackBarContext) {
                        ref.read(preferenceServiceProvider.notifier).setShowQueue(true);
                      },
                    );
            }
          },
        ),

        ContextMenuActions(
          icon: appIconSet.addToQueue,
          label: 'Add to queue',
          onTap: () {
            ref.read(playerServiceProvider).addToQueue([tracks[indexToPlay]], playbackContextType, playbackContextId);

            if (context.mounted) {
              final showQueue = ref.read(preferenceServiceProvider).showQueue;

              showQueue
                  ? showNordSnackBar(context: context, message: 'Added 1 track to queue', type: .general)
                  : showNordSnackBar(
                      context: context,
                      message: 'Added 1 track to queue',
                      type: .general,
                      actionLabel: 'View Queue',
                      onAction: (snackBarContext) {
                        ref.read(preferenceServiceProvider.notifier).setShowQueue(true);
                      },
                    );
            }
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

            await showDialog(
              context: context,
              builder: (context) =>
                  CreatePlaylistDialog(database: ref.read(appDatabaseProvider), tracksToAdd: widget.tracksToAdd),
            );
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
                      // ADD TO DATABASE
                      final db = ref.read(appDatabaseProvider);
                      final trackIds = widget.tracksToAdd.map((t) => t.track.id).toList();
                      await db.addTracksToPlaylist(playlist.id, trackIds);

                      ContextMenu.closeAll();

                      if (context.mounted) {
                        showNordSnackBar(
                          context: context,
                          message: 'Added to ${playlist.name}',
                          type: .general,
                          actionLabel: 'View',
                          onAction: (snackBarContext) {
                            snackBarContext.go('${Routes.playlistsPage}/${playlist.id}');
                          },
                        );
                      }
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

class CreatePlaylistDialog extends ConsumerStatefulWidget {
  final AppDatabase database;
  final List<TrackWithArtists> tracksToAdd;

  const CreatePlaylistDialog({super.key, required this.database, this.tracksToAdd = const []});

  @override
  ConsumerState<CreatePlaylistDialog> createState() => _CreatePlaylistDialogState();
}

class _CreatePlaylistDialogState extends ConsumerState<CreatePlaylistDialog> with LoggerMixin {
  late final TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _submit() async {
    final name = _textController.text.trim();

    if (name.isEmpty) {
      Navigator.pop(context);
      return;
    }

    final newPlaylistId = await widget.database.addPlaylist(PlaylistsCompanion.insert(name: name));

    if (!mounted) return;

    log.i('$name created successfully');

    if (widget.tracksToAdd.isNotEmpty) {
      final db = ref.read(appDatabaseProvider);
      final trackIds = widget.tracksToAdd.map((t) => t.track.id).toList();

      await db.addTracksToPlaylist(newPlaylistId, trackIds);

      if (!mounted) return;
      showNordSnackBar(
        context: context,
        message: 'Created "$name" with ${trackIds.length} tracks',
        type: .success,
        actionLabel: 'Open Playlist',
        onAction: (snackBarContext) {
          snackBarContext.go('${Routes.playlistsPage}/$newPlaylistId');
        },
      );
    } else {
      showNordSnackBar(
        context: context,
        message: 'Playlist "$name" created',
        type: .success,
        actionLabel: 'Open',
        onAction: (snackBarContext) {
          snackBarContext.go('${Routes.playlistsPage}/$newPlaylistId');
        },
      );
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return NordAlertDialog(
      title: 'Create New Playlist',
      content: TextField(
        controller: _textController,
        autofocus: true,
        decoration: const InputDecoration(hintText: 'Playlist Name', border: OutlineInputBorder()),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: _submit, child: const Text('Create')),
      ],
    );
  }
}
