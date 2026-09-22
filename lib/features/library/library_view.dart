import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nordplayer/core/theme/icon-sets/app_icon_set.dart';
import 'package:nordplayer/core/utils/datetime_extension.dart';
import 'package:nordplayer/core/utils/int_extension.dart';
import 'package:nordplayer/domain/models/models.dart';
import 'package:nordplayer/features/albums/albums_view.dart';
import 'package:nordplayer/features/library/library_ui_state.dart';
import 'package:nordplayer/features/library/library_viewmodel.dart';
import 'package:nordplayer/routes/router.dart';
import 'package:nordplayer/widgets/app_icon.dart';
import 'package:nordplayer/widgets/music_tile.dart';
import 'package:nordplayer/widgets/popover_panel.dart';
import 'package:nordplayer/widgets/sections/section_container.dart';
import 'package:nordplayer/widgets/sections/section_expansible.dart';
import 'package:nordplayer/widgets/sections/section_page_title.dart';
import 'package:nordplayer/widgets/unimplemented.dart';

/// Pure presentation View for the Library overview screen, observing [LibraryUiState].
class LibraryView extends ConsumerWidget {
  const LibraryView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final uiState = ref.watch(libraryViewModelProvider);
    final adaptiveBg = uiState.isAdaptiveBg;
    final viewModel = ref.read(libraryViewModelProvider.notifier);

    if (uiState.isLoading) {
      return Scaffold(
        backgroundColor: adaptiveBg ? Colors.transparent : theme.colorScheme.surface,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (uiState.errorMessage != null) {
      return Scaffold(
        backgroundColor: adaptiveBg ? Colors.transparent : theme.colorScheme.surface,
        body: Center(child: Text('Error loading stats: ${uiState.errorMessage}')),
      );
    }

    if (uiState.isEmpty) {
      return Scaffold(
        backgroundColor: adaptiveBg ? Colors.transparent : theme.colorScheme.surface,
        body: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              LibraryHeader(stats: uiState.stats),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
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
        ),
      );
    }

    return Scaffold(
      backgroundColor: adaptiveBg ? Colors.transparent : theme.colorScheme.surface,
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              children: [
                LibraryHeader(stats: uiState.stats),
                const SizedBox(height: 12),
                for (final section in uiState.sections)
                  if (section.isVisible) ...[
                    _buildSection(context, section.id, theme, uiState, viewModel),
                    const SizedBox(height: 12),
                  ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String id,
    ThemeData theme,
    LibraryUiState uiState,
    LibraryViewModel viewModel,
  ) {
    switch (id) {
      case 'recently_added':
        return SectionExpansible(
          initialState: InitialState.expanded,
          title: 'Recently Added',
          titleStyle: theme.textTheme.titleLarge,
          body: RecentlyAddedPanel(
            tracks: uiState.recentlyAddedTracks,
            showMore: uiState.isRecentlyAddedExpanded,
            onToggleShowMore: viewModel.toggleRecentlyAddedExpanded,
            onPlayTrack: (tracks, index) =>
                viewModel.playTrack(tracksToPlay: tracks, index: index, playbackContextType: 'recently_added'),
          ),
        );
      case 'albums':
        return SectionExpansible(
          initialState: InitialState.expanded,
          title: 'Albums',
          titleStyle: theme.textTheme.titleLarge,
          onTitleClick: () => context.go(Routes.albumsPage),
          body: AlbumsPanel(albums: uiState.randomAlbums),
        );
      case 'tracks':
        return SectionExpansible(
          initialState: InitialState.expanded,
          title: 'Tracks',
          titleStyle: theme.textTheme.titleLarge,
          onTitleClick: () => context.go(Routes.tracksPage),
          body: TracksPanel(
            sampleTracks: uiState.sampleTracks,
            onPlayTrack: (tracks, index) =>
                viewModel.playTrack(tracksToPlay: tracks, index: index, playbackContextType: 'top_tracks'),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

/// Header widget displaying aggregate library stats and section customization button.
class LibraryHeader extends ConsumerWidget {
  final LibraryStats stats;
  final GlobalKey _customizeSectionButtonKey = GlobalKey();

  LibraryHeader({super.key, required this.stats});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final appIconSet = ref.watch(appIconProvider);

    return SectionContainer(
      child: SectionPageTitle(
        initialState: InitialState.expanded,
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
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
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
            Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 24.0),
              child: SizedBox(
                width: double.infinity,
                child: Wrap(
                  spacing: 24,
                  runSpacing: 16,
                  alignment: WrapAlignment.spaceEvenly,
                  children: [
                    LibraryStatItem(icon: appIconSet.tracks, value: '${stats.trackCount}', label: 'Tracks'),
                    LibraryStatItem(icon: appIconSet.artists, value: '${stats.artistCount}', label: 'Artists'),
                    LibraryStatItem(icon: appIconSet.albums, value: '${stats.albumCount}', label: 'Albums'),
                    LibraryStatItem(icon: appIconSet.genres, value: '${stats.genreCount}', label: 'Genres'),
                    LibraryStatItem(icon: appIconSet.playlist, value: '${stats.playlistCount}', label: 'Playlists'),
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
          ],
        ),
      ),
    );
  }
}

/// Stat display item showing an icon, value, and label.
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

/// Horizontal scrollable panel displaying random albums with left/right navigation arrows.
class AlbumsPanel extends StatefulWidget {
  final List<Album> albums;

  const AlbumsPanel({super.key, required this.albums});

  @override
  State<AlbumsPanel> createState() => _AlbumsPanelState();
}

class _AlbumsPanelState extends State<AlbumsPanel> {
  final ScrollController _scrollController = ScrollController();
  bool _showLeftButton = false;
  bool _showRightButton = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateScrollButtons);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateScrollButtons());
  }

  @override
  void didUpdateWidget(covariant AlbumsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateScrollButtons());
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateScrollButtons);
    _scrollController.dispose();
    super.dispose();
  }

  void _updateScrollButtons() {
    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;
    final showLeft = position.pixels > 0;
    final showRight = position.pixels < position.maxScrollExtent;

    if (showLeft != _showLeftButton || showRight != _showRightButton) {
      setState(() {
        _showLeftButton = showLeft;
        _showRightButton = showRight;
      });
    }
  }

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
    final albums = widget.albums;
    if (albums.isEmpty) return const Text('No albums found.');

    final theme = Theme.of(context);

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
  }
}

/// Panel displaying up to 6 sample tracks in a 1-or-2-column wrap.
class TracksPanel extends StatelessWidget {
  final List<TrackWithArtists> sampleTracks;
  final void Function(List<TrackWithArtists> tracks, int index) onPlayTrack;

  const TracksPanel({super.key, required this.sampleTracks, required this.onPlayTrack});

  @override
  Widget build(BuildContext context) {
    if (sampleTracks.isEmpty) {
      return const Text("No tracks found");
    }

    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final bool useTwoColumns = constraints.maxWidth > 600;
            const double spacing = 8.0;
            final double itemWidth = useTwoColumns ? (constraints.maxWidth - spacing) / 2 : constraints.maxWidth;

            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                for (int i = 0; i < sampleTracks.length; i++)
                  if (sampleTracks[i].isNotEmpty)
                    SizedBox(
                      width: itemWidth,
                      child: LibraryTrackTile(
                        track: sampleTracks[i],
                        showDuration: true,
                        playbackContextType: 'top_tracks',
                        tracksToPlay: sampleTracks,
                        indexToPlay: i,
                        onPlayTrack: onPlayTrack,
                      ),
                    ),
              ],
            );
          },
        ),
      ],
    );
  }
}

/// Panel displaying recently added tracks with show more / show less toggle.
class RecentlyAddedPanel extends StatelessWidget {
  final List<TrackWithArtists> tracks;
  final bool showMore;
  final VoidCallback onToggleShowMore;
  final void Function(List<TrackWithArtists> tracks, int index) onPlayTrack;

  const RecentlyAddedPanel({
    super.key,
    required this.tracks,
    required this.showMore,
    required this.onToggleShowMore,
    required this.onPlayTrack,
  });

  @override
  Widget build(BuildContext context) {
    if (tracks.isEmpty) {
      return const Center(
        child: Padding(padding: EdgeInsets.all(16.0), child: Text('No recently added tracks.')),
      );
    }

    final int shownLength = showMore ? tracks.length : (tracks.length < 6 ? tracks.length : 6);

    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final bool useTwoColumns = constraints.maxWidth > 600;
            const double spacing = 8.0;
            final double itemWidth = useTwoColumns ? (constraints.maxWidth - spacing) / 2 : constraints.maxWidth;

            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                for (int i = 0; i < shownLength; i++)
                  if (tracks[i].isNotEmpty)
                    SizedBox(
                      width: itemWidth,
                      child: LibraryTrackTile(
                        track: tracks[i],
                        showDateAdded: true,
                        playbackContextType: 'recently_added',
                        tracksToPlay: tracks,
                        indexToPlay: i,
                        onPlayTrack: onPlayTrack,
                      ),
                    ),
              ],
            );
          },
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: onToggleShowMore,
          child: Text(
            showMore ? 'Show Less' : 'Show More',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          ),
        ),
      ],
    );
  }
}

/// Dumb track tile for library overview panels.
class LibraryTrackTile extends ConsumerWidget {
  const LibraryTrackTile({
    super.key,
    required this.track,
    this.showDateAdded = false,
    this.showDuration = false,
    required this.playbackContextType,
    required this.tracksToPlay,
    required this.indexToPlay,
    required this.onPlayTrack,
  });

  final TrackWithArtists track;
  final bool showDateAdded;
  final bool showDuration;
  final String playbackContextType;
  final List<TrackWithArtists> tracksToPlay;
  final int indexToPlay;
  final void Function(List<TrackWithArtists> tracks, int index) onPlayTrack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appIconSet = ref.watch(appIconProvider);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onDoubleTap: () => onPlayTrack(tracksToPlay, indexToPlay),
        child: SizedBox(
          height: 68,
          child: Row(
            children: [
              Expanded(
                child: MusicTile(
                  padding: const EdgeInsets.only(left: 8.0),
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

/// Popover panel permitting users to reorder and toggle visibility of library sections.
class LibrarySectionsPanel extends ConsumerWidget {
  const LibrarySectionsPanel({super.key});

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
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final adaptiveBgPanelBlur = ref.watch(libraryViewModelProvider.select((s) => s.adaptiveBgPanelBlur));
    final appIconSet = ref.watch(appIconProvider);
    final sections = ref.watch(librarySectionsProvider);

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
              itemCount: sections.length,
              onReorderItem: (int oldIndex, int newIndex) {
                ref.read(libraryViewModelProvider.notifier).reorderSections(oldIndex, newIndex);
              },
              itemBuilder: (context, index) {
                final section = sections[index];
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
                              ref.read(libraryViewModelProvider.notifier).toggleSectionVisibility(section.id);
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
