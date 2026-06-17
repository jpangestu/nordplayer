import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nordplayer/database/app_database.dart';
import 'package:nordplayer/routes/router.dart';
import 'package:nordplayer/services/config_service.dart';
import 'package:nordplayer/widgets/context_menu.dart';

class AlbumsPage extends ConsumerWidget {
  const AlbumsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final appConfig = ref.watch(configServiceProvider).requireValue;
    final albums = ref.watch(albumsProvider);

    return Scaffold(
      backgroundColor: appConfig.adaptiveBg ? Colors.transparent : theme.colorScheme.surface,
      body: albums.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Text('Error loading albums: $err'),
        data: (data) {
          return Column(
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    const double minItemWidth = 200.0;
                    // Calculate exactly how many albums can fit.
                    final int crossAxisCount = (constraints.maxWidth / minItemWidth).floor().clamp(1, 100);

                    return GridView.builder(
                      padding: const .only(left: 24, right: 24, top: 24, bottom: 16),
                      itemCount: data.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
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
                widget.album.albumArtist!,
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
              onTapDown: (details) {
                // Fetch featured artists for this album
                final artistsAsync = ref.read(trackArtistsProvider(widget.album.id));

                artistsAsync.whenData((artists) {
                  if (artists.isEmpty) return;

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
                });
              },
              child: Text(
                widget.album.albumArtist!,
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
