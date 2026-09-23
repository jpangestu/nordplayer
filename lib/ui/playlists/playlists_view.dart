import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nordplayer/utils/logger.dart';
import 'package:nordplayer/ui/shared/themes/icon_sets/app_icon_set.dart';
import 'package:nordplayer/domain/models/models.dart';
import 'package:nordplayer/ui/playlists/playlists_ui_state.dart';
import 'package:nordplayer/ui/playlists/playlists_viewmodel.dart';
import 'package:nordplayer/ui/playlists/widgets/playlist_dialogs.dart';
import 'package:nordplayer/routing/router.dart';
import 'package:nordplayer/ui/shared/ui/album_art_stack.dart';
import 'package:nordplayer/ui/shared/ui/animated_equalizer_icon.dart';
import 'package:nordplayer/ui/shared/ui/app_icon.dart';
import 'package:nordplayer/ui/shared/ui/context_menu.dart';
import 'package:nordplayer/ui/shared/ui/frosted_glass.dart';
import 'package:nordplayer/ui/shared/ui/nord_alert_dialog.dart';
import 'package:nordplayer/ui/shared/ui/nord_snack_bar.dart';
import 'package:nordplayer/ui/shared/ui/sections/section_container.dart';
import 'package:nordplayer/ui/shared/ui/sections/section_page_title.dart';

/// Pure presentation View for the Playlists overview screen, observing [PlaylistsUiState].
class PlaylistsView extends ConsumerWidget {
  const PlaylistsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final uiState = ref.watch(playlistsViewModelProvider);
    final appIconSet = ref.watch(appIconProvider);

    return Scaffold(
      backgroundColor: uiState.isAdaptiveBg ? Colors.transparent : theme.colorScheme.surface,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: SectionContainer(
              child: SectionPageTitle(
                title: 'Playlists',
                titleStyle: theme.textTheme.headlineSmall,
                trailing: Row(
                  children: [
                    IconButton(
                      onPressed: () => showCreatePlaylistDialog(context),
                      icon: AppIcon(appIconSet.add, color: theme.textTheme.headlineSmall!.color, size: 22),
                      tooltip: 'Add New Playlist',
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(child: _buildBody(context, uiState)),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, PlaylistsUiState uiState) {
    if (uiState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (uiState.errorMessage != null) {
      return Center(child: Text('Error: ${uiState.errorMessage}'));
    }
    if (uiState.isEmpty) {
      return const Center(child: Text('No playlists yet. Create one to get started!'));
    }

    final playlists = uiState.playlists;
    return LayoutBuilder(
      builder: (context, constraints) {
        const double minItemWidth = 252.0;
        final int crossAxisCount = (constraints.maxWidth / minItemWidth).floor().clamp(1, 100);

        return GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisExtent: 240,
            crossAxisSpacing: 24,
            mainAxisSpacing: 8,
          ),
          itemCount: playlists.length,
          itemBuilder: (context, index) {
            return Align(
              alignment: AlignmentDirectional.topStart,
              child: SizedBox(
                width: 220,
                child: PlaylistCard(playlistWithDetails: playlists[index], playlistId: playlists[index].playlist.id),
              ),
            );
          },
        );
      },
    );
  }
}

// ==========================================
// INDIVIDUAL PLAYLIST CARD (WITH HOVER STATE)
// ==========================================

class PlaylistCard extends ConsumerStatefulWidget {
  final PlaylistWithDetails playlistWithDetails;
  final int playlistId;

  const PlaylistCard({super.key, required this.playlistWithDetails, required this.playlistId});

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
    final uiState = ref.watch(playlistsViewModelProvider);
    final appIconSet = ref.watch(appIconProvider);

    final isPlayingThisPlaylist = uiState.activePlaylistId == playlistId;
    final isAudioPlaying = uiState.isAudioPlaying;
    final nowPlayingAlbumArt = isPlayingThisPlaylist && uiState.activePlaylistAlbumArt.isNotEmpty
        ? uiState.activePlaylistAlbumArt
        : null;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () {
          final basePath = Routes.playlistsPage;
          final targetId = widget.playlistWithDetails.playlist.id;
          context.go('$basePath/$targetId');
          log.i('Navigate to playlist $targetId');
        },
        onSecondaryTapDown: (details) {
          _showContextMenu(details.globalPosition, ref);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  AlbumArtStack(
                    imageUrls: isPlayingThisPlaylist && nowPlayingAlbumArt != null
                        ? nowPlayingAlbumArt
                        : widget.playlistWithDetails.imageUrls,
                    sliceWidth: 10,
                    alignment: Alignment.centerLeft,
                  ),
                  if (_isHovered)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(50),
                          border: Border.all(color: theme.colorScheme.outlineVariant),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(50),
                          child: FrostedGlass(
                            backgroundColor: uiState.isAdaptiveBg
                                ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
                                : theme.colorScheme.surfaceContainerHigh,
                            blurSigma: 20,
                            child: Material(
                              color: Colors.transparent,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  InkWell(
                                    key: _moreButtonKey,
                                    onTap: () {
                                      final RenderBox renderBox =
                                          _moreButtonKey.currentContext!.findRenderObject() as RenderBox;
                                      final buttonPosition = renderBox.localToGlobal(Offset.zero);
                                      _showContextMenu(buttonPosition, ref);
                                    },
                                    child: Container(
                                      alignment: Alignment.center,
                                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                      child: AppIcon(
                                        appIconSet.contextMenu,
                                        color: theme.colorScheme.primary,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (_isHovered)
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(50),
                          border: Border.all(color: theme.colorScheme.outlineVariant),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(50),
                          child: FrostedGlass(
                            backgroundColor: uiState.isAdaptiveBg
                                ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
                                : theme.colorScheme.surfaceContainerHigh,
                            blurSigma: 20,
                            child: Material(
                              color: Colors.transparent,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  InkWell(
                                    onTap: _playPlaylist,
                                    child: Container(
                                      alignment: Alignment.center,
                                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                      child: Icon(Icons.play_arrow_rounded, color: theme.colorScheme.primary, size: 28),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (isPlayingThisPlaylist && isAudioPlaying) ...[
                  AnimatedEqualizerIcon(color: theme.colorScheme.primary, size: 16, isPlaying: isAudioPlaying),
                  const SizedBox(width: 8),
                ],
                Text(
                  widget.playlistWithDetails.playlist.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: isPlayingThisPlaylist ? theme.colorScheme.primary : null,
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
                      color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  )
                : const Text(''),
          ],
        ),
      ),
    );
  }

  void _showContextMenu(Offset position, WidgetRef ref) {
    final uiState = ref.read(playlistsViewModelProvider);
    final appIconSet = ref.read(appIconProvider);

    ContextMenu.show(
      isAdaptive: uiState.isAdaptiveBg,
      context: context,
      globalPosition: position,
      actionMenus: [
        ContextMenuActions(icon: appIconSet.play, label: 'Play', onTap: _playPlaylist),
        ContextMenuActions(icon: appIconSet.addToQueue, label: 'Add to queue', onTap: _addToQueue),
        ContextMenuActions(
          icon: appIconSet.rename,
          label: 'Rename',
          onTap: () {
            showRenamePlaylistDialog(context, widget.playlistWithDetails.playlist);
          },
        ),
        ContextMenuActions(
          icon: appIconSet.delete,
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
    final vm = ref.read(playlistsViewModelProvider.notifier);
    final played = await vm.playPlaylistById(widget.playlistWithDetails.playlist.id);

    if (!played && mounted) {
      showNordSnackBar(message: 'This playlist is empty! Add some tracks first.', type: .info);
    }
  }

  Future<void> _addToQueue() async {
    final vm = ref.read(playlistsViewModelProvider.notifier);
    final count = await vm.addPlaylistToQueue(widget.playlistWithDetails.playlist.id);

    if (!mounted) return;
    if (count == 0) {
      showNordSnackBar(message: 'This playlist is empty! Add some tracks first.', type: .general);
    } else {
      showNordSnackBar(message: 'Added $count tracks to queue', type: .general);
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => NordAlertDialog(
        title: 'Delete Playlist?',
        content: Text(
          'Are you sure you want to delete "${widget.playlistWithDetails.playlist.name}"?\nThis cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final vm = ref.read(playlistsViewModelProvider.notifier);
      await vm.deletePlaylist(widget.playlistWithDetails.playlist.id);
      if (context.mounted) {
        showNordSnackBar(message: 'Deleted "${widget.playlistWithDetails.playlist.name}"', type: .success);
      }
    }
  }
}
