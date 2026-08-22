import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nordplayer/database/app_database.dart';
import 'package:nordplayer/models/library_section_config.dart';
import 'package:nordplayer/pages/albums_page.dart';
import 'package:nordplayer/routes/router.dart';
import 'package:nordplayer/services/config_service.dart';
import 'package:nordplayer/services/player_service.dart';
import 'package:nordplayer/theming/icon-sets/app_icon_set.dart';
import 'package:nordplayer/utils/datetime_extension.dart';
import 'package:nordplayer/utils/int_extension.dart';
import 'package:nordplayer/utils/unimplemented.dart';
import 'package:nordplayer/widgets/app_icon.dart';
import 'package:nordplayer/widgets/music_tile.dart';
import 'package:nordplayer/widgets/popover_panel.dart';
import 'package:nordplayer/widgets/settings/section_container.dart';
import 'package:nordplayer/widgets/settings/section_expansible.dart';
import 'package:nordplayer/widgets/settings/section_page_titile.dart';

class LibraryPage extends ConsumerStatefulWidget {
  const LibraryPage({super.key});

  @override
  ConsumerState<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends ConsumerState<LibraryPage> {
  bool isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appConfig = ref.watch(configServiceProvider).requireValue;
    final adaptiveBg = ref.watch(configServiceProvider.select((config) => config.requireValue.adaptiveBg));
    final statsAsync = ref.watch(libraryStatsProvider);

    return Scaffold(
      backgroundColor: adaptiveBg ? Colors.transparent : Theme.of(context).colorScheme.surface,
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Text('Error loading stats: $err'),
        data: (stats) {
          if (stats.trackCount == 0) {
            return Padding(
              padding: const EdgeInsetsGeometry.all(12),
              child: Column(
                children: [
                  const LibraryHeader(),

                  Expanded(
                    child: Column(
                      mainAxisAlignment: .center,
                      children: [
                        Text(
                          "Your library is empty",
                          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Scan your local folders to set up your music library.",
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: () {
                            context.go('/settings/libraryIndexer');
                          },
                          icon: const AppIcon(Icons.create_new_folder),
                          label: const Text("Add Music Folders"),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  children: [
                    const LibraryHeader(),

                    const SizedBox(height: 12),

                    for (final section in appConfig.librarySections)
                      if (section.isVisible) ...[_buildSection(section.id, theme), const SizedBox(height: 12)],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSection(String id, ThemeData theme) {
    switch (id) {
      case 'recently_added':
        return SectionExpansible(
          initialState: InitialState.expanded,
          title: 'Recently Added',
          titleStyle: theme.textTheme.titleLarge,
          body: const RecentlyAddedPanel(),
        );
      case 'albums':
        return SectionExpansible(
          initialState: InitialState.expanded,
          title: 'Albums',
          titleStyle: theme.textTheme.titleLarge,
          onTitleClick: () => context.go(Routes.albumsPage),
          body: const AlbumsPanel(),
        );
      case 'tracks':
        return SectionExpansible(
          initialState: InitialState.expanded,
          title: 'Tracks',
          titleStyle: theme.textTheme.titleLarge,
          onTitleClick: () => context.go(Routes.tracksPage),
          body: const TracksPanel(),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

class LibraryHeader extends ConsumerStatefulWidget {
  const LibraryHeader({super.key});

  @override
  ConsumerState<LibraryHeader> createState() => _LibraryHeaderState();
}

class _LibraryHeaderState extends ConsumerState<LibraryHeader> {
  bool isExpanded = true;
  final GlobalKey _customizeSectionButtonKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appIconSet = ref.watch(appIconProvider);
    final statsAsync = ref.watch(libraryStatsProvider);

    return SectionContainer(
      child: SectionPageTitle(
        initialState: .expanded,
        title: 'Library',
        titleStyle: theme.textTheme.headlineSmall,
        trailing: Row(
          children: [
            IconButton(
              key: _customizeSectionButtonKey,
              onPressed: () {
                showPopover(
                  context: context,
                  anchorKey: _customizeSectionButtonKey,
                  width: 280,
                  padding: const .symmetric(vertical: 8.0, horizontal: 12.0),
                  child: const LibrarySectionsPanel(),
                );
              },
              icon: AppIcon(appIconSet.settings2, color: theme.textTheme.headlineSmall!.color, size: 22),
              tooltip: 'Customize Sections',
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: statsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Text('Error loading stats: $err'),
                data: (stats) => Wrap(
                  spacing: 24,
                  runSpacing: 16,
                  alignment: .spaceEvenly,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0, bottom: 24.0),
                      child: SizedBox(
                        width: double.infinity,
                        child: statsAsync.when(
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (err, stack) => Text('Error loading stats: $err'),
                          data: (stats) => Wrap(
                            spacing: 24,
                            runSpacing: 16,
                            alignment: .spaceEvenly,
                            children: [
                              LibraryStatItem(icon: appIconSet.tracks, value: '${stats.trackCount}', label: 'Tracks'),
                              LibraryStatItem(
                                icon: appIconSet.artists,
                                value: '${stats.artistCount}',
                                label: 'Artists',
                              ),
                              LibraryStatItem(icon: appIconSet.albums, value: '${stats.albumCount}', label: 'Albums'),
                              LibraryStatItem(icon: appIconSet.genres, value: '${stats.genreCount}', label: 'Genres'),
                              LibraryStatItem(
                                icon: appIconSet.playlist,
                                value: '${stats.playlistCount}',
                                label: 'Playlists',
                              ),
                              LibraryStatItem(
                                icon: appIconSet.playtime,
                                value: stats.totalPlaytimeMs.toTotalDurationString(),
                                label: 'Total Playtime',
                              ),
                              LibraryStatItem(
                                icon: appIconSet.storage,
                                value: stats.totalSizeBytes.toFileSizeString(),
                                label: 'Total Size',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
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
                          child: AlbumCard(
                            album: albums[i],
                            albumSize: 160,
                            onAlbumTap: () {
                              final basePath = Routes.albumsPage;
                              final targetId = albums[i].id;

                              context.go('$basePath/$targetId');
                            },
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

class TracksPanel extends ConsumerWidget {
  const TracksPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final libraryAsync = ref.watch(libraryStreamProvider);

    return libraryAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
      data: (tracks) {
        if (tracks.isEmpty) {
          return const Text("No tracks found");
        }

        // Create a copy of the list, shuffle it, and take the first 6
        // TODO: Implement top tracks features and replace this
        final shuffledTracks = List<TrackWithArtists>.from(tracks)..shuffle();
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
                            showDuration: true,
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
            child: Padding(padding: EdgeInsets.all(16.0), child: Text('No recently added tracks.')),
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

// ================================================================================================

class LibrarySectionsPanel extends ConsumerStatefulWidget {
  const LibrarySectionsPanel({super.key});

  @override
  ConsumerState<LibrarySectionsPanel> createState() => _LibrarySectionsPanelState();
}

class _LibrarySectionsPanelState extends ConsumerState<LibrarySectionsPanel> {
  late List<LibrarySectionConfig> _localSections;

  @override
  void initState() {
    super.initState();
    // Read current config state locally to initialize drag state
    final currentConfig = ref.read(configServiceProvider).requireValue;
    _localSections = List<LibrarySectionConfig>.from(currentConfig.librarySections);
  }

  String _getSectionName(String id) {
    switch (id) {
      case 'recently_added':
        return 'Recently Added';
      case 'albums':
        return 'Albums';
      case 'tracks':
        return 'Tracks';
      default:
        return id;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final adaptiveBgPanelBlur = ref.watch(
      configServiceProvider.select((config) => config.requireValue.adaptiveBgPanelBlur),
    );
    final appIconSet = ref.watch(appIconProvider);

    return PopoverPanel(
      width: 280,
      constraints: const BoxConstraints(maxHeight: 350),
      blurSigma: adaptiveBgPanelBlur,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 16.0, bottom: 8.0),
            child: Text(
              'CUSTOMIZE SECTIONS',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
                letterSpacing: 1.0,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Flexible(
            child: ReorderableListView.builder(
              buildDefaultDragHandles: false,
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              itemCount: _localSections.length,
              onReorderItem: (int oldIndex, int newIndex) {
                setState(() {
                  if (oldIndex < newIndex) {
                    newIndex -= 1;
                  }
                  final item = _localSections.removeAt(oldIndex);
                  _localSections.insert(newIndex, item);
                });
                ref.read(configServiceProvider.notifier).updateConfig(librarySections: _localSections);
              },
              itemBuilder: (context, index) {
                final section = _localSections[index];
                return Padding(
                  key: ValueKey(section.id),
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 12.0),
                        child: Text(
                          _getSectionName(section.id),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: section.isVisible
                                ? theme.colorScheme.onSurface
                                : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ReorderableDragStartListener(
                            index: index,
                            child: AppIcon(
                              appIconSet.dragVertical,
                              color: theme.colorScheme.onSurfaceVariant,
                              size: 20,
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _localSections[index] = section.copyWith(isVisible: !section.isVisible);
                              });
                              ref.read(configServiceProvider.notifier).updateConfig(librarySections: _localSections);
                            },
                            icon: AppIcon(
                              section.isVisible ? appIconSet.visible : appIconSet.invisible,
                              color: theme.colorScheme.onSurfaceVariant,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
