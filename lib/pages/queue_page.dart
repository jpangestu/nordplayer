import 'dart:async';
import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nordplayer/database/app_database.dart';
import 'package:nordplayer/pages/library_page.dart';
import 'package:nordplayer/services/config_service.dart';
import 'package:nordplayer/services/player_service.dart';
import 'package:nordplayer/services/preference_service.dart';
import 'package:nordplayer/widgets/frosted_glass.dart';
import 'package:nordplayer/widgets/music_tile.dart';

class QueuePage extends ConsumerStatefulWidget {
  const QueuePage({
    super.key,
    required this.isWideScreen,
    required this.isAppBarAllowContentBehindIt,
  });
  final bool isWideScreen;
  final bool isAppBarAllowContentBehindIt;

  @override
  ConsumerState<QueuePage> createState() => _QueuePageState();
}

class _QueuePageState extends ConsumerState<QueuePage> {
  late ScrollController _scrollController;

  /// The height of your MusicTile + padding (50 + 8 + 8).
  final double _itemHeight = 66.0;
  bool _isHeaderHovered = false;

  bool _isShuffling = false;
  Timer? _shuffleTimer;

  @override
  void initState() {
    super.initState();

    // Read the index exactly once when the page first opens
    final initialIndex = ref.read(currentTrackIndexProvider);

    // Calculate how far down to scroll. (If index is -1, just stay at 0)
    final initialOffset = initialIndex > 0 ? initialIndex * _itemHeight : 0.0;
    _scrollController = ScrollController(initialScrollOffset: initialOffset);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _shuffleTimer?.cancel();
    super.dispose();
  }

  void _scrollToCurrentTrack() {
    final currentIndex = ref.read(currentTrackIndexProvider);

    if (currentIndex >= 0 && _scrollController.hasClients) {
      _scrollController.animateTo(
        currentIndex * _itemHeight,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentTracks = ref.watch(currentTracksInQueueProvider);
    final currentTrackIndex = ref.watch(currentTrackIndexProvider);
    final currentPlaybackContext = ref.watch(playbackContextProvider);
    final selectedIndices = ref.watch(
      selectedTracksIndexProvider('queue_page'),
    );

    final isShuffleMode = ref.watch(preferenceServiceProvider).shuffleMode;

    final theme = Theme.of(context);
    final appConfig = ref.watch(configServiceProvider).requireValue;

    // Listen to shuffle mode change
    ref.listen<
      bool
    >(preferenceServiceProvider.select((prefs) => prefs.shuffleMode), (
      previous,
      next,
    ) {
      if (previous != next) {
        _isShuffling = true;
        _shuffleTimer?.cancel();
        // Failsafe: If the index magically doesn't change during shuffle,
        // lower the flag after 500ms anyway so normal animations aren't permanently broken.
        _shuffleTimer = Timer(const Duration(milliseconds: 500), () {
          if (mounted) _isShuffling = false;
        });
      }
    });

    // Make the currently playing song always at the top by default
    ref.listen<int>(currentTrackIndexProvider, (previous, next) {
      if (next != previous && next >= 0 && _scrollController.hasClients) {
        if (_isShuffling) {
          // It's a shuffle! Snap instantly and lower the flag immediately.
          _scrollController.jumpTo(next * _itemHeight);
          _isShuffling = false;
          _shuffleTimer?.cancel();
        } else {
          // It's a double-click, next track, or previous track! Animate smoothly.
          _scrollController.animateTo(
            next * _itemHeight,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
          );
        }
      }
    });

    return FrostedGlass(
      blurSigma: 10,
      child: Padding(
        padding: EdgeInsets.only(
          top: widget.isAppBarAllowContentBehindIt ? 60.0 : 0.0,
        ),
        child: SizedBox(
          width: widget.isWideScreen ? 350 : 300,
          child: Scaffold(
            backgroundColor: appConfig.adaptiveBg
                ? theme.colorScheme.surfaceContainer.withValues(
                    alpha: appConfig.adaptiveBgDimmer,
                  )
                : theme.colorScheme.surfaceContainer,
            // MediaQuery.removePadding ensure tracks list doesn't leave blank space
            // when scrolling up the first track in the list
            body: MediaQuery.removePadding(
              context: context,
              removeTop: true,
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  SliverAppBar(
                    pinned: true,
                    backgroundColor: appConfig.adaptiveBg
                        ? Colors.transparent
                        : theme.colorScheme.secondaryContainer,
                    // Disable app bar changing color when tracks list scrolls below it
                    surfaceTintColor: Colors.transparent,
                    elevation: 0,
                    scrolledUnderElevation: 4.0,
                    shadowColor: Colors.black,
                    titleSpacing: 0,
                    flexibleSpace: appConfig.adaptiveBg
                        ? ClipRect(
                            child: BackdropFilter(
                              filter: ImageFilter.blur(
                                sigmaX: 10.0,
                                sigmaY: 10.0,
                                tileMode: .mirror,
                              ),
                              child: Container(
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainer
                                    .withValues(alpha: 0.6),
                              ),
                            ),
                          )
                        : null,
                    title: MouseRegion(
                      onEnter: (_) => setState(() => _isHeaderHovered = true),
                      onExit: (_) => setState(() => _isHeaderHovered = false),
                      child: Container(
                        width: double.infinity,
                        height: kToolbarHeight,
                        alignment: Alignment.centerLeft,
                        padding: .symmetric(
                          horizontal: _isHeaderHovered ? 8 : 16.0,
                        ),
                        child: Row(
                          children: [
                            if (_isHeaderHovered) ...[
                              IconButton(
                                onPressed: () {
                                  ref
                                      .read(preferenceServiceProvider.notifier)
                                      .setShowQueue(false);
                                },
                                icon: Icon(Icons.keyboard_arrow_right),
                                tooltip: 'Close Queue',
                              ),
                              SizedBox(width: 8),
                            ],
                            Text('Queue'),
                          ],
                        ),
                      ),
                    ),
                  ),

                  SliverReorderableList(
                    // PERFORMANCE OPTIMIZATION:
                    // Bind the list's Key to the shuffle state (true/false).
                    // If not do it this way, toggling shuffle forces SliverReorderableList to calculate
                    // the animation paths for hundreds of tracks simultaneously, which freezes the UI.
                    // Changing the key forces Flutter to instantly destroy the old list and paint
                    // the new one from scratch, completely bypassing the expensive animation diffing.
                    key: ValueKey('queue_list_$isShuffleMode'),
                    onReorder: (oldIndex, newIndex) {
                      ref
                          .read(playerServiceProvider)
                          .moveTrack(oldIndex, newIndex);
                    },
                    itemCount: currentTracks.length,
                    itemExtent: _itemHeight,
                    itemBuilder: (context, index) {
                      final trackItem = currentTracks[index];

                      if (trackItem != null) {
                        final isSelected = selectedIndices.contains(index);
                        final isCurrentlyPlaying = index == currentTrackIndex;

                        return _QueueItem(
                          key: ObjectKey(trackItem),
                          index: index,
                          trackItem: trackItem,
                          isSelected: isSelected,
                          isCurrentlyPlaying: isCurrentlyPlaying,
                          onRemove: () {
                            ref.read(playerServiceProvider).removeTrack(index);
                          },
                          onClick:
                              (index, {required isCtrl, required isShift}) {
                                ref
                                    .read(
                                      selectedTracksIndexProvider(
                                        'queue_page',
                                      ).notifier,
                                    )
                                    .selectTrack(
                                      index,
                                      isCtrlSelect: isCtrl,
                                      isShiftSelect: isShift,
                                    );
                              },
                          onDoubleClick: (index) {
                            ref
                                .read(playerServiceProvider)
                                .setPlaylist(
                                  tracksToPlay: currentTracks.nonNulls.toList(),
                                  initialIndex: index,
                                  playbackContextType:
                                      currentPlaybackContext?.type ?? 'library',
                                  playbackContextId: currentPlaybackContext?.id,
                                );
                          },
                          onRightClick: (index, globalPosition) {
                            final selectionNotifier = ref.read(
                              selectedTracksIndexProvider(
                                'queue_page',
                              ).notifier,
                            );
                            final currentSelection = ref.read(
                              selectedTracksIndexProvider('queue_page'),
                            );

                            // If right-clicking an unselected item, select it first and clear others
                            if (!currentSelection.contains(index)) {
                              selectionNotifier.selectTrack(
                                index,
                                isCtrlSelect: false,
                                isShiftSelect: false,
                              );
                            }

                            final updatedSelection = ref.read(
                              selectedTracksIndexProvider('queue_page'),
                            );

                            // Convert to list and sort the indices
                            final sortedIndices = updatedSelection.toList()
                              ..sort();

                            // Safely map the selected tracks
                            final List<TrackWithArtists> selectedTracks =
                                sortedIndices
                                    .map((i) => currentTracks[i])
                                    .nonNulls
                                    .toList();

                            TrackContextMenu.show(
                              context: context,
                              ref: ref,
                              isAdaptive: ref
                                  .watch(configServiceProvider)
                                  .requireValue
                                  .adaptiveBg,
                              globalPosition: globalPosition,
                              allTracks: currentTracks.nonNulls.toList(),
                              clickedIndex:
                                  index, // Assuming no nulls skewing the index
                              selectedTracks: selectedTracks,
                              playbackContextType:
                                  'queue', // Explicitly pass 'queue'
                              playbackContextId: null,
                            );
                          },
                        );
                      }
                      return SizedBox.shrink(key: ValueKey('empty_$index'));
                    },
                  ),
                ],
              ),
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: _scrollToCurrentTrack,
              mini: true,
              tooltip: 'Show currently playing',
              child: const Icon(Icons.keyboard_arrow_up),
            ),
          ),
        ),
      ),
    );
  }
}

class _QueueItem extends ConsumerStatefulWidget {
  final int index;
  final TrackWithArtists trackItem;
  final bool isSelected;
  final bool isCurrentlyPlaying;
  final VoidCallback onRemove;
  final void Function(int index, {required bool isCtrl, required bool isShift})?
  onClick;
  final void Function(int index)? onDoubleClick;
  final void Function(int index, Offset globalPosition)? onRightClick;

  const _QueueItem({
    required super.key,
    required this.index,
    required this.trackItem,
    required this.isSelected,
    required this.isCurrentlyPlaying,
    required this.onRemove,
    required this.onClick,
    required this.onDoubleClick,
    required this.onRightClick,
  });

  @override
  ConsumerState<_QueueItem> createState() => _QueueItemState();
}

class _QueueItemState extends ConsumerState<_QueueItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Listener(
        onPointerDown: (event) {
          if (event.buttons == kPrimaryMouseButton) {
            final isCtrl =
                HardwareKeyboard.instance.isControlPressed ||
                HardwareKeyboard.instance.isMetaPressed;
            final isShift = HardwareKeyboard.instance.isShiftPressed;

            widget.onClick?.call(
              widget.index,
              isCtrl: isCtrl,
              isShift: isShift,
            );
          } else if (event.buttons == kSecondaryMouseButton) {
            widget.onRightClick?.call(widget.index, event.position);
          }
        },
        child: GestureDetector(
          onDoubleTap: () => widget.onDoubleClick?.call(widget.index),
          child: Container(
            height: 66,
            color: widget.isSelected
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                : _isHovered
                ? Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.05)
                : Colors.transparent,
            child: Stack(
              alignment: Alignment.centerRight,
              children: [
                MusicTile(
                  selected: widget.isCurrentlyPlaying,
                  padding: EdgeInsets.only(
                    left: 16,
                    top: 8,
                    bottom: 8,
                    right: _isHovered ? 90.0 : 16.0,
                  ),
                  title: widget.trackItem.track.title,
                  artists: widget.trackItem.artists
                      .map<String>((artist) => artist.name)
                      .toList(),
                  albumArtPath: widget.trackItem.album.albumArtPath,
                ),

                // Show action buttons only when hovered
                if (_isHovered)
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: widget.onRemove,
                          tooltip: 'Remove from queue',
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        // Desktop users need a specific drag handle to click and drag
                        ReorderableDragStartListener(
                          index: widget.index,
                          child: IconButton(
                            icon: const Icon(Icons.drag_indicator, size: 20),
                            onPressed: () {}, // Handled by the drag listener
                            mouseCursor: SystemMouseCursors.grab,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
