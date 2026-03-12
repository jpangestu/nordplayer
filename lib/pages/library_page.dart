import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:media_kit/media_kit.dart';
import 'package:nordplayer/database/app_database.dart';
import 'package:nordplayer/services/logger.dart';
import 'package:nordplayer/services/player_service.dart';
import 'package:nordplayer/widgets/album_art_stack.dart';
import 'package:nordplayer/widgets/album_art_wall.dart';
import 'package:nordplayer/widgets/context_menu.dart';
import 'package:nordplayer/widgets/music_tile.dart';
import 'package:nordplayer/widgets/nordplayer_app_bar.dart';
import 'package:nordplayer/widgets/shortcuts.dart';
import 'package:nordplayer/widgets/sliver_resizable_table_layout.dart';

class LibraryPage extends ConsumerWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    final libraryAsync = ref.watch(libraryStreamProvider);
    final tableColumns = ref.watch(libraryTableColumnsProvider);
    final selectedIndices = ref.watch(
      selectedTracksIndexProvider('library_page'),
    );

    return Shortcuts(
      shortcuts: <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): const PlaySelectedIntent(),
        SingleActivator(LogicalKeyboardKey.numpadEnter):
            const PlaySelectedIntent(),
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          extendBodyBehindAppBar: true,
          appBar: NordplayerAppBar(),
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                floating: false,
                pinned: true,
                expandedHeight: 220,
                scrolledUnderElevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  title: LayoutBuilder(
                    builder: (context, constraints) {
                      final settings = context
                          .dependOnInheritedWidgetOfExactType<
                            FlexibleSpaceBarSettings
                          >();
                      if (settings == null) return const SizedBox.shrink();
                      final deltaExtent =
                          settings.maxExtent - settings.minExtent;
                      final t =
                          (settings.currentExtent - settings.minExtent) /
                          deltaExtent;
                      final clampT = t.clamp(0.0, 1.0);
                      final double horizontalOffset = 141 * clampT;

                      return Padding(
                        padding: EdgeInsets.only(
                          left: horizontalOffset,
                          bottom: 60 * clampT,
                        ),
                        child: Text(
                          'Library',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      );
                    },
                  ),
                  background: LibraryHeroHeader(),
                ),
              ),

              libraryAsync.when(
                loading: () => const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, stack) => SliverFillRemaining(
                  child: Center(child: Text('Error: $error')),
                ),
                data: (tracks) {
                  if (tracks.isEmpty) {
                    return SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Your library is empty",
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Scan your local folders to set up your music library.",
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            FilledButton.icon(
                              onPressed: () {
                                context.go('/settings/library-management');
                              },
                              icon: const Icon(Icons.create_new_folder),
                              label: const Text("Add Music Folders"),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return Actions(
                    actions: <Type, Action<Intent>>{
                      PlaySelectedIntent: PlaySelectedAction(
                        ref,
                        tracks,
                        'library_page',
                      ),
                    },
                    child: SliverInteractiveTable<TrackWithArtists>(
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
                            // Wrap our custom reactive widget inside the context menu
                            ContextMenuCustomWidget(
                              child: const ColumnToggleContextMenu(),
                            ),
                          ],
                        );
                      },
                      onRowClick: (index, {required isCtrl, required isShift}) {
                        ref
                            .read(
                              selectedTracksIndexProvider(
                                'library_page',
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
                            .setPlaylist(tracks, index);
                      },
                      onRowRightClick: (index, globalPosition) {
                        final selectionNotifier = ref.read(
                          selectedTracksIndexProvider('library_page').notifier,
                        );
                        final currentSelection = ref.read(
                          selectedTracksIndexProvider('library_page'),
                        );

                        // If right-clicking an unselected item, select it first and clear others
                        if (!currentSelection.contains(index)) {
                          selectionNotifier.selectTrack(
                            index,
                            isCtrlSelect: false,
                            isShiftSelect: false,
                          );
                        }

                        final updatedSelection = ref.read(
                          selectedTracksIndexProvider('library_page'),
                        );

                        // Convert to list and sort the indices first
                        final sortedIndices = updatedSelection.toList()..sort();
                        final List<TrackWithArtists> selectedTracks =
                            sortedIndices.map((i) => tracks[i]).toList();

                        TrackContextMenu.show(
                          context: context,
                          ref: ref,
                          globalPosition: globalPosition,
                          allTracks: tracks,
                          clickedIndex: index,
                          selectedTracks: selectedTracks,
                        );
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LibraryHeroHeader extends ConsumerWidget {
  const LibraryHeroHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final wallCovers = ref.watch(libraryWallCoversProvider);
    final stackCovers = ref.watch(stackCoversProvider).value ?? [];
    final displayStackCovers = stackCovers.isEmpty
        ? wallCovers.take(5).toList()
        : stackCovers;

    final libraryTracks = ref.watch(libraryStreamProvider).value ?? [];
    final int totalMs = libraryTracks.fold(
      0,
      (sum, track) => sum + track.track.durationMs,
    );

    final Duration totalDuration = Duration(milliseconds: totalMs);

    String formatTotalDuration(Duration d) {
      final hours = d.inHours;
      final minutes = d.inMinutes % 60;

      if (hours > 0) {
        return '$hours hr $minutes min';
      } else {
        return '$minutes min';
      }
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        AlbumArtWall(imageUrls: wallCovers),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                theme.colorScheme.primary.withValues(alpha: 0.10),
                theme.colorScheme.primary.withValues(alpha: 0.0),
              ],
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 60),
                child: SizedBox(
                  width: 244,
                  child: Align(
                    alignment: .centerLeft,
                    child: AlbumArtStack(
                      imageUrls: displayStackCovers,
                      size: 180,
                      sliceWidth: 16,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 24, top: 100, right: 16),
                child: Text(
                  '${libraryTracks.length} Tracks - ${formatTotalDuration(totalDuration)}',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Context menu for the table header right click
class ColumnToggleContextMenu extends ConsumerWidget {
  const ColumnToggleContextMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the columns so the checkboxes visually update instantly
    final columns = ref.watch(libraryTableColumnsProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: columns.map((col) {
        return InkWell(
          onTap: () {
            // Toggle the state.
            ref.read(libraryTableColumnsProvider.notifier).toggleColumn(col.id);
          },
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(
                  col.isVisible
                      ? Icons.check_box
                      : Icons.check_box_outline_blank,
                  size: 18,
                ),
                const SizedBox(width: 12),
                Text(col.label, style: const TextStyle(fontSize: 14)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class TrackContextMenu {
  /// Shows the standard right-click menu for music tracks.
  static void show({
    required BuildContext context,
    required WidgetRef ref,
    required Offset globalPosition,
    required List<TrackWithArtists> allTracks,
    required int clickedIndex,
    required List<TrackWithArtists> selectedTracks,
  }) {
    ContextMenu.show(
      context: context,
      globalPosition: globalPosition,
      actionMenus: [
        ContextMenuActions(
          icon: Icons.play_circle,
          label: selectedTracks.length == 1 ? 'Play' : 'Play as playlist',
          shortcut: '⏎',
          onTap: () {
            if (selectedTracks.length == 1) {
              ref
                  .read(playerServiceProvider)
                  .setPlaylist(allTracks, clickedIndex);
            } else {
              // Keep the playlist perfectly sorted by library index
              final playlistToPlay = selectedTracks;

              // Find where the right-clicked track lives inside this sorted list
              final startingQueueIndex = playlistToPlay.indexWhere(
                (t) =>
                    t.track.filePath == allTracks[clickedIndex].track.filePath,
              );

              // Pass the sorted list, but tell the player to start at the clicked track
              ref
                  .read(playerServiceProvider)
                  .setPlaylist(
                    playlistToPlay,
                    startingQueueIndex == -1 ? 0 : startingQueueIndex,
                  );
            }
          },
        ),
        ContextMenuActions(
          icon: Icons.playlist_add_outlined,
          label: 'Add to queue',
          onTap: () {
            ref.read(playerServiceProvider).addToQueue(selectedTracks);

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Added ${selectedTracks.length} tracks to queue',
                  ),
                  behavior: SnackBarBehavior.floating,
                  width: 300,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              );
            }
          },
        ),
        ContextSubMenuAction(
          icon: Icons.add,
          label: 'Add to playlist',
          children: [
            ContextMenuCustomWidget(
              child: SearchablePlaylistContextSubMenu(
                tracksToAdd: selectedTracks,
              ),
            ),
          ],
        ),
        ContextMenuDivider(),
        ContextMenuActions(
          icon: Icons.description_outlined,
          label: 'Edit Metadata',
          onTap: () {}, // TODO: Add Metadata context menu
        ),
        ContextMenuActions(
          icon: Icons.folder_outlined,
          label: 'Show in folder',
          onTap: () async {
            final path = allTracks[clickedIndex].track.filePath;
            await showInFolder(path);
          },
        ),
      ],
    );
  }
}

/// Context sub-menu for add to playlist table row context menu
class SearchablePlaylistContextSubMenu extends ConsumerStatefulWidget {
  final List<TrackWithArtists> tracksToAdd;

  const SearchablePlaylistContextSubMenu({
    super.key,
    required this.tracksToAdd,
  });

  @override
  ConsumerState<SearchablePlaylistContextSubMenu> createState() =>
      _SearchablePlaylistMenuState();
}

class _SearchablePlaylistMenuState
    extends ConsumerState<SearchablePlaylistContextSubMenu> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final playlistsWithDetails = ref.watch(playlistsStreamProvider);

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
                prefixIcon: const Icon(Icons.search, size: 16),
                contentPadding: EdgeInsets.zero,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
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
              builder: (context) => CreatePlaylistDialog(
                database: ref.read(appDatabaseProvider),
                tracksToAdd: widget.tracksToAdd,
              ),
            );
          },
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const Icon(Icons.add, size: 20),
                const SizedBox(width: 12),
                const Text(
                  'New playlist',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),

        Divider(
          height: 9,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
        ),

        // -- PLAYLIST LISTS --
        playlistsWithDetails.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, st) => const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Error loading playlists'),
          ),
          data: (playlistsWithDetailsData) {
            final filtered = playlistsWithDetailsData
                .where(
                  (p) => p.playlist.name.toLowerCase().contains(
                    _query.toLowerCase(),
                  ),
                )
                .toList();

            if (filtered.isEmpty) {
              return Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'No playlists found.',
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
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
                      final trackIds = widget.tracksToAdd
                          .map((t) => t.track.id)
                          .toList();
                      await db.addTracksToPlaylist(playlist.id, trackIds);

                      ContextMenu.closeAll();

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Added to ${playlist.name}')),
                        );
                      }
                    },
                    child: Container(
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      alignment: Alignment.centerLeft,
                      child: Text(
                        playlist.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
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

  const CreatePlaylistDialog({
    super.key,
    required this.database,
    this.tracksToAdd = const [],
  });

  @override
  ConsumerState<CreatePlaylistDialog> createState() =>
      _CreatePlaylistDialogState();
}

class _CreatePlaylistDialogState extends ConsumerState<CreatePlaylistDialog>
    with LoggerMixin {
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

    final newPlaylistId = await widget.database.addPlaylist(
      PlaylistsCompanion.insert(name: name),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$name created successfully')));

    log.i('$name created successfully');

    if (widget.tracksToAdd.isNotEmpty) {
      final db = ref.read(appDatabaseProvider);
      final trackIds = widget.tracksToAdd.map((t) => t.track.id).toList();

      await db.addTracksToPlaylist(newPlaylistId, trackIds);

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Added to $name')));
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create New Playlist'),
      content: TextField(
        controller: _textController,
        autofocus: true,
        decoration: const InputDecoration(
          hintText: 'Playlist Name',
          border: OutlineInputBorder(),
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Create')),
      ],
    );
  }
}

// TODO: Fix cannot open certain path with weird characters (' ` ;, etc)
Future<void> showInFolder(String filePath) async {
  final file = File(filePath);
  if (!await file.exists()) {
    debugPrint("File does not exist: $filePath");
    return;
  }

  if (Platform.isLinux) {
    try {
      await Process.run('dbus-send', [
        '--session',
        '--dest=org.freedesktop.FileManager1',
        '--type=method_call',
        '/org/freedesktop/FileManager1',
        'org.freedesktop.FileManager1.ShowItems',
        'array:string:file://$filePath', // file:// + raw path
        'string:',
      ]);
    } catch (e) {
      // Fallback: If DBus fails, just open the parent directory
      final folderPath = file.parent.path;
      await Process.run('xdg-open', [folderPath]);
    }
  } else if (Platform.isWindows) {
    await Process.run('explorer.exe', ['/select,', filePath]);
  } else if (Platform.isMacOS) {
    await Process.run('open', ['-R', filePath]);
  }
}

// ================================ Provider ==================================

final libraryWallCoversProvider = Provider<List<String>>((ref) {
  final libraryAsync = ref.watch(libraryStreamProvider);
  final libraryTracks = libraryAsync.value ?? [];

  if (libraryTracks.isEmpty) return [];

  final List<String> wallCovers = [];
  final Set<String> seenWallCovers = {};

  final randomLibrary = [...libraryTracks]..shuffle();

  for (final track in randomLibrary) {
    final artPath = track.album.albumArtPath;
    if (artPath != null &&
        artPath.isNotEmpty &&
        !seenWallCovers.contains(artPath)) {
      seenWallCovers.add(artPath);
      wallCovers.add(artPath);
    }
    if (wallCovers.length >= 30) break;
  }

  return wallCovers;
});

final stackCoversProvider = StreamProvider<List<String>>((ref) {
  final player = ref.watch(playerServiceProvider).mkPlayer;

  return player.stream.playlist.map((playlist) {
    if (playlist.medias.isEmpty || playlist.index < 0) {
      return [];
    }

    final int currentIndex = playlist.index;
    final List<Media> allMedia = playlist.medias;
    final PlaylistMode loopMode = player.state.playlistMode;

    final List<String> stackCovers = [];

    for (
      int count = 0;
      count < allMedia.length && stackCovers.length < 5;
      count++
    ) {
      int targetIndex = currentIndex + count;

      if (targetIndex >= allMedia.length) {
        if (loopMode == PlaylistMode.loop) {
          targetIndex = targetIndex % allMedia.length;
        } else {
          break;
        }
      }

      final track = allMedia[targetIndex].extras?['data'] as TrackWithArtists?;
      if (track != null) {
        // If there is no art, pass an empty string "" as a placeholder flag
        final artPath = track.album.albumArtPath?.isNotEmpty == true
            ? track.album.albumArtPath!
            : "";

        stackCovers.add(artPath);
      }
    }

    return stackCovers;
  });
});

final libraryTableColumnsProvider =
    NotifierProvider<
      LibraryTableColumnsNotifier,
      List<TableColumn<TrackWithArtists>>
    >(LibraryTableColumnsNotifier.new);

class LibraryTableColumnsNotifier
    extends Notifier<List<TableColumn<TrackWithArtists>>> {
  @override
  List<TableColumn<TrackWithArtists>> build() {
    return [
      TableColumn<TrackWithArtists>(
        id: 'index',
        label: "#",
        width: 60,
        minWidth: 60,
        alignment: Alignment.centerRight,
        cellBuilder: (context, track, index) {
          return Consumer(
            builder: (context, ref, child) {
              final isPlaying =
                  ref.watch(currentTrackProvider).value?.track.filePath ==
                  track.track.filePath;
              if (isPlaying) {
                return Icon(
                  Icons.volume_up,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                );
              }
              return Text(
                "${index + 1}",
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                ),
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
              final isPlaying =
                  ref.watch(currentTrackProvider).value?.track.filePath ==
                  track.track.filePath;
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
          return Text(
            track.album.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          );
        },
      ),
      TableColumn<TrackWithArtists>(
        id: 'path',
        label: 'Path',
        flex: 3,
        minWidth: 100,
        isVisible: false,
        cellBuilder: (context, track, index) {
          return Text(
            track.track.filePath,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          );
        },
      ),
      TableColumn<TrackWithArtists>(
        id: 'duration',
        label: 'Duration',
        width: 100,
        minWidth: 90,
        alignment: Alignment.centerRight,
        cellBuilder: (context, track, index) {
          final duration = Duration(milliseconds: track.track.durationMs);
          final minutes = duration.inMinutes;
          final seconds = duration.inSeconds % 60;
          return Text('$minutes:${seconds.toString().padLeft(2, '0')}');
        },
      ),
    ];
  }

  /// Toggles the visibility of a column by its ID.
  void toggleColumn(String id) {
    state = [
      for (final col in state)
        if (col.id == id) col.copyWith(isVisible: !col.isVisible) else col,
    ];
  }

  void updateColumnWidths(List<double> newWidths) {
    int visibleIndex = 0;
    double currentVisibleFlexTotal = 0;
    double totalNewFlexibleWidth = 0;

    // Calculate the total flex pool and total pixel width of the currently visible flexible columns
    for (final col in state) {
      if (!col.isVisible) continue;

      final newWidth = newWidths[visibleIndex];
      visibleIndex++;

      if (col.flex != null) {
        currentVisibleFlexTotal += col.flex!;
        totalNewFlexibleWidth += newWidth;
      }
    }

    // Safety check to prevent division by zero
    if (totalNewFlexibleWidth <= 0) totalNewFlexibleWidth = 1;

    // Reset index for the mapping phase
    visibleIndex = 0;

    state = state.map((col) {
      if (!col.isVisible) return col;

      final newWidth = newWidths[visibleIndex];
      visibleIndex++;

      if (col.width != null) {
        // Fixed-width columns just take the exact new pixel width
        return col.copyWith(width: newWidth);
      } else {
        // Normalize the flex!
        // This converts the raw pixels back into the original single-digit scale.
        double normalizedFlex =
            (newWidth / totalNewFlexibleWidth) * currentVisibleFlexTotal;
        return col.copyWith(flex: normalizedFlex);
      }
    }).toList();
  }
}

final selectedTracksIndexProvider =
    NotifierProvider.family<SelectedTracksIndex, Set<int>, String>(
      SelectedTracksIndex.new,
    );

class SelectedTracksIndex extends Notifier<Set<int>> {
  SelectedTracksIndex(this.tableId);

  final String tableId;
  int? _anchorIndex;

  @override
  Set<int> build() => {};

  void selectTrack(
    int index, {
    required bool isCtrlSelect,
    required bool isShiftSelect,
  }) {
    if (isShiftSelect) {
      final start = _anchorIndex ?? index;
      final minIdx = start < index ? start : index;
      final maxIdx = start > index ? start : index;
      final range = <int>{for (var i = minIdx; i <= maxIdx; i++) i};

      if (isCtrlSelect) {
        state = {...state, ...range};
      } else {
        state = range;
      }
    } else if (isCtrlSelect) {
      _anchorIndex = index;
      if (state.contains(index)) {
        state = {...state}..remove(index);
      } else {
        state = {...state, index};
      }
    } else {
      _anchorIndex = index;
      state = {index};
    }
  }
}
