import 'dart:io' show File;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nordplayer/ui/shared/themes/icon_sets/app_icon_set.dart';
import 'package:nordplayer/utils/int_extension.dart';
import 'package:nordplayer/domain/models/models.dart';
import 'package:nordplayer/ui/albums/album_detail_ui_state.dart';
import 'package:nordplayer/ui/albums/album_detail_viewmodel.dart';
import 'package:nordplayer/ui/tracks/widgets/track_context_menu.dart';
import 'package:nordplayer/ui/shared/ui/animated_equalizer_icon.dart';
import 'package:nordplayer/ui/shared/ui/app_icon.dart';
import 'package:nordplayer/ui/shared/ui/base_button.dart';
import 'package:nordplayer/ui/shared/ui/button_container.dart';
import 'package:nordplayer/ui/shared/ui/context_menu.dart';
import 'package:nordplayer/ui/shared/ui/frosted_glass.dart';
import 'package:nordplayer/ui/shared/ui/select_popover.dart';
import 'package:nordplayer/ui/shared/ui/sliver_resizable_table.dart';
import 'package:nordplayer/ui/shared/ui/unimplemented.dart';

/// Pure presentation View for the Album Detail screen, observing [AlbumDetailUiState].
class AlbumDetailView extends ConsumerWidget {
  final int albumId;

  const AlbumDetailView({super.key, required this.albumId});

  Widget _buildCell(
    BuildContext context,
    WidgetRef ref,
    AlbumDetailUiState uiState,
    AlbumDetailViewModel viewModel,
    String columnId,
    TrackWithArtists track,
    int index,
    int albumId,
    List<TrackWithArtists> allTracks,
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
          track.track.trackNumber.toString(),
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6)),
        );
      case 'title':
        return Text(track.track.title);
      case 'duration':
        return Text(track.track.durationMs.toDurationString());
      case 'context_menu':
        final appIconSet = ref.watch(appIconProvider);

        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            IconButton(
              onPressed: () {
                unimplemented(context);
              },
              icon: AppIcon(appIconSet.favorite),
            ),
            Listener(
              onPointerDown: (event) {
                if (!uiState.selectedIndices.contains(index)) {
                  viewModel.selectSingle(index);
                }

                final selectedIndices = uiState.selectedIndices.contains(index)
                    ? (uiState.selectedIndices.toList()..sort())
                    : [index];
                final selectedTracks = selectedIndices
                    .where((i) => i >= 0 && i < allTracks.length)
                    .map((i) => allTracks[i])
                    .toList();

                TrackContextMenu.show(
                  context: context,
                  ref: ref,
                  isAdaptive: uiState.isAdaptiveBg,
                  globalPosition: event.position,
                  tracks: allTracks,
                  clickedIndex: index,
                  selectedTracks: selectedTracks,
                  playbackContextType: 'album',
                  playbackContextId: albumId,
                );
              },
              child: IconButton(icon: AppIcon(appIconSet.contextMenu), onPressed: () {}),
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final uiState = ref.watch(albumDetailViewModelProvider(albumId));
    final viewModel = ref.read(albumDetailViewModelProvider(albumId).notifier);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface.withValues(
        alpha: uiState.isAdaptiveBg ? uiState.adaptiveBgThemeOverlay : 1,
      ),
      body: Builder(
        builder: (context) {
          if (uiState.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (uiState.errorMessage != null) {
            return Center(child: Text('Error: ${uiState.errorMessage}'));
          }

          final data = uiState.albumWithTracks;

          // The album does not exist
          if (data == null) {
            return Center(child: Text("Album not found", style: theme.textTheme.titleLarge));
          }

          // The album exists, but the tracks list is empty
          if (data.tracks.isEmpty) {
            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: AlbumDetailViewHeader(albumId: albumId, albumWithTracks: data),
                ),
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: Text("This album has no tracks", style: theme.textTheme.titleMedium)),
                ),
              ],
            );
          }

          final albumDetailColumns = uiState.columns
              .map(
                (config) => TableColumn<TrackWithArtists>.fromConfig(
                  config: config,
                  cellBuilder: (context, track, index) =>
                      _buildCell(context, ref, uiState, viewModel, config.id, track, index, albumId, data.tracks),
                ),
              )
              .toList();

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: AlbumDetailViewHeader(albumId: albumId, albumWithTracks: data),
              ),

              SliverResizableTable(
                items: data.tracks,
                columns: albumDetailColumns,
                selectedIndices: uiState.selectedIndices,
                isAdaptive: uiState.isAdaptiveBg,
                headerBlur: uiState.adaptiveBgPanelBlur,
                headerThemeOverlay: uiState.adaptiveBgThemeOverlay,
                onHeaderRightClick: (globalPosition) {
                  ContextMenu.show(
                    context: context,
                    isAdaptive: uiState.isAdaptiveBg,
                    globalPosition: globalPosition,
                    actionMenus: [
                      ContextMenuCustomWidget(child: AlbumDetailViewTableColumnSelectorMenu(albumId: albumId)),
                    ],
                  );
                },
                onRowClick: (index, {required isCtrl, required isShift}) {
                  viewModel.selectTrack(index, isCtrlSelect: isCtrl, isShiftSelect: isShift);
                },
                onRowDoubleClick: (index) {
                  viewModel.playAlbum(tracks: data.tracks, initialIndex: index, shouldShuffle: false);
                },
                onRowRightClick: (index, globalPosition) {
                  if (!uiState.selectedIndices.contains(index)) {
                    viewModel.selectSingle(index);
                  }

                  final currentSelection = uiState.selectedIndices.contains(index)
                      ? (uiState.selectedIndices.toList()..sort())
                      : [index];
                  final List<TrackWithArtists> selectedTracks = currentSelection
                      .where((i) => i >= 0 && i < data.tracks.length)
                      .map((i) => data.tracks[i])
                      .toList();

                  TrackContextMenu.show(
                    context: context,
                    ref: ref,
                    isAdaptive: uiState.isAdaptiveBg,
                    globalPosition: globalPosition,
                    tracks: data.tracks,
                    clickedIndex: index,
                    selectedTracks: selectedTracks,
                    playbackContextType: 'album',
                    playbackContextId: albumId,
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Header component for Album Detail displaying artwork, title, metadata, and actions.
class AlbumDetailViewHeader extends ConsumerStatefulWidget {
  final int albumId;
  final AlbumWithTracks albumWithTracks;

  const AlbumDetailViewHeader({super.key, required this.albumId, required this.albumWithTracks});

  @override
  ConsumerState<AlbumDetailViewHeader> createState() => _AlbumDetailViewHeaderState();
}

class _AlbumDetailViewHeaderState extends ConsumerState<AlbumDetailViewHeader> {
  bool _isTitleHovered = false;
  final GlobalKey _sortButtonKey = GlobalKey();
  final GlobalKey _filterButtonKey = GlobalKey();

  Widget _buildFallbackArt(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(LucideIcons.disc3, size: 110, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final album = widget.albumWithTracks.album;
    final artPath = widget.albumWithTracks.album.albumArtPath;
    final tracks = widget.albumWithTracks.tracks;
    final theme = Theme.of(context);
    final appIconSet = ref.watch(appIconProvider);

    final uiState = ref.watch(albumDetailViewModelProvider(widget.albumId));
    final viewModel = ref.read(albumDetailViewModelProvider(widget.albumId).notifier);
    final shouldShuffle = uiState.shouldShuffle;

    // More info section
    final moreInfoParts = <String>[];
    if (album.year != 0) {
      moreInfoParts.add(album.year.toString());
    }
    final trackWord = tracks.length == 1 ? 'Track' : 'Tracks';
    moreInfoParts.add('${tracks.length} $trackWord, ${widget.albumWithTracks.tracksLengthMs.toTotalDurationString()}');
    final moreInfoString = moreInfoParts.join('  •  ');

    return FrostedGlass(
      backgroundColor: uiState.isAdaptiveBg
          ? theme.colorScheme.surfaceContainer.withValues(alpha: uiState.adaptiveBgThemeOverlay)
          : theme.colorScheme.surface,
      blurSigma: uiState.adaptiveBgPanelBlur,
      child: Container(
        padding: const .symmetric(horizontal: 24, vertical: 24),
        height: 200 + 48 + 24 + 36,
        decoration: uiState.isAdaptiveBg
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
        child: Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  // Album Art
                  SizedBox(
                    height: 200,
                    width: 200,
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
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 20),

                  // Descriptions
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Album title
                        Text(
                          widget.albumWithTracks.album.title,
                          style: theme.textTheme.headlineMedium,
                          maxLines: 2,
                          overflow: .ellipsis,
                        ),

                        const SizedBox(height: 8),

                        // Album artist
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          onEnter: (_) => setState(() => _isTitleHovered = true),
                          onExit: (_) => setState(() => _isTitleHovered = false),
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {},
                            child: Padding(
                              padding: const EdgeInsets.only(left: 0.0, right: 0.0, top: 4.0, bottom: 4.0),
                              child: Row(
                                mainAxisSize: .min,
                                children: [
                                  Text(
                                    widget.albumWithTracks.album.albumArtist ?? 'Unknown Artist',
                                    style: theme.textTheme.titleLarge!.copyWith(
                                      decoration: _isTitleHovered ? TextDecoration.underline : TextDecoration.none,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 2.0, top: 1.5),
                                    child: AnimatedSlide(
                                      offset: _isTitleHovered ? const Offset(0.1, 0) : Offset.zero,
                                      duration: const Duration(milliseconds: 200),
                                      curve: Curves.easeOutCubic,
                                      child: AppIcon(
                                        LucideIcons.chevronRight500,
                                        size: 24,
                                        color: theme.textTheme.titleLarge!.color,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 4),

                        // More info
                        Text(moreInfoString),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Buttons
            Row(
              children: [
                ButtonContainer(
                  buttons: [
                    BaseButton(
                      icon: Icons.play_arrow_rounded,
                      buttonHeight: 36,
                      buttonWidth: 74,
                      padding: const .only(right: 0),
                      iconSize: 26,
                      iconColor: theme.colorScheme.onSurface,
                      title: 'Play',
                      overlayShape: .rectangle,
                      overlayColor: theme.colorScheme.onSurface.withValues(alpha: 0.05),
                      onClick: () {
                        viewModel.playAlbum(tracks: tracks, shouldShuffle: shouldShuffle);
                      },
                    ),

                    Center(child: Container(width: 1, height: 20, color: theme.colorScheme.outlineVariant)),

                    BaseButton(
                      icon: appIconSet.shuffle,
                      buttonHeight: 36,
                      buttonWidth: 44,
                      padding: const .only(right: 8),
                      iconSize: 20,
                      iconColor: shouldShuffle ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                      overlayShape: .rectangle,
                      overlayColor: theme.colorScheme.onSurface.withValues(alpha: 0.05),
                      tooltip: 'Shuffle',
                      onClick: () {
                        viewModel.toggleShuffle();
                      },
                    ),
                  ],
                ),

                const SizedBox(width: 16),

                ButtonContainer(
                  buttons: [
                    BaseButton(
                      icon: appIconSet.favorite,
                      buttonHeight: 36,
                      buttonWidth: 42,
                      padding: const .only(left: 6),
                      iconSize: 20,
                      iconColor: theme.colorScheme.onSurface,
                      overlayShape: .rectangle,
                      overlayColor: theme.colorScheme.onSurface.withValues(alpha: 0.05),
                      tooltip: 'Favorite',
                      onClick: () {
                        unimplemented(context);
                      },
                    ),
                    BaseButton(
                      icon: appIconSet.contextMenu,
                      buttonHeight: 36,
                      buttonWidth: 42,
                      padding: const .only(right: 6),
                      iconSize: 20,
                      iconColor: theme.colorScheme.onSurface,
                      overlayShape: .rectangle,
                      overlayColor: theme.colorScheme.onSurface.withValues(alpha: 0.05),
                      tooltip: 'Context Menu',
                      onClick: () {
                        unimplemented(context);
                      },
                    ),
                  ],
                ),

                const Spacer(),

                ButtonContainer(
                  buttons: [
                    BaseButton(
                      key: _sortButtonKey,
                      icon: appIconSet.sort,
                      buttonHeight: 36,
                      buttonWidth: 42,
                      padding: const .only(left: 6),
                      iconSize: 20,
                      iconColor: theme.colorScheme.onSurface,
                      overlayShape: .rectangle,
                      overlayColor: theme.colorScheme.onSurface.withValues(alpha: 0.05),
                      tooltip: 'Sort',
                      onClick: () {
                        SelectPopover.show(
                          context: context,
                          anchorKey: _sortButtonKey,
                          closeOnSelect: false,
                          sectionsBuilder: (context, popoverRef) {
                            final currentSort = uiState.sortCriteria;
                            final currentOrder = uiState.sortOrder;

                            return [
                              SelectPopoverSection<AlbumTrackSort>(
                                title: 'Sort by',
                                selectedValue: currentSort,
                                options: const [
                                  SelectPopoverOption(title: 'Track Number', value: AlbumTrackSort.trackNumber),
                                  SelectPopoverOption(title: 'Title', value: AlbumTrackSort.title),
                                  SelectPopoverOption(title: 'Duration', value: AlbumTrackSort.duration),
                                ],
                                onSelected: (sort) {
                                  viewModel.setSort(sort);
                                },
                              ),
                              SelectPopoverSection<SortOrder>(
                                title: 'Order',
                                selectedValue: currentOrder,
                                options: const [
                                  SelectPopoverOption(title: 'Ascending', value: SortOrder.ascending),
                                  SelectPopoverOption(title: 'Descending', value: SortOrder.descending),
                                ],
                                onSelected: (order) {
                                  viewModel.setOrder(order);
                                },
                              ),
                            ];
                          },
                        );
                      },
                    ),
                    BaseButton(
                      key: _filterButtonKey,
                      icon: appIconSet.filter,
                      buttonHeight: 36,
                      buttonWidth: 42,
                      padding: const .only(right: 6),
                      iconSize: 20,
                      iconColor: theme.colorScheme.onSurface,
                      overlayShape: .rectangle,
                      overlayColor: theme.colorScheme.onSurface.withValues(alpha: 0.05),
                      tooltip: 'Filter',
                      onClick: () {
                        SelectPopover.show(
                          context: context,
                          anchorKey: _filterButtonKey,
                          closeOnSelect: false,
                          sectionsBuilder: (context, popoverRef) {
                            final showFavoritesOnly = uiState.showFavoritesOnly;
                            return [
                              SelectPopoverSection<bool>(
                                title: 'Filter',
                                options: [
                                  SelectPopoverOption<bool>(
                                    title: 'Favorites',
                                    value: true,
                                    isSelected: showFavoritesOnly,
                                    onTap: () {
                                      viewModel.toggleFavoritesOnly();
                                    },
                                  ),
                                ],
                              ),
                            ];
                          },
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Context menu popup widget for selecting which columns appear in the album detail table.
class AlbumDetailViewTableColumnSelectorMenu extends ConsumerWidget {
  final int albumId;

  const AlbumDetailViewTableColumnSelectorMenu({super.key, required this.albumId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final columns = ref.watch(albumDetailViewModelProvider(albumId).select((s) => s.columns));
    final viewModel = ref.read(albumDetailViewModelProvider(albumId).notifier);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: columns.map((col) {
        return InkWell(
          onTap: () {
            viewModel.toggleColumnVisibility(col.id);
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
                  col.label.isEmpty ? (col.id == 'context_menu' ? 'More Options' : col.id) : col.label,
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
