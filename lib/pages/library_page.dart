import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nordplayer/database/app_database.dart';
import 'package:nordplayer/routes/router.dart';
import 'package:nordplayer/services/config_service.dart';
import 'package:nordplayer/services/player_service.dart';
import 'package:nordplayer/theming/icon-sets/app_icon_set.dart';
import 'package:nordplayer/utils/datetime_extension.dart';
import 'package:nordplayer/utils/int_extension.dart';
import 'package:nordplayer/utils/unimplemented.dart';
import 'package:nordplayer/widgets/app_icon.dart';
import 'package:nordplayer/widgets/frosted_glass.dart';
import 'package:nordplayer/widgets/music_tile.dart';

class LibraryPage extends ConsumerStatefulWidget {
  const LibraryPage({super.key});

  @override
  ConsumerState<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends ConsumerState<LibraryPage> {
  bool isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final appConfig = ref.watch(configServiceProvider).requireValue;

    return Scaffold(
      backgroundColor: appConfig.adaptiveBg ? Colors.transparent : Theme.of(context).colorScheme.surface,
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                const LibraryHeader(),

                // const CollapsibleSection(
                //   padding: .only(left: 24.0, right: 24.0, top: 0, bottom: 16),
                //   label: 'Pinned',
                //   content: Placeholder(fallbackHeight: 120),
                // ),
                const CollapsibleSection(label: 'Recently Added', content: RecentlyAddedPanel()),

                CollapsibleSection(
                  label: 'Albums',
                  onLabelClick: () {
                    context.go(Routes.albumsPage);
                  },
                  content: const AlbumsPanel(),
                ),

                CollapsibleSection(
                  padding: const .only(left: 24, right: 24, top: 0, bottom: 24),
                  label: 'All Tracks',
                  onLabelClick: () {
                    context.go(Routes.allTracksPage);
                  },
                  content: const AllTracksPanel(),
                ),

                // CollapsibleSection(
                //   label: 'Playlists',
                //   onLabelClick: () {
                //     context.go(Routes.playlistsPage);
                //   },
                //   content: const Placeholder(fallbackHeight: 120),
                // ),

                // CollapsibleSection(
                //   label: 'Genres',
                //   onLabelClick: () {
                //     // context.go(Routes.playlistsPage);
                //   },
                //   content: const Placeholder(fallbackHeight: 120),
                // ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class LibraryHeader extends ConsumerStatefulWidget {
  const LibraryHeader({super.key});

  @override
  ConsumerState<LibraryHeader> createState() => _LibraryHeaderState();
}

class _LibraryHeaderState extends ConsumerState<LibraryHeader> {
  bool isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appConfig = ref.watch(configServiceProvider).requireValue;
    final appIconSet = ref.watch(appIconProvider);
    final statsAsync = ref.watch(libraryStatsProvider);

    return Padding(
      padding: const .symmetric(horizontal: 12, vertical: 12),
      child: FrostedGlass(
        backgroundColor: appConfig.adaptiveBg
            ? theme.colorScheme.surfaceContainer.withValues(alpha: appConfig.adaptiveBgThemeOverlay * 0.5)
            : theme.colorScheme.surfaceContainer,
        blurSigma: appConfig.adaptiveBgPanelBlur,
        borderRadius: 6,
        child: AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          alignment: .topCenter,
          child: Container(
            padding: const .symmetric(horizontal: 12, vertical: 12),
            constraints: const BoxConstraints(minHeight: 60),
            child: Column(
              crossAxisAlignment: .start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 36,
                  child: Row(
                    children: [
                      const Text('Library', style: TextStyle(fontSize: 24, fontWeight: .bold)),
                      const Spacer(),
                      // IconButton(icon: AppIcon(appIconSet.preference), tooltip: 'Customize Sections', onPressed: () {}),
                      IconButton(
                        icon: AppIcon(isExpanded ? appIconSet.navigationDown : appIconSet.statistic),
                        color: theme.colorScheme.onSurface,
                        tooltip: isExpanded ? 'Hide Statistics' : 'Show Statistics',
                        onPressed: () {
                          setState(() {
                            isExpanded = !isExpanded;
                          });
                        },
                      ),
                    ],
                  ),
                ),

                if (isExpanded) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0, bottom: 12.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: statsAsync.when(
                        data: (stats) => Wrap(
                          spacing: 24,
                          runSpacing: 16,
                          alignment: .spaceEvenly,
                          children: [
                            LibraryStatItem(icon: appIconSet.allTracks, value: '${stats.trackCount}', label: 'Tracks'),
                            LibraryStatItem(icon: appIconSet.artists, value: '${stats.artistCount}', label: 'Artists'),
                            LibraryStatItem(icon: appIconSet.albums, value: '${stats.albumCount}', label: 'Albums'),
                            LibraryStatItem(icon: appIconSet.genres, value: '${stats.genreCount}', label: 'Genres'),
                            LibraryStatItem(
                              icon: appIconSet.playlist,
                              value: '${stats.playlistCount}',
                              label: 'Playlists',
                            ),
                            LibraryStatItem(
                              icon: appIconSet.playtime,
                              value: stats.formattedPlaytime,
                              label: 'Total Playtime',
                            ),
                            LibraryStatItem(icon: appIconSet.storage, value: stats.formattedSize, label: 'Total Size'),
                          ],
                        ),
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (err, stack) => Text('Error loading stats: $err'),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class LibraryStatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const LibraryStatItem({super.key, required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 32, color: theme.colorScheme.primary),

        const SizedBox(width: 12),

        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      ],
    );
  }
}

class CollapsibleSection extends ConsumerStatefulWidget {
  const CollapsibleSection({
    super.key,
    required this.label,
    this.onLabelClick,
    this.padding = const .only(left: 24, right: 24, top: 0, bottom: 8),
    required this.content,
  });

  final String label;
  final void Function()? onLabelClick;
  final EdgeInsetsGeometry padding;
  final Widget content;

  @override
  ConsumerState<CollapsibleSection> createState() => _CollapsibleSectionState();
}

class _CollapsibleSectionState extends ConsumerState<CollapsibleSection> {
  bool isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appIconSet = ref.watch(appIconProvider);

    return Padding(
      padding: widget.padding,
      child: Column(
        children: [
          Row(
            children: [
              MouseRegion(
                cursor: widget.onLabelClick != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
                child: GestureDetector(
                  onTap: widget.onLabelClick,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(widget.label, style: theme.textTheme.titleLarge),
                      if (widget.onLabelClick != null)
                        AppIcon(appIconSet.navigationRight, color: theme.textTheme.titleLarge!.color, size: 28),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              IconButton(
                onPressed: () {
                  setState(() {
                    isExpanded = !isExpanded;
                  });
                },
                icon: AppIcon(
                  isExpanded ? appIconSet.navigationDown : appIconSet.navigationRight,
                  color: theme.colorScheme.onSurface,
                  size: 28,
                ),
                tooltip: isExpanded ? 'Shrink' : 'Expand',
              ),
            ],
          ),
          if (isExpanded) widget.content,
        ],
      ),
    );
  }
}

class AlbumsPanel extends ConsumerStatefulWidget {
  const AlbumsPanel({super.key});

  @override
  ConsumerState<AlbumsPanel> createState() => _AlbumsPanelState();
}

class _AlbumsPanelState extends ConsumerState<AlbumsPanel> {
  final ScrollController _scrollController = ScrollController();
  bool _showLeftButton = false;
  bool _showRightButton = false;

  @override
  void initState() {
    super.initState();
    // Listen for scrolling to update button visibility
    _scrollController.addListener(_updateScrollButtons);

    // Wait for the first frame to render so we know the max scroll extent, which tells us if we need to show the right
    // arrow on initial load.
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateScrollButtons());
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateScrollButtons);
    _scrollController.dispose();
    super.dispose();
  }

  // The logic to evaluate if buttons should be shown
  void _updateScrollButtons() {
    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;
    // Show left if we've scrolled past 0
    final showLeft = position.pixels > 0;
    // Show right if we haven't reached the absolute end
    final showRight = position.pixels < position.maxScrollExtent;

    if (showLeft != _showLeftButton || showRight != _showRightButton) {
      setState(() {
        _showLeftButton = showLeft;
        _showRightButton = showRight;
      });
    }
  }

  // Smooth scrolling functions (jumps by ~2 albums at a time)
  void _scrollLeft() {
    if (!_scrollController.hasClients) return;

    final target = (_scrollController.offset - 360).clamp(0.0, _scrollController.position.maxScrollExtent);

    _scrollController.animateTo(target, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  void _scrollRight() {
    if (!_scrollController.hasClients) return;

    final target = (_scrollController.offset + 360).clamp(0.0, _scrollController.position.maxScrollExtent);

    _scrollController.animateTo(target, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  @override
  Widget build(BuildContext context) {
    final randomAlbumsAsync = ref.watch(randomAlbumsProvider);
    final theme = Theme.of(context);

    return randomAlbumsAsync.when(
      data: (albums) {
        if (albums.isEmpty) return const Text('No albums found.');

        // Force to check for arrows right after the albums finish rendering
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _updateScrollButtons();
        });

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Stack(
            alignment: Alignment.center,
            children: [
              SingleChildScrollView(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (int i = 0; i < albums.length; i++) ...[
                      Padding(
                        padding: EdgeInsets.only(left: i == 0 ? 0 : 12.0, right: i == albums.length - 1 ? 0 : 12.0),
                        child: SizedBox(
                          width: 160,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.file(
                                  File(
                                    albums[i].albumArtPath ??
                                        '/home/est/.cache/com.nordplayer.nordplayer/album_art/album_38.jpg',
                                  ),
                                  height: 160,
                                  width: 160,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                albums[i].title,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                                style: theme.textTheme.titleMedium,
                              ),
                              Text(albums[i].albumArtist ?? 'Unknown Artist', style: theme.textTheme.bodyMedium),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Left Scroll Button
              if (_showLeftButton)
                Positioned(
                  left: 0,
                  top: 56,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.surface.withValues(alpha: 0.8),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4)],
                    ),
                    child: IconButton(icon: const Icon(Icons.chevron_left), onPressed: _scrollLeft),
                  ),
                ),

              // Right Scroll Button
              if (_showRightButton)
                Positioned(
                  right: 0,
                  top: 56,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.surface.withValues(alpha: 0.8),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4)],
                    ),
                    child: IconButton(icon: const Icon(Icons.chevron_right), onPressed: _scrollRight),
                  ),
                ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Text('Error: $err'),
    );
  }
}

class AllTracksPanel extends ConsumerWidget {
  const AllTracksPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final libraryAsync = ref.watch(libraryStreamProvider);

    return libraryAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
      data: (allTracks) {
        if (allTracks.isEmpty) {
          return Text(
            "Your library is empty",
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          );
        }

        // Create a copy of the list, shuffle it, and take the first 6
        // TODO: Implement top tracks features and replace this
        final shuffledTracks = List<TrackWithArtists>.from(allTracks)..shuffle();
        final sixTracks = shuffledTracks.take(6).toList();

        return Column(
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                // The breakpoint for when it should switch to 2 columns
                final bool useTwoColumns = constraints.maxWidth > 600;
                const double spacing = 8.0;

                // Calculate the exact width each tile should take
                final double itemWidth = useTwoColumns
                    // Subtract spacing to prevent overflow
                    ? (constraints.maxWidth - spacing) / 2
                    : constraints.maxWidth;

                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    for (int i = 0; i < sixTracks.length; i++)
                      if (sixTracks[i].isNotEmpty)
                        SizedBox(
                          width: itemWidth,
                          child: LibraryTrackTile(
                            track: sixTracks[i],
                            showDateAdded: true,
                            playbackContextType: 'top_tracks',
                            tracksToPlay: sixTracks,
                            indexToPlay: i,
                          ),
                        ),
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class RecentlyAddedPanel extends ConsumerStatefulWidget {
  const RecentlyAddedPanel({super.key});

  @override
  ConsumerState<RecentlyAddedPanel> createState() => _RecentlyAddedPanelState();
}

class _RecentlyAddedPanelState extends ConsumerState<RecentlyAddedPanel> {
  bool showMore = false;

  @override
  Widget build(BuildContext context) {
    final recentTracksAsync = ref.watch(recentlyAddedTracksProvider);

    return recentTracksAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Text('Error loading recent tracks: $err'),
      data: (recentTracks) {
        if (recentTracks.isEmpty) {
          return const Center(
            child: Padding(padding: EdgeInsets.all(24.0), child: Text('No recently added tracks.')),
          );
        }

        int shownLength = showMore ? recentTracks.length : (recentTracks.length < 6 ? recentTracks.length : 6);

        return Column(
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                // The breakpoint for when it should switch to 2 columns
                final bool useTwoColumns = constraints.maxWidth > 600;
                const double spacing = 8.0;

                // Calculate the exact width each tile should take
                final double itemWidth = useTwoColumns
                    // Subtract spacing to prevent overflow
                    ? (constraints.maxWidth - spacing) / 2
                    : constraints.maxWidth;

                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    for (int i = 0; i < shownLength; i++)
                      if (recentTracks[i].isNotEmpty)
                        SizedBox(
                          width: itemWidth,
                          child: LibraryTrackTile(
                            track: recentTracks[i],
                            showDateAdded: true,
                            playbackContextType: 'recently_added',
                            tracksToPlay: recentTracks,
                            indexToPlay: i,
                          ),
                        ),
                  ],
                );
              },
            ),

            const SizedBox(height: 8),

            TextButton(
              onPressed: () {
                setState(() {
                  showMore = !showMore;
                });
              },
              child: Text(
                showMore ? 'Show Less' : 'Show More',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              ),
            ),
          ],
        );
      },
    );
  }
}

class LibraryTrackTile extends ConsumerWidget {
  const LibraryTrackTile({
    super.key,
    required this.track,
    this.showDateAdded = false,
    this.showDuration = false,
    required this.playbackContextType,
    required this.tracksToPlay,
    required this.indexToPlay,
  });

  final TrackWithArtists track;
  final bool showDateAdded;
  final bool showDuration;

  final String playbackContextType;
  final List<TrackWithArtists> tracksToPlay;
  final int indexToPlay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appIconSet = ref.watch(appIconProvider);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: .circular(6),
        onDoubleTap: () {
          ref
              .read(playerServiceProvider)
              .setPlaylist(
                playbackContextType: playbackContextType,
                playbackContextId: null,
                tracksToPlay: tracksToPlay,
                initialIndex: indexToPlay,
              );
        },
        child: SizedBox(
          height: 68,
          child: Row(
            children: [
              Expanded(
                child: MusicTile(
                  padding: const .only(left: 8.0),
                  title: track.track.title,
                  artists: track.artists.map((artist) => artist.name).toList(),
                  albumArtPath: track.album.albumArtPath,
                ),
              ),

              const SizedBox(width: 24),
              if (showDateAdded) ...[Text(track.track.dateAdded.toRelativeTime()), const SizedBox(width: 24)],
              if (showDuration) ...[Text(track.track.durationMs.toDurationString()), const SizedBox(width: 24)],

              IconButton(
                onPressed: () {
                  unimplemented(context);
                },
                icon: AppIcon(appIconSet.favorite),
              ),
              IconButton(
                onPressed: () {
                  unimplemented(context);
                },
                icon: AppIcon(appIconSet.contextMenu),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }
}
