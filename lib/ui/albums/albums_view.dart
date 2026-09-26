import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nordplayer/domain/models/album.dart';
import 'package:nordplayer/routing/router.dart';
import 'package:nordplayer/ui/albums/albums_ui_state.dart';
import 'package:nordplayer/ui/albums/albums_viewmodel.dart';
import 'package:nordplayer/ui/shared/themes/icon_sets/app_icon_set.dart';
import 'package:nordplayer/ui/shared/ui/app_icon.dart';
import 'package:nordplayer/ui/shared/ui/context_menu.dart';
import 'package:nordplayer/ui/shared/ui/sections/section_container.dart';
import 'package:nordplayer/ui/shared/ui/sections/section_page_title.dart';

/// Pure presentation View for the Albums overview screen, observing [AlbumsUiState].
class AlbumsView extends ConsumerStatefulWidget {
  const AlbumsView({super.key});

  @override
  ConsumerState<AlbumsView> createState() => _AlbumsViewState();
}

class _AlbumsViewState extends ConsumerState<AlbumsView> {
  final GlobalKey _filterButtonKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appIconSet = ref.watch(appIconProvider);
    final uiState = ref.watch(albumsViewModelProvider);

    return Scaffold(
      backgroundColor: uiState.isAdaptiveBg ? Colors.transparent : theme.colorScheme.surface,
      body: Builder(
        builder: (context) {
          if (uiState.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (uiState.errorMessage != null) {
            return Center(child: Text('Error loading albums: ${uiState.errorMessage}'));
          }

          final data = uiState.albums;

          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const .only(left: 12.0, right: 12.0, top: 12.0, bottom: 12.0),
                sliver: SliverToBoxAdapter(
                  child: SectionContainer(
                    child: SectionPageTitle(
                      titleStyle: theme.textTheme.headlineSmall,
                      title: 'Albums',
                      trailing: Row(
                        children: [
                          IconButton(
                            key: _filterButtonKey,
                            onPressed: () {},
                            icon: AppIcon(appIconSet.filter, color: theme.textTheme.headlineSmall!.color, size: 22),
                            tooltip: 'Filter',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (uiState.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      'No albums found',
                      style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.only(left: 24, right: 24, top: 0, bottom: 16),
                  sliver: SliverGrid.builder(
                    itemCount: data.length,
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 200.0,
                      mainAxisExtent: 240,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 8,
                    ),
                    itemBuilder: (context, index) {
                      final album = data[index];
                      return Center(
                        child: SizedBox(
                          width: 180,
                          child: AlbumCard(
                            album: album,
                            onAlbumTap: () {
                              final basePath = Routes.albumsPage;
                              final targetId = album.id;
                              context.go('$basePath/$targetId');
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Card widget rendering an album cover, title, and artist name with hover effects.
class AlbumCard extends ConsumerStatefulWidget {
  final Album album;

  /// Default = 180
  final double? albumSize;
  final VoidCallback onAlbumTap;
  final VoidCallback? onAlbumArtistTap;

  const AlbumCard({super.key, required this.album, this.albumSize, required this.onAlbumTap, this.onAlbumArtistTap});

  @override
  ConsumerState<AlbumCard> createState() => _AlbumCardState();
}

class _AlbumCardState extends ConsumerState<AlbumCard> {
  bool _isHoveringAlbum = false;
  bool _isHoveringAlbumArtist = false;

  Widget _buildFallbackArt(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          LucideIcons.disc3,
          size: (widget.albumSize ?? 180) / 2,
          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String? artPath = widget.album.albumArtPath;

    return Column(
      children: [
        MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _isHoveringAlbum = true),
          onExit: (_) => setState(() => _isHoveringAlbum = false),
          child: GestureDetector(
            onTap: widget.onAlbumTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  height: widget.albumSize ?? 180,
                  width: widget.albumSize ?? 180,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // The Base Image (or fallback)
                        (artPath != null && artPath.isNotEmpty)
                            ? Image.file(
                                File(artPath),
                                fit: BoxFit.cover,
                                cacheWidth: 360,
                                errorBuilder: (context, error, stackTrace) => _buildFallbackArt(theme),
                              )
                            : _buildFallbackArt(theme),

                        // The Hover Overlay
                        AnimatedOpacity(
                          opacity: _isHoveringAlbum ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 200),
                          child: Container(color: Colors.black.withValues(alpha: 0.2)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),

                // The Album Title
                Text(
                  widget.album.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    decoration: _isHoveringAlbum ? TextDecoration.underline : null,
                  ),
                ),
              ],
            ),
          ),
        ),

        if (widget.album.albumArtistId != null) ...[
          MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) => setState(() => _isHoveringAlbumArtist = true),
            onExit: (_) => setState(() => _isHoveringAlbumArtist = false),
            child: GestureDetector(
              onTap: widget.onAlbumArtistTap,
              child: Text(
                widget.album.albumArtist ?? 'Unknown Artist',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  decoration: _isHoveringAlbumArtist ? TextDecoration.underline : TextDecoration.none,
                ),
              ),
            ),
          ),
        ] else ...[
          MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) => setState(() => _isHoveringAlbumArtist = true),
            onExit: (_) => setState(() => _isHoveringAlbumArtist = false),
            child: GestureDetector(
              onTapDown: (details) async {
                // Fetch featured artists for this album via ViewModel
                final artists = await ref.read(albumsViewModelProvider.notifier).getAlbumArtists(widget.album.id);
                if (artists.isEmpty || !context.mounted) return;

                ContextMenu.show(
                  context: context,
                  isAdaptive: true,
                  globalPosition: details.globalPosition,
                  actionMenus: artists.map((artist) {
                    return ContextMenuActions(
                      icon: Icons.person,
                      label: artist.name,
                      onTap: () {
                        // context.go('${Routes.artistsPage}/${artist.id}');
                      },
                    );
                  }).toList(),
                );
              },
              child: Text(
                widget.album.albumArtist ?? 'Various Artists',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  decoration: _isHoveringAlbumArtist ? TextDecoration.underline : TextDecoration.none,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
