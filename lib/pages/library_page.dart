import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:media_kit/media_kit.dart';
import 'package:nordplayer/database/app_database.dart';
import 'package:nordplayer/pages/playlists_page.dart';
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

    return Shortcuts(
      shortcuts: <ShortcutActivator, Intent>{
        LogicalKeySet(LogicalKeyboardKey.enter): const PlaySelectedIntent(),
        LogicalKeySet(LogicalKeyboardKey.numpadEnter): const PlaySelectedIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{PlaySelectedIntent: PlaySelectedAction(ref)},
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

                    return SliverResizableTableLayout(
                      columns: const [
                        TableColumn(
                          label: "#",
                          width: 60,
                          minWidth: 60,
                          alignment: Alignment.centerRight,
                        ),
                        TableColumn(label: "Title", flex: 5, minWidth: 200),
                        TableColumn(label: "Album", flex: 3, minWidth: 120),
                        TableColumn(
                          label: 'Duration',
                          width: 100,
                          minWidth: 90,
                          alignment: Alignment.centerRight,
                        ),
                      ],
                      itemCount: tracks.length,
                      rowBuilder: (context, index, widths, cellPadding) {
                        return _LibraryTrackRow(
                          tracks: tracks,
                          index: index,
                          widths: widths,
                          cellPadding: cellPadding,
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LibraryTrackRow extends ConsumerStatefulWidget {
  final List<TrackWithArtists> tracks;
  final int index;
  final List<double> widths;
  final EdgeInsets cellPadding;

  const _LibraryTrackRow({
    required this.tracks,
    required this.index,
    required this.widths,
    required this.cellPadding,
  });

  @override
  ConsumerState<_LibraryTrackRow> createState() => _LibraryTrackRowState();
}

class _LibraryTrackRowState extends ConsumerState<_LibraryTrackRow>
    with LoggerMixin {
  late final TapGestureRecognizer _albumTapRecognizer;
  bool _rowHovered = false;
  bool _albumHovered = false;

  @override
  void initState() {
    super.initState();
    _albumTapRecognizer = TapGestureRecognizer();
  }

  @override
  void dispose() {
    _albumTapRecognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textScaler = MediaQuery.textScalerOf(context);
    final double tileHeight = MusicTile.tileHeight(textScaler);
    final theme = Theme.of(context);
    final subtitleStyle =
        theme.listTileTheme.subtitleTextStyle ?? theme.textTheme.bodyMedium!;

    final currentTrack = ref.watch(currentTrackProvider).value;
    final thisTrack = widget.tracks[widget.index];
    final thisTrackArtists = thisTrack.artists.map((a) => a.name).toList();
    final bool thisTrackSelected = ref.watch(
      selectedTracksIndexProvider.select((set) => set.contains(widget.index)),
    );
    final bool thisTrackPlayed =
        currentTrack?.track.filePath == thisTrack.track.filePath;

    final duration = Duration(milliseconds: thisTrack.track.durationMs);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;

    return MouseRegion(
      onEnter: (_) => setState(() => _rowHovered = true),
      onExit: (_) => setState(() => _rowHovered = false),
      child: Listener(
        onPointerDown: (event) {
          final isCtrlSelect =
              HardwareKeyboard.instance.isControlPressed ||
              HardwareKeyboard.instance.isMetaPressed;
          final isShiftSelect = HardwareKeyboard.instance.isShiftPressed;

          // Left click
          if (event.buttons == kPrimaryMouseButton) {
            // _closeContextMenu();

            ref
                .read(selectedTracksIndexProvider.notifier)
                .selectTrack(
                  widget.index,
                  isCtrlSelect: isCtrlSelect,
                  isShiftSelect: isShiftSelect,
                );
          }
          // Right click
          else if (event.buttons == kSecondaryMouseButton) {
            final currentSelection = ref.read(selectedTracksIndexProvider);

            // Only alter selection if right-clicking an unselected track
            if (!currentSelection.contains(widget.index)) {
              ref
                  .read(selectedTracksIndexProvider.notifier)
                  .selectTrack(
                    widget.index,
                    isCtrlSelect: isCtrlSelect,
                    isShiftSelect: isShiftSelect,
                  );
            }

            final currentTracks = ref.read(selectedTracksProvider);

            ContextMenu.show(
              context: context,
              globalPosition: event.position,
              actionMenus: [
                ContextMenuActions(
                  icon: Icons.play_circle,
                  label: ref.read(selectedTracksIndexProvider).length == 1
                      ? 'Play'
                      : 'Play as playlist',
                  shortcut: '⏎',
                  onTap: () {
                    if (currentTracks.length == 1) {
                      ref
                          .read(playerServiceProvider)
                          .setPlaylist(widget.tracks, widget.index);
                    } else {
                      final List<TrackWithArtists> reorderedPlaylist = [];
                      final clickedTrack = widget.tracks[widget.index];

                      // Put the clicked track at index 0
                      reorderedPlaylist.add(clickedTrack);

                      // Add all other selected tracks EXCEPT the one we just added
                      reorderedPlaylist.addAll(
                        currentTracks.where(
                          (t) =>
                              t.track.filePath != clickedTrack.track.filePath,
                        ),
                      );

                      ref
                          .read(playerServiceProvider)
                          .setPlaylist(reorderedPlaylist, 0);
                    }
                  },
                ),
                ContextMenuActions(
                  icon: Icons.playlist_add_outlined,
                  label: 'Add to queue',
                  onTap: _addToQueue,
                ),
                ContextSubMenuAction(
                  icon: Icons.add,
                  label: 'Add to playlist',
                  children: [
                    ContextMenuCustomWidget(
                      child: SearchablePlaylistMenu(
                        tracksToAdd: currentTracks.isEmpty
                            ? [widget.tracks[widget.index]]
                            : currentTracks,
                      ),
                    ),
                  ],
                ),
                ContextMenuDivider(),
                ContextMenuActions(
                  icon: Icons.description_outlined,
                  label: 'Edit Medata',
                  onTap: () {},
                ),
                ContextMenuActions(
                  icon: Icons.folder_outlined,
                  label: 'Show in folder',
                  onTap: () async {
                    final path = widget.tracks[widget.index].track.filePath;
                    await showInFolder(path);
                  },
                ),
                ContextMenuActions(
                  icon: Icons.info_outline,
                  label: 'Show details',
                  onTap: () {},
                ),
              ],
            );
          }
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onDoubleTapDown: (details) {
            // _closeContextMenu();
            ref
                .read(playerServiceProvider)
                .setPlaylist(widget.tracks, widget.index);
          },
          child: Container(
            height: tileHeight,
            decoration: BoxDecoration(
              borderRadius: .circular(6),
              color: _rowHovered
                  ? theme.colorScheme.primary.withValues(alpha: 0.1)
                  : Colors.transparent,
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: .circular(6),
                color: thisTrackSelected
                    ? theme.colorScheme.primary.withValues(alpha: 0.1)
                    : Colors.transparent,
              ),
              child: Row(
                children: [
                  // COLUMN 1: Index OR Play Button
                  SizedBox(
                    width: widget.widths[0],
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => ref
                            .read(playerServiceProvider)
                            .setPlaylist(widget.tracks, widget.index),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding: widget.cellPadding,
                            child: _rowHovered
                                ? thisTrackPlayed && ref.read(isPlayingProvider)
                                      ? const Icon(Icons.pause, size: 20)
                                      : const Icon(Icons.play_arrow, size: 20)
                                : Text(
                                    "${widget.index + 1}",
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // COLUMN 2: Title & Artist
                  SizedBox(
                    width: widget.widths[1],
                    child: MusicTile(
                      selected: thisTrackPlayed,
                      albumArtPath: thisTrack.album.albumArtPath,
                      title: thisTrack.track.title,
                      artists: thisTrackArtists,
                      padding: widget.cellPadding,
                    ),
                  ),

                  // COLUMN 3: Album
                  SizedBox(
                    width: widget.widths[2],
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16.0),
                      child: RichText(
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        text: TextSpan(
                          text: thisTrack.album.title,
                          recognizer: _albumTapRecognizer
                            ..onTap = () {
                              log.d(
                                'Navigate to album: ${thisTrack.album.title} (from "${thisTrack.track.title}")',
                              );
                            },
                          onEnter: (_) => setState(() => _albumHovered = true),
                          onExit: (_) => setState(() => _albumHovered = false),
                          style: subtitleStyle.copyWith(
                            decoration: _albumHovered
                                ? TextDecoration.underline
                                : TextDecoration.none,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // COLUMN 4: Duration
                  SizedBox(
                    width: widget.widths[3],
                    child: Padding(
                      padding: widget.cellPadding,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          '$minutes:${seconds.toString().padLeft(2, '0')}',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _addToQueue() async {
    final currentTrack = ref.read(selectedTracksProvider);
    ref.read(playerServiceProvider).addToQueue(currentTrack);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added ${currentTrack.length} tracks to queue'),
          behavior: SnackBarBehavior.floating,
          width: 300,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
      );
    }
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

class SearchablePlaylistMenu extends ConsumerStatefulWidget {
  final List<TrackWithArtists> tracksToAdd;

  const SearchablePlaylistMenu({super.key, required this.tracksToAdd});

  @override
  ConsumerState<SearchablePlaylistMenu> createState() =>
      _SearchablePlaylistMenuState();
}

class _SearchablePlaylistMenuState
    extends ConsumerState<SearchablePlaylistMenu> {
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
            showCreatePlaylistDialogAndAddTracks(
              context,
              ref.read(appDatabaseProvider),
              widget.tracksToAdd,
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

//
// Provider
//

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

final selectedTracksIndexProvider =
    NotifierProvider<SelectedTracksIndex, Set<int>>(SelectedTracksIndex.new);

class SelectedTracksIndex extends Notifier<Set<int>> {
  // Store the last track that was clicked without shift
  int? _anchorIndex;

  @override
  Set<int> build() {
    return {};
  }

  void selectTrack(
    int index, {
    required bool isCtrlSelect,
    required bool isShiftSelect,
  }) {
    if (isShiftSelect) {
      // Shift click
      final start = _anchorIndex ?? index;

      // Determine direction (up or down the list)
      final minIdx = start < index ? start : index;
      final maxIdx = start > index ? start : index;

      // Generate the contiguous block of indices
      final range = <int>{for (var i = minIdx; i <= maxIdx; i++) i};

      if (isCtrlSelect) {
        // Ctrl + Shift: Add the new block to existing scattered selections
        state = {...state, ...range};
      } else {
        // Pure Shift: Replace the entire selection with just this block
        state = range;
      }
    } else if (isCtrlSelect) {
      // Ctrl/Cmd Click
      _anchorIndex = index;

      if (state.contains(index)) {
        state = {...state}..remove(index);
      } else {
        state = {...state, index};
      }
    } else {
      // Normal left click
      _anchorIndex = index;
      state = {index};
    }
  }
}

final selectedTracksProvider = Provider<List<TrackWithArtists>>((ref) {
  final selectedIndices = ref.watch(selectedTracksIndexProvider);
  final libraryTracks = ref.watch(libraryStreamProvider).value ?? [];

  if (selectedIndices.isEmpty || libraryTracks.isEmpty) return [];

  final sortedIndices = selectedIndices.toList()..sort();

  return sortedIndices.map((index) => libraryTracks[index]).toList();
});
