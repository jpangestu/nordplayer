import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nordplayer/domain/models/artist.dart';
import 'package:nordplayer/ui/artists/artists_ui_state.dart';
import 'package:nordplayer/ui/artists/artists_viewmodel.dart';
import 'package:nordplayer/ui/shared/themes/icon_sets/app_icon_set.dart';
import 'package:nordplayer/ui/shared/ui/app_icon.dart';
import 'package:nordplayer/ui/shared/ui/sections/section_container.dart';
import 'package:nordplayer/ui/shared/ui/sections/section_page_title.dart';

/// Pure presentation View for the Artists overview screen, observing [ArtistsUiState].
class ArtistsView extends ConsumerStatefulWidget {
  const ArtistsView({super.key});

  @override
  ConsumerState<ArtistsView> createState() => _ArtistsViewState();
}

class _ArtistsViewState extends ConsumerState<ArtistsView> {
  final GlobalKey _filterButtonKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appIconSet = ref.watch(appIconProvider);
    final uiState = ref.watch(artistsViewModelProvider);

    return Scaffold(
      backgroundColor: uiState.isAdaptiveBg ? Colors.transparent : theme.colorScheme.surface,
      body: Builder(
        builder: (context) {
          if (uiState.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (uiState.errorMessage != null) {
            return Center(child: Text('Error loading artists: ${uiState.errorMessage}'));
          }

          final data = uiState.artists;

          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const .only(left: 12.0, right: 12.0, top: 12.0, bottom: 12.0),
                sliver: SliverToBoxAdapter(
                  child: SectionContainer(
                    child: SectionPageTitle(
                      titleStyle: theme.textTheme.headlineSmall,
                      title: 'Artists',
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
                      'No artists found',
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
                      maxCrossAxisExtent: 180.0,
                      mainAxisExtent: 200,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemBuilder: (context, index) {
                      final artist = data[index];
                      return Center(
                        child: SizedBox(width: 150, child: ArtistCard(artist: artist)),
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

/// Circular avatar card widget rendering an artist's image, fallback icon, and name.
class ArtistCard extends StatefulWidget {
  final Artist artist;
  final VoidCallback? onTap;
  final double avatarSize;

  const ArtistCard({super.key, required this.artist, this.onTap, this.avatarSize = 130});

  @override
  State<ArtistCard> createState() => _ArtistCardState();
}

class _ArtistCardState extends State<ArtistCard> {
  bool _isHovering = false;

  Widget _buildFallbackAvatar(ThemeData theme) {
    return Container(
      width: widget.avatarSize,
      height: widget.avatarSize,
      decoration: BoxDecoration(shape: BoxShape.circle, color: theme.colorScheme.surfaceContainerHighest),
      child: Center(
        child: Icon(
          LucideIcons.user2,
          size: widget.avatarSize * 0.45,
          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final imgPath = widget.artist.artistImgPath;
    final isInteractive = widget.onTap != null;

    return MouseRegion(
      cursor: isInteractive ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: isInteractive ? (_) => setState(() => _isHovering = true) : null,
      onExit: isInteractive ? (_) => setState(() => _isHovering = false) : null,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: widget.avatarSize,
              height: widget.avatarSize,
              child: ClipOval(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (imgPath != null && imgPath.isNotEmpty)
                      Image.file(
                        File(imgPath),
                        fit: BoxFit.cover,
                        cacheWidth: 260,
                        errorBuilder: (context, error, stackTrace) => _buildFallbackAvatar(theme),
                      )
                    else
                      _buildFallbackAvatar(theme),

                    // Hover Overlay
                    AnimatedOpacity(
                      opacity: (_isHovering && isInteractive) ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: Container(
                        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black.withValues(alpha: 0.15)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Artist Name
            Text(
              widget.artist.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                decoration: (_isHovering && isInteractive) ? TextDecoration.underline : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
