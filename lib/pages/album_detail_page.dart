import 'dart:io' show File;
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
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

class AlbumDetailPageHeader extends ConsumerWidget {
  const AlbumDetailPageHeader({super.key, required this.albumWithTracks});

  final AlbumWithTracks albumWithTracks;

  Widget _buildFallbackArt(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(LucideIcons.disc3, size: 110, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final album = albumWithTracks.album;
    final artPath = albumWithTracks.album.albumArtPath;
    final tracks = albumWithTracks.tracks;
    final theme = Theme.of(context);

    final appConfig = ref.watch(configServiceProvider).requireValue;
    final appIconSet = ref.watch(appIconProvider);

    // More info section
    final moreInfoParts = <String>[];
    if (album.year != 0) {
      moreInfoParts.add(album.year.toString());
    }
    final trackWord = tracks.length == 1 ? 'Track' : 'Tracks';
    moreInfoParts.add('${tracks.length} $trackWord, ${albumWithTracks.tracksLengthMs.toTotalDurationString()}');
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
                    child: Expanded(
                      child: Column(
                        mainAxisAlignment: .center,
                        crossAxisAlignment: .start,
                        children: [
                          // Album title
                          Text(
                            albumWithTracks.album.title,
                            style: theme.textTheme.headlineMedium,
                            maxLines: 2,
                            overflow: .ellipsis,
                          ),

                          const SizedBox(height: 8),

                          // Album artist
                          MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: () {},
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    albumWithTracks.album.albumArtist ?? 'Unknown Artist',
                                    style: theme.textTheme.titleLarge,
                                  ),
                                  AppIcon(
                                    appIconSet.navigationRight,
                                    color: theme.textTheme.titleLarge!.color,
                                    size: 28,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 4),

                          // More info
                          Text(moreInfoString),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Buttons
            HeaderButtons(albumTracks: albumWithTracks.tracks, albumId: albumWithTracks.album.id),
          ],
        ),
      ),
    );
  }
}

class HeaderButtons extends ConsumerStatefulWidget {
  const HeaderButtons({super.key, required this.albumTracks, required this.albumId});

  final int albumId;
  final List<TrackWithArtists> albumTracks;

  @override
  ConsumerState<HeaderButtons> createState() => _HeaderButtonsState();
}

class _HeaderButtonsState extends ConsumerState<HeaderButtons> {
  late bool shouldShuffle;

  @override
  void initState() {
    super.initState();
    shouldShuffle = ref.read(preferenceServiceProvider).shuffleMode;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final appConfig = ref.watch(configServiceProvider).requireValue;
    final appIconSet = ref.watch(appIconProvider);

    return Row(
      children: [
        // PLAY & SHUFFLE GROUP
        Container(
          height: 36,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(50),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(50),
            child: FrostedGlass(
              backgroundColor: appConfig.adaptiveBg
                  ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
                  : theme.colorScheme.surfaceContainerHigh,
              blurSigma: 20,
              child: Material(
                color: Colors.transparent,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Play Button
                    InkWell(
                      onTap: () {
                        final playerService = ref.read(playerServiceProvider);

                        final int startIndex = shouldShuffle ? Random().nextInt(widget.albumTracks.length) : 0;

                        // Sync the local state to the global preferences
                        ref.read(preferenceServiceProvider.notifier).setShuffleMode(shouldShuffle);

                        playerService.setPlaylist(
                          tracksToPlay: widget.albumTracks,
                          initialIndex: startIndex,
                          playbackContextType: 'album',
                          playbackContextId: widget.albumId,
                          forceReload: true,
                        );
                      },
                      child: Container(
                        alignment: Alignment.center,
                        padding: const .only(left: 8.0, right: 8.0),
                        child: Row(
                          children: [
                            Icon(Icons.play_arrow_rounded, color: theme.colorScheme.onSurface, size: 26),
                            const SizedBox(width: 4),
                            Text(
                              'Play',
                              style: theme.textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // The subtle vertical divider
                    Center(child: Container(width: 1, height: 20, color: theme.colorScheme.outlineVariant)),

                    // Shuffle Button
                    InkWell(
                      onTap: () {
                        setState(() {
                          shouldShuffle = !shouldShuffle;
                        });
                      },
                      child: Container(
                        alignment: Alignment.center,
                        padding: const .only(left: 8.0, right: 16.0),
                        child: AppIcon(
                          appIconSet.shuffle,
                          size: 20,
                          color: shouldShuffle ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // const Spacer(),
        const SizedBox(width: 16),

        // Favorite and context menu buttons
        Container(
          height: 36,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(50),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(50),
            child: FrostedGlass(
              backgroundColor: appConfig.adaptiveBg
                  ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
                  : theme.colorScheme.surfaceContainerHigh,
              blurSigma: 20,
              child: Material(
                color: Colors.transparent,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Favorite
                    InkWell(
                      onTap: () {
                        unimplemented(context);
                      },
                      child: Container(
                        alignment: Alignment.center,
                        padding: const .only(left: 14.0, right: 8.0),
                        child: AppIcon(appIconSet.favorite, color: theme.colorScheme.onSurface, size: 20),
                      ),
                    ),

                    // Context menu button
                    InkWell(
                      onTap: () {
                        unimplemented(context);
                      },
                      child: Container(
                        alignment: Alignment.center,
                        padding: const .only(left: 8.0, right: 14.0),
                        child: AppIcon(appIconSet.contextMenu, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
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
