import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nordplayer/database/app_database.dart';
import 'package:nordplayer/routes/routes.dart';
import 'package:nordplayer/services/config_service.dart';
import 'package:nordplayer/services/logger.dart';
import 'package:nordplayer/services/player_service.dart';
import 'package:nordplayer/widgets/album_art_stack.dart';
import 'package:nordplayer/widgets/animated_equalizer_icon.dart';
import 'package:nordplayer/widgets/context_menu.dart';

class PlaylistsPage extends ConsumerWidget {
  const PlaylistsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final db = ref.watch(appDatabaseProvider);
    final appConfig = ref.watch(configServiceProvider).requireValue;

    return Scaffold(
      backgroundColor: appConfig.adaptiveBg
          ? theme.colorScheme.surfaceContainer.withValues(alpha: 0.5)
          : theme.colorScheme.surface,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- HEADER SECTION ---
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 32, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Your Playlists',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                OutlinedButton.icon(
                  onPressed: () => showCreatePlaylistDialog(context, db),
                  icon: const Icon(Icons.add),
                  label: const Text('New Playlist'),
                ),
              ],
            ),
          ),

          // --- GRID SECTION ---
          Expanded(
            child: StreamBuilder<List<PlaylistWithDetails>>(
              stream: db.watchAllPlaylists(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final playlistsWithCount = snapshot.data ?? [];

                if (playlistsWithCount.isEmpty) {
                  return const Center(
                    child: Text('No playlists yet. Create one to get started!'),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 220, // Max width of each card
                    childAspectRatio:
                        0.91, // To match album art stack with 10 slice width
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: playlistsWithCount.length,
                  itemBuilder: (context, index) {
                    return PlaylistCard(
                      playlistWithDetails: playlistsWithCount[index],
                      database: db,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> showCreatePlaylistDialog(
  BuildContext context,
  AppDatabase db,
) async {
  await showDialog(
    context: context,
    builder: (context) => CreatePlaylistDialog(database: db),
  );
}

Future<void> showCreatePlaylistDialogAndAddTracks(
  BuildContext context,
  AppDatabase db,
  List<TrackWithArtists> tracksToAdd,
) async {
  await showDialog(
    context: context,
    builder: (context) =>
        CreatePlaylistDialog(database: db, tracksToAdd: tracksToAdd),
  );
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

class RenamePlaylistDialog extends ConsumerStatefulWidget {
  final AppDatabase database;
  final PlaylistData playlist;

  const RenamePlaylistDialog({
    super.key,
    required this.database,
    required this.playlist,
  });

  @override
  ConsumerState<RenamePlaylistDialog> createState() =>
      _RenamePlaylistDialogState();
}

class _RenamePlaylistDialogState extends ConsumerState<RenamePlaylistDialog> {
  late final TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    // Pre-fill the text field with the current name
    _textController = TextEditingController(text: widget.playlist.name);
    // Automatically select/highlight all text so the user can just start typing
    _textController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: widget.playlist.name.length,
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _submit() async {
    final newName = _textController.text.trim();

    if (newName.isEmpty || newName == widget.playlist.name) {
      Navigator.pop(context);
      return;
    }

    await widget.database.renamePlaylist(widget.playlist.id, newName);

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Renamed to "$newName"')));

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Rename Playlist'),
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
        FilledButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }
}

// ==========================================
// INDIVIDUAL PLAYLIST CARD (WITH HOVER STATE)
// ==========================================

class PlaylistCard extends ConsumerStatefulWidget {
  final PlaylistWithDetails playlistWithDetails;
  final AppDatabase database;

  const PlaylistCard({
    super.key,
    required this.playlistWithDetails,
    required this.database,
  });

  @override
  ConsumerState<PlaylistCard> createState() => _PlaylistCardState();
}

class _PlaylistCardState extends ConsumerState<PlaylistCard> with LoggerMixin {
  bool _isHovered = false;
  final GlobalKey _moreButtonKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalTracks = widget.playlistWithDetails.trackCount;
    final playlistId = widget.playlistWithDetails.playlist.id;

    // Check if THIS playlist is the active context
    final playbackContext = ref.watch(playbackContextProvider);
    final isPlayingThisPlaylist =
        playbackContext?.isPlaying('playlist', playlistId) ?? false;
    final isAudioPlaying = ref.watch(isPlayingProvider);

    final nowPlayingAlbumArt = ref.watch(current5TracksAlbumArtInQueueProvider);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () {
          final basePath = Routes.playlistsPage;
          final targetId = widget.playlistWithDetails.playlist.id;

          context.push('$basePath/$targetId');
          log.i(
            'Navigate to playlist ${widget.playlistWithDetails.playlist.id}',
          );
        },
        onSecondaryTapDown: (details) {
          _showContextMenu(details.globalPosition, ref);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // -- PLAYLIST CARD --
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // -- CARD BACKGROUND --
                  AlbumArtStack(
                    imageUrls:
                        ref.read(playbackContextProvider)?.id ==
                            widget.playlistWithDetails.playlist.id
                        ? nowPlayingAlbumArt
                        : widget.playlistWithDetails.imageUrls,
                    sliceWidth: 10,
                  ),

                  // -- OPTIONS MENU (RIGHT CLICK ALTERNATIVE) --
                  if (_isHovered)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Material(
                        shape: const CircleBorder(),
                        color: theme.colorScheme.onPrimary.withValues(
                          alpha: 0.5,
                        ),
                        elevation: 4,
                        child: IconButton(
                          key: _moreButtonKey,
                          visualDensity: .compact,
                          icon: Icon(
                            Icons.more_horiz,
                            color: theme.colorScheme.primary,
                            size: 20,
                          ),
                          tooltip: 'Options',
                          hoverColor: theme.colorScheme.primary.withValues(
                            alpha: 0.1,
                          ),
                          focusColor: theme.colorScheme.primary.withValues(
                            alpha: 0.15,
                          ),
                          highlightColor: theme.colorScheme.primary.withValues(
                            alpha: 0.2,
                          ),
                          onPressed: () {
                            final RenderBox renderBox =
                                _moreButtonKey.currentContext!
                                        .findRenderObject()
                                    as RenderBox;

                            final buttonPosition = renderBox.localToGlobal(
                              Offset.zero,
                            );

                            _showContextMenu(buttonPosition, ref);
                          },
                        ),
                      ),
                    ),

                  // -- THE PLAY BUTTON --
                  if (_isHovered)
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Material(
                        color: Theme.of(context).colorScheme.primary,
                        shape: const CircleBorder(),
                        elevation: 4,
                        child: IconButton(
                          icon: Icon(
                            Icons.play_arrow,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                          onPressed: () {
                            _playPlaylist();
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // -- NAME AND TOTAL TRACKS --
            Row(
              children: [
                if (isPlayingThisPlaylist && isAudioPlaying) ...[
                  AnimatedEqualizerIcon(
                    color: theme.colorScheme.primary,
                    size: 16,
                    isPlaying: isAudioPlaying,
                  ),
                  SizedBox(width: 8),
                ],
                Text(
                  widget.playlistWithDetails.playlist.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: isPlayingThisPlaylist
                        ? theme.colorScheme.primary
                        : null,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),

            const SizedBox(height: 4),
            _isHovered
                ? Text(
                    '${totalTracks.toString()} ${totalTracks > 1 ? ' tracks' : ' track'}',
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  )
                : Text(''),
          ],
        ),
      ),
    );
  }

  void _showContextMenu(Offset position, WidgetRef ref) {
    ContextMenu.show(
      context: context,
      globalPosition: position,
      actionMenus: [
        ContextMenuActions(
          icon: Icons.play_circle,
          label: 'Play',
          onTap: _playPlaylist,
        ),
        ContextMenuActions(
          icon: Icons.playlist_add_outlined,
          label: 'Add to queue',
          onTap: _addToQueue,
        ),
        ContextMenuActions(
          icon: Icons.edit_outlined,
          label: 'Rename',
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => RenamePlaylistDialog(
                database: widget.database,
                playlist: widget.playlistWithDetails.playlist,
              ),
            );
          },
        ),
        ContextMenuActions(
          icon: Icons.delete_outline,
          label: 'Delete',
          isDestructive: true,
          onTap: () {
            _confirmDelete(context);
          },
        ),
      ],
    );
  }

  Future<void> _playPlaylist() async {
    final tracks = await widget.database.getPlaylistTracks(
      widget.playlistWithDetails.playlist.id,
    );

    if (tracks.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This playlist is empty! Add some tracks first.'),
          ),
        );
      }
      return;
    }

    ref
        .read(playerServiceProvider)
        .setPlaylist(
          playbackContextType: 'playlist',
          playbackContextId: widget.playlistWithDetails.playlist.id,
          tracksToPlay: tracks,
          initialIndex: 0,
        );
  }

  Future<void> _addToQueue() async {
    final tracks = await widget.database.getPlaylistTracks(
      widget.playlistWithDetails.playlist.id,
    );

    if (tracks.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This playlist is empty! Add some tracks first.'),
          ),
        );
      }
      return;
    }

    final playbackContext = ref.read(playbackContextProvider);
    ref
        .read(playerServiceProvider)
        .addToQueue(tracks, playbackContext?.type ?? '', playbackContext?.id);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added ${tracks.length} tracks to queue'),
          behavior: SnackBarBehavior.floating,
          width: 300,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
      );
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Playlist?'),
        content: Text(
          'Are you sure you want to delete "${widget.playlistWithDetails.playlist.name}"?\nThis cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await widget.database.deletePlaylist(
        widget.playlistWithDetails.playlist.id,
      );
      if (context.mounted) {
        final screenWidth = MediaQuery.of(context).size.width;
        final horizontalMargin = screenWidth > 400
            ? (screenWidth - 300) / 2
            : 24.0;

        // TODO: Create a reusable custom snackbar (shrink wrap text)
        // showed asynchronously and stacked ton top of each other if
        //there's multiple snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Deleted "${widget.playlistWithDetails.playlist.name}"',
              textAlign: TextAlign.center,
            ),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.only(
              bottom: 98.0,
              left: horizontalMargin,
              right: horizontalMargin,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
        );
      }
    }
  }
}
