import 'dart:io' show File;
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nordplayer/database/app_database.dart';
import 'package:nordplayer/pages/pages_context_menu.dart';
import 'package:nordplayer/pages/pages_helper.dart';
import 'package:nordplayer/services/config_service.dart';
import 'package:nordplayer/services/player_service.dart';
import 'package:nordplayer/services/preference_service.dart';
import 'package:nordplayer/theming/icon-sets/app_icon_set.dart';
import 'package:nordplayer/utils/int_extension.dart';
import 'package:nordplayer/utils/unimplemented.dart';
import 'package:nordplayer/widgets/animated_equalizer_icon.dart';
import 'package:nordplayer/widgets/app_icon.dart';
import 'package:nordplayer/widgets/frosted_glass.dart';
import 'package:nordplayer/widgets/sliver_resizable_table.dart';
import 'package:nordplayer/widgets/title_bar/base_button.dart';
import 'package:nordplayer/widgets/title_bar/button_container.dart';

class AlbumDetailPage extends ConsumerWidget {
  final int albumId;

  const AlbumDetailPage({super.key, required this.albumId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final appConfig = ref.watch(configServiceProvider).requireValue;
    final albumsWithTracks = ref.watch(albumWithTracksProvider(albumId));
    final albumDetailColumns = ref.watch(albumDetailPageColumnsProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface.withValues(
        alpha: appConfig.adaptiveBg ? appConfig.adaptiveBgThemeOverlay : 1,
      ),
      body: albumsWithTracks.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (data) {
          // The album not exist
          if (data == null) {
            return Center(child: Text("Album not found", style: theme.textTheme.titleLarge));
          }

          // The album exists, but the tracks list is empty
          if (data.tracks.isEmpty) {
            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: AlbumDetailPageHeader(albumWithTracks: data)),
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: Text("This album has no tracks", style: theme.textTheme.titleMedium)),
                ),
              ],
            );
          }

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: AlbumDetailPageHeader(albumWithTracks: data)),

              SliverResizableTable(
                items: data.tracks,
                columns: albumDetailColumns,
                isAdaptive: appConfig.adaptiveBg,
                headerBlur: appConfig.adaptiveBgPanelBlur,
                headerThemeOverlay: appConfig.adaptiveBgThemeOverlay,
                onRowClick: (index, {required isCtrl, required isShift}) {
                  ref
                      .read(selectedTracksIndexProvider('album').notifier)
                      .selectTrack(index, isCtrlSelect: isCtrl, isShiftSelect: isShift);
                },
                onRowDoubleClick: (index) {
                  ref
                      .read(playerServiceProvider)
                      .setPlaylist(
                        playbackContextType: 'album',
                        playbackContextId: albumId,
                        tracksToPlay: data.tracks,
                        initialIndex: index,
                      );
                },
                onRowRightClick: (index, globalPosition) {
                  final selectionNotifier = ref.read(selectedTracksIndexProvider('album').notifier);
                  final currentSelection = ref.read(selectedTracksIndexProvider('album'));

                  if (!currentSelection.contains(index)) {
                    selectionNotifier.selectTrack(index, isCtrlSelect: false, isShiftSelect: false);
                  }

                  final updatedSelection = ref.read(selectedTracksIndexProvider('album'));
                  final sortedIndices = updatedSelection.toList()..sort();

                  final List<TrackWithArtists> selectedTracks = sortedIndices.map((i) => data.tracks[i]).toList();

                  TrackContextMenu.show(
                    context: context,
                    ref: ref,
                    isAdaptive: appConfig.adaptiveBg,
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

class AlbumDetailPageHeader extends ConsumerStatefulWidget {
  final AlbumWithTracks albumWithTracks;
  const AlbumDetailPageHeader({super.key, required this.albumWithTracks});

  @override
  ConsumerState<AlbumDetailPageHeader> createState() => _AlbumDetailPageHeader();
}

class _AlbumDetailPageHeader extends ConsumerState<AlbumDetailPageHeader> {
  late bool shouldShuffle;
  bool _isTitleHovered = false;

  Widget _buildFallbackArt(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(LucideIcons.disc3, size: 110, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    shouldShuffle = ref.read(preferenceServiceProvider).shuffleMode;
  }

  @override
  Widget build(BuildContext context) {
    final album = widget.albumWithTracks.album;
    final artPath = widget.albumWithTracks.album.albumArtPath;
    final tracks = widget.albumWithTracks.tracks;
    final theme = Theme.of(context);

    final appConfig = ref.watch(configServiceProvider).requireValue;
    final appIconSet = ref.watch(appIconProvider);

    // More info section
    final moreInfoParts = <String>[];
    if (album.year != 0) {
      moreInfoParts.add(album.year.toString());
    }
    final trackWord = tracks.length == 1 ? 'Track' : 'Tracks';
    moreInfoParts.add('${tracks.length} $trackWord, ${widget.albumWithTracks.tracksLengthMs.toTotalDurationString()}');
    final moreInfoString = moreInfoParts.join('  •  ');

    return FrostedGlass(
      backgroundColor: appConfig.adaptiveBg
          ? theme.colorScheme.surfaceContainer.withValues(alpha: appConfig.adaptiveBgThemeOverlay)
          : theme.colorScheme.surface,
      blurSigma: appConfig.adaptiveBgPanelBlur,
      child: Container(
        padding: const .symmetric(horizontal: 24, vertical: 24),
        height: 200 + 48 + 24 + 36,
        decoration: appConfig.adaptiveBg
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
                        final playerService = ref.read(playerServiceProvider);

                        final int startIndex = shouldShuffle ? Random().nextInt(tracks.length) : 0;

                        // Sync the local state to the global preferences
                        ref.read(preferenceServiceProvider.notifier).setShuffleMode(shouldShuffle);

                        playerService.setPlaylist(
                          tracksToPlay: tracks,
                          initialIndex: startIndex,
                          playbackContextType: 'album',
                          playbackContextId: widget.albumWithTracks.album.id,
                          forceReload: true,
                        );
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
                        setState(() {
                          shouldShuffle = !shouldShuffle;
                        });
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
                        unimplemented(context);
                      },
                    ),
                    BaseButton(
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
                        unimplemented(context);
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

final albumDetailPageColumnsProvider =
    NotifierProvider<AlbumDetailPageColumnsNotifier, List<TableColumn<TrackWithArtists>>>(
      AlbumDetailPageColumnsNotifier.new,
    );

class AlbumDetailPageColumnsNotifier extends Notifier<List<TableColumn<TrackWithArtists>>> {
  @override
  List<TableColumn<TrackWithArtists>> build() {
    return _initialColumns;
  }

  void toggleVisibility(String columnId) {
    state = state.map((col) {
      if (col.id == columnId) {
        return col.copyWith(isVisible: !col.isVisible);
      }
      return col;
    }).toList();
  }

  static final List<TableColumn<TrackWithArtists>> _initialColumns = [
    TableColumn<TrackWithArtists>(
      id: 'index',
      label: "#",
      width: 50,
      minWidth: 50,
      alignment: Alignment.centerRight,
      cellBuilder: (context, track, index) {
        return Consumer(
          builder: (context, ref, child) {
            final isActiveTrack = ref.watch(currentTrackProvider)?.track.filePath == track.track.filePath;

            if (isActiveTrack) {
              final isAudioPlaying = ref.watch(isPlayingProvider);

              return AnimatedEqualizerIcon(
                color: Theme.of(context).colorScheme.primary,
                size: 16,
                isPlaying: isAudioPlaying,
              );
            }
            return Text(
              track.track.trackNumber.toString(),
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6)),
            );
          },
        );
      },
    ),
    TableColumn<TrackWithArtists>(
      id: 'title',
      label: "Title",
      flex: 5,
      minWidth: 150,
      cellBuilder: (context, track, index) {
        return Text(track.track.title);
      },
    ),
    TableColumn<TrackWithArtists>(
      id: 'duration',
      label: 'Duration',
      width: 90,
      minWidth: 90,
      alignment: Alignment.center,
      cellBuilder: (context, track, index) {
        return Text(track.track.durationMs.toDurationString());
      },
    ),
    TableColumn<TrackWithArtists>(
      id: 'context_menu',
      label: '',
      width: 115,
      minWidth: 115,
      alignment: Alignment.centerRight,
      cellBuilder: (context, track, index) {
        return Consumer(
          builder: (context, ref, child) {
            final appIconSet = ref.watch(appIconProvider);

            return Row(
              mainAxisAlignment: .end,
              children: [
                IconButton(
                  onPressed: () {
                    unimplemented(context);
                  },
                  icon: AppIcon(appIconSet.favorite), // TODO: do favorite system
                ),
                Listener(
                  onPointerDown: (event) {
                    // Sync Selection
                    final selectionNotifier = ref.read(selectedTracksIndexProvider('albums').notifier);
                    if (!ref.read(selectedTracksIndexProvider('albums')).contains(index)) {
                      selectionNotifier.selectTrack(index, isCtrlSelect: false, isShiftSelect: false);
                    }

                    // Grab the albumId directly from the track of the row that was clicked!
                    final albumId = track.album.id;

                    final albumData = ref.read(albumWithTracksProvider(albumId)).value;
                    final tracks = albumData?.tracks ?? [];

                    final selectedIndices = ref.read(selectedTracksIndexProvider('albums')).toList()..sort();
                    final selectedTracks = selectedIndices.map((i) => tracks[i]).toList();

                    TrackContextMenu.show(
                      context: context,
                      ref: ref,
                      isAdaptive: ref.read(configServiceProvider).requireValue.adaptiveBg,
                      globalPosition: event.position,
                      tracks: tracks,
                      clickedIndex: index,
                      selectedTracks: selectedTracks,

                      // 3. Make sure to pass the correct context to the menu!
                      playbackContextType: 'album',
                      playbackContextId: albumId,
                    );
                  },
                  child: IconButton(icon: AppIcon(appIconSet.contextMenu), onPressed: () {}),
                ),
              ],
            );
          },
        );
      },
    ),
  ];
}
