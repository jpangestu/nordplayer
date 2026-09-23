import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nordplayer/utils/datetime_extension.dart';
import 'package:nordplayer/utils/int_extension.dart';
import 'package:nordplayer/domain/models/models.dart';
import 'package:nordplayer/ui/tracks/tracks_ui_state.dart';
import 'package:nordplayer/ui/tracks/tracks_viewmodel.dart';
import 'package:nordplayer/ui/tracks/widgets/track_context_menu.dart';
import 'package:nordplayer/routing/router.dart';
import 'package:nordplayer/ui/shared/ui/album_art_stack.dart';
import 'package:nordplayer/ui/shared/ui/animated_equalizer_icon.dart';
import 'package:nordplayer/ui/shared/ui/app_icon.dart';
import 'package:nordplayer/ui/shared/ui/clickable_text.dart';
import 'package:nordplayer/ui/shared/ui/context_menu.dart';
import 'package:nordplayer/ui/shared/ui/frosted_glass.dart';
import 'package:nordplayer/ui/shared/ui/music_tile.dart';
import 'package:nordplayer/ui/shared/ui/sliver_resizable_table.dart';

/// Pure presentation View for the Tracks screen, observing [TracksUiState].
class TracksView extends ConsumerWidget {
  const TracksView({super.key});

  Widget _buildCell(
    BuildContext context,
    WidgetRef ref,
    String columnId,
    TrackWithArtists track,
    int index,
    TracksUiState uiState,
    TracksViewModel viewModel,
  ) {
    switch (columnId) {
      case 'index':
        final isActiveTrack = uiState.activeTrackPath == track.track.filePath;
        if (isActiveTrack) {
          return AnimatedEqualizerIcon(
            color: Theme.of(context).colorScheme.primary,
            size: 16,
            isPlaying: uiState.isAudioPlaying,
          );
        }
        return Text(
          "${index + 1}",
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6)),
        );
      case 'title_artist':
        final isPlaying = uiState.activeTrackPath == track.track.filePath;
        return MusicTile(
          selected: isPlaying,
          albumArtPath: track.album.albumArtPath,
          title: track.track.title,
          artists: track.artists.map((a) => a.name).toList(),
          padding: EdgeInsets.zero,
        );
      case 'album':
        return ClickableText(
          text: track.album.title,
          onTap: () {
            final basePath = Routes.albumsPage;
            final targetId = track.album.id;
            context.go('$basePath/$targetId');
          },
        );
      case 'path':
        return Text(track.track.filePath, maxLines: 1, overflow: TextOverflow.ellipsis);
      case 'date_added':
        return Text(track.track.dateAdded.toRelativeTime(), maxLines: 1, overflow: TextOverflow.ellipsis);
      case 'duration':
        return Text(track.track.durationMs.toDurationString());
      case 'context_menu':
        return Listener(
          onPointerDown: (event) {
            if (!uiState.selectedIndices.contains(index)) {
              viewModel.selectSingle(index);
            }

            final currentSelection = ref.read(tracksViewModelProvider).selectedIndices;
            final sortedIndices = currentSelection.toList()..sort();
            final selectedTracks = sortedIndices
                .where((i) => i >= 0 && i < uiState.tracks.length)
                .map((i) => uiState.tracks[i])
                .toList();

            TrackContextMenu.show(
              context: context,
              ref: ref,
              isAdaptive: uiState.isAdaptiveBg,
              globalPosition: event.position,
              tracks: uiState.tracks,
              clickedIndex: index,
              selectedTracks: selectedTracks,
              playbackContextType: 'all_tracks',
            );
          },
          child: IconButton(icon: const Icon(Icons.more_horiz), onPressed: () {}),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final uiState = ref.watch(tracksViewModelProvider);
    final viewModel = ref.read(tracksViewModelProvider.notifier);

    final tracksPageTableColumns = uiState.columns
        .map(
          (config) => TableColumn<TrackWithArtists>.fromConfig(
            config: config,
            cellBuilder: (context, track, index) =>
                _buildCell(context, ref, config.id, track, index, uiState, viewModel),
          ),
        )
        .toList();

    if (uiState.isLoading) {
      return Scaffold(
        backgroundColor: uiState.isAdaptiveBg ? Colors.transparent : theme.colorScheme.surface,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (uiState.errorMessage != null) {
      return Scaffold(
        backgroundColor: uiState.isAdaptiveBg ? Colors.transparent : theme.colorScheme.surface,
        body: Center(child: Text('Error loading tracks: ${uiState.errorMessage}')),
      );
    }

    if (uiState.isEmpty) {
      return Scaffold(
        backgroundColor: uiState.isAdaptiveBg ? Colors.transparent : theme.colorScheme.surface,
        body: Column(
          children: [
            TracksPageHeader(tracks: uiState.tracks, albumArtCovers: uiState.albumArtCovers),
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
      );
    }

    return Scaffold(
      backgroundColor: uiState.isAdaptiveBg ? Colors.transparent : theme.colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: TracksPageHeader(tracks: uiState.tracks, albumArtCovers: uiState.albumArtCovers),
          ),
          SliverResizableTable(
            items: uiState.tracks,
            columns: tracksPageTableColumns,
            selectedIndices: uiState.selectedIndices,
            rowHeight: 66.0,
            tablePadding: const EdgeInsets.only(left: 24, top: 8, bottom: 24, right: 24),
            isAdaptive: uiState.isAdaptiveBg,
            headerBlur: uiState.adaptiveBgPanelBlur,
            headerThemeOverlay: uiState.adaptiveBgThemeOverlay,
            onHeaderRightClick: (globalPosition) {
              ContextMenu.show(
                context: context,
                isAdaptive: uiState.isAdaptiveBg,
                globalPosition: globalPosition,
                actionMenus: [ContextMenuCustomWidget(child: const HeaderColumnSelectorMenu())],
              );
            },
            onRowClick: (index, {required isCtrl, required isShift}) {
              viewModel.selectTrack(index, isCtrlSelect: isCtrl, isShiftSelect: isShift);
            },
            onRowDoubleClick: (index) {
              viewModel.playTrack(uiState.tracks, index);
            },
            onRowRightClick: (index, globalPosition) {
              if (!uiState.selectedIndices.contains(index)) {
                viewModel.selectSingle(index);
              }

              final updatedSelection = ref.read(tracksViewModelProvider).selectedIndices;
              final sortedIndices = updatedSelection.toList()..sort();
              final List<TrackWithArtists> selectedTracks = sortedIndices.map((i) => uiState.tracks[i]).toList();

              TrackContextMenu.show(
                context: context,
                ref: ref,
                isAdaptive: uiState.isAdaptiveBg,
                globalPosition: globalPosition,
                tracks: uiState.tracks,
                clickedIndex: index,
                selectedTracks: selectedTracks,
                playbackContextType: 'all_tracks',
                playbackContextId: null,
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Header collage and summary view for the Tracks screen.
class TracksPageHeader extends ConsumerWidget {
  final List<TrackWithArtists> tracks;
  final List<String> albumArtCovers;

  const TracksPageHeader({super.key, required this.tracks, required this.albumArtCovers});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isAdaptive = ref.watch(tracksViewModelProvider.select((s) => s.isAdaptiveBg));
    final panelBlur = ref.watch(tracksViewModelProvider.select((s) => s.adaptiveBgPanelBlur));
    final themeOverlay = ref.watch(tracksViewModelProvider.select((s) => s.adaptiveBgThemeOverlay));
    final int totalDurationMs = tracks.fold(0, (sum, track) => sum + track.track.durationMs);

    return FrostedGlass(
      backgroundColor: isAdaptive
          ? theme.colorScheme.surfaceContainer.withValues(alpha: themeOverlay)
          : theme.colorScheme.surface,
      blurSigma: panelBlur,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: isAdaptive
            ? const BoxDecoration()
            : BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    theme.colorScheme.surfaceContainer.withValues(alpha: 1.0),
                    theme.colorScheme.surface.withValues(alpha: 1.0),
                  ],
                ),
              ),
        child: Padding(
          padding: const EdgeInsets.only(top: 0.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                height: 220,
                width: 244,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: AlbumArtStack(imageUrls: albumArtCovers, size: 180, maxLayers: 5, sliceWidth: 16),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tracks', style: theme.textTheme.headlineMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text('${tracks.length} Tracks, ${totalDurationMs.toTotalDurationString()}'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Menu widget enabling users to toggle visibility of table columns.
class HeaderColumnSelectorMenu extends ConsumerWidget {
  const HeaderColumnSelectorMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final columns = ref.watch(tracksViewModelProvider.select((s) => s.columns));

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: columns.map((col) {
        return InkWell(
          onTap: () {
            ref.read(tracksViewModelProvider.notifier).toggleColumnVisibility(col.id);
          },
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(
                  col.isVisible ? Icons.check_box : Icons.check_box_outline_blank,
                  size: 20,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                const SizedBox(width: 12),
                Text(
                  col.label.isEmpty ? 'More Options' : col.label,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
