import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nordplayer/database/app_database.dart';
import 'package:nordplayer/pages/pages_context_menu.dart';
import 'package:nordplayer/pages/pages_helper.dart';
import 'package:nordplayer/services/config_service.dart';
import 'package:nordplayer/services/player_service.dart';
import 'package:nordplayer/services/preference_service.dart';
import 'package:nordplayer/theming/icon-sets/app_icon_set.dart';
import 'package:nordplayer/widgets/app_icon.dart';
import 'package:nordplayer/widgets/frosted_glass.dart';
import 'package:nordplayer/widgets/music_tile.dart';

class QueuePage extends ConsumerStatefulWidget {
  const QueuePage({super.key});

  @override
  ConsumerState<QueuePage> createState() => _QueuePageState();
}

class _QueuePageState extends ConsumerState<QueuePage> {
  late ScrollController _scrollController;

  /// The height of MusicTile + padding (50 + 8 + 8).
  final double _itemHeight = 66.0;
  bool _isHeaderHovered = false;

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
    final currentTrack = ref.watch(currentTrackProvider);
    final currentTracks = ref.watch(currentTracksInQueueProvider);
    final currentPlaybackContext = ref.watch(playbackContextProvider);
    final selectedIndices = ref.watch(selectedTracksIndexProvider('queue_page'));

    final theme = Theme.of(context);
    final appConfig = ref.watch(configServiceProvider).requireValue;
    final appIconSet = ref.watch(appIconProvider);

    // Handle index changes (Next/Prev/Auto-advance)
    ref.listen<int>(currentTrackIndexProvider, (previous, next) {
      if (next != previous && next >= 0 && _scrollController.hasClients) {
        // Read the exact intent of this track change
        final scrollBehavior = ref.read(queueScrollBehaviorProvider);

        if (scrollBehavior == QueueScrollBehavior.animate) {
          _scrollController.animateTo(
            next * _itemHeight,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
          );
        } else if (scrollBehavior == QueueScrollBehavior.jump) {
          _scrollController.jumpTo(next * _itemHeight);
        }

        // Reset the intent
        ref.read(queueScrollBehaviorProvider.notifier).setIntent(QueueScrollBehavior.none);
      }
    });

    return FrostedGlass(
      blurSigma: appConfig.adaptiveBgPanelBlur,
      child: SizedBox(
        width: 300,
        child: Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: appConfig.adaptiveBg ? Colors.transparent : theme.colorScheme.surfaceContainer,
            toolbarHeight: 60,
            // Disable app bar changing color when tracks list scrolls below it
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0.0,
            shadowColor: Colors.black,
            titleSpacing: 0,
            flexibleSpace: appConfig.adaptiveBg
                ? ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0, tileMode: .mirror),
                      child: Container(color: Colors.transparent),
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
                padding: .symmetric(horizontal: _isHeaderHovered ? 8 : 16.0),
                child: Row(
                  children: [
                    if (_isHeaderHovered) ...[
                      IconButton(
                        onPressed: () {
                          ref.read(preferenceServiceProvider.notifier).setShowQueue(false);
                        },
                        icon: AppIcon(appIconSet.sidebarOpen),
                        tooltip: 'Close Queue',
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text('Queue', style: Theme.of(context).textTheme.titleLarge),
                  ],
                ),
              ),
            ),
          ),
          backgroundColor: appConfig.adaptiveBg
              ? theme.colorScheme.surfaceContainerLow.withValues(alpha: appConfig.adaptiveBgThemeOverlay)
              : theme.colorScheme.surfaceContainerLow,
          body: ReorderableList(
            padding: const EdgeInsets.only(top: 66, bottom: 4),
            controller: _scrollController,
            onReorderStart: (index) {
              ref.read(queueIsDraggingProvider.notifier).setDragging(true);
            },
            onReorderEnd: (index) {
              ref.read(queueIsDraggingProvider.notifier).setDragging(false);
            },
            onReorder: (oldIndex, newIndex) {
              ref.read(selectedTracksIndexProvider('queue_page').notifier).updateIndicesOnReorder(oldIndex, newIndex);
              ref.read(currentTracksInQueueProvider.notifier).moveTrackOptimistically(oldIndex, newIndex);
              ref.read(playerServiceProvider).moveTrack(oldIndex, newIndex);
            },
            itemCount: currentTracks.length,
            itemExtent: _itemHeight,
            itemBuilder: (context, index) {
              final trackItem = currentTracks[index];

              final isSelected = selectedIndices.contains(index);
              final isCurrentlyPlaying =
                  currentTrack != null && trackItem.track.filePath == currentTrack.track.filePath;
              return _QueueItem(
                key: ObjectKey(trackItem),
                index: index,
                trackItem: trackItem,
                isSelected: isSelected,
                isCurrentlyPlaying: isCurrentlyPlaying,
                onRemove: () {
                  final selection = ref.read(selectedTracksIndexProvider('queue_page'));
                  if (selection.contains(index)) {
                    ref.read(playerServiceProvider).removeTracks(selection.toList());
                    ref.read(selectedTracksIndexProvider('queue_page').notifier).clear();
                  } else {
                    ref.read(playerServiceProvider).removeTrack(index);
                    ref.read(selectedTracksIndexProvider('queue_page').notifier).updateIndicesOnRemove(index);
                  }
                },
                onClick: (index, {required isCtrl, required isShift}) {
                  ref
                      .read(selectedTracksIndexProvider('queue_page').notifier)
                      .selectTrack(index, isCtrlSelect: isCtrl, isShiftSelect: isShift);
                },
                onDoubleClick: (index) {
                  ref.read(playerServiceProvider).suppressNextScroll();
                  ref
                      .read(playerServiceProvider)
                      .setPlaylist(
                        tracksToPlay: currentTracks.nonNulls.toList(),
                        initialIndex: index,
                        playbackContextType: currentPlaybackContext?.type ?? 'library',
                        playbackContextId: currentPlaybackContext?.id,
                      );
                },
                onRightClick: (index, globalPosition) {
                  final selectionNotifier = ref.read(selectedTracksIndexProvider('queue_page').notifier);
                  final currentSelection = ref.read(selectedTracksIndexProvider('queue_page'));

                  // If right-clicking an unselected item, select it first and clear others
                  if (!currentSelection.contains(index)) {
                    selectionNotifier.selectTrack(index, isCtrlSelect: false, isShiftSelect: false);
                  }

                  final updatedSelection = ref.read(selectedTracksIndexProvider('queue_page'));

                  // Convert to list and sort the indices
                  final sortedIndices = updatedSelection.toList()..sort();

                  // Safely map the selected tracks
                  final List<TrackWithArtists> selectedTracks = sortedIndices
                      .map((i) => currentTracks[i])
                      .nonNulls
                      .toList();

                  TrackContextMenu.show(
                    context: context,
                    ref: ref,
                    isAdaptive: ref.watch(configServiceProvider).requireValue.adaptiveBg,
                    globalPosition: globalPosition,
                    tracks: currentTracks.nonNulls.toList(),
                    clickedIndex: index, // Assuming no nulls skewing the index
                    selectedTracks: selectedTracks,
                    playbackContextType: 'queue', // Explicitly pass 'queue'
                    playbackContextId: null,
                  );
                },
              );
            },
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: _scrollToCurrentTrack,
            mini: true,
            tooltip: 'Show currently playing',
            child: const AppIcon(Icons.keyboard_arrow_up),
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
  final void Function(int index, {required bool isCtrl, required bool isShift})? onClick;
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
  bool _isHoveringActions = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDragging = ref.watch(queueIsDraggingProvider);

    // If we start dragging, hide the hover actions immediately
    final effectiveHover = _isHovered && !isDragging;

    return MouseRegion(
      onEnter: (_) {
        if (!isDragging) setState(() => _isHovered = true);
      },
      onExit: (_) => setState(() => _isHovered = false),
      child: Listener(
        onPointerDown: (event) {
          if (_isHoveringActions) return;

          if (event.buttons == kPrimaryMouseButton) {
            final isCtrl = HardwareKeyboard.instance.isControlPressed || HardwareKeyboard.instance.isMetaPressed;
            final isShift = HardwareKeyboard.instance.isShiftPressed;

            widget.onClick?.call(widget.index, isCtrl: isCtrl, isShift: isShift);
          } else if (event.buttons == kSecondaryMouseButton) {
            widget.onRightClick?.call(widget.index, event.position);
          }
        },
        child: Container(
          height: 66,
          color: widget.isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.1)
              : effectiveHover
              ? theme.colorScheme.onSurface.withValues(alpha: 0.05)
              : Colors.transparent,
          child: Stack(
            alignment: Alignment.centerRight,
            children: [
              GestureDetector(
                onDoubleTap: () => widget.onDoubleClick?.call(widget.index),
                child: ReorderableDragStartListener(
                  index: widget.index,
                  child: MusicTile(
                    selected: widget.isCurrentlyPlaying,
                    padding: EdgeInsets.only(left: 16, top: 8, bottom: 8, right: effectiveHover ? 90.0 : 16.0),
                    title: widget.trackItem.track.title,
                    artists: widget.trackItem.artists.map<String>((artist) => artist.name).toList(),
                    albumArtPath: widget.trackItem.album.albumArtPath,
                  ),
                ),
              ),

              // Show action buttons only when hovered
              if (effectiveHover)
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: MouseRegion(
                    onEnter: (_) => _isHoveringActions = true,
                    onExit: (_) => _isHoveringActions = false,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const AppIcon(Icons.close, size: 20),
                          onPressed: widget.onRemove,
                          tooltip: 'Remove from queue',
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        Builder(
                          builder: (buttonContext) => IconButton(
                            icon: const AppIcon(Icons.more_horiz, size: 20),
                            onPressed: () {
                              final RenderBox renderBox = buttonContext.findRenderObject() as RenderBox;
                              final position = renderBox.localToGlobal(Offset(0, renderBox.size.height));
                              widget.onRightClick?.call(widget.index, position);
                            },
                            tooltip: 'Options',
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

enum QueueScrollBehavior { animate, jump, none }

final queueScrollBehaviorProvider = NotifierProvider<ScrollBehaviorNotifier, QueueScrollBehavior>(
  ScrollBehaviorNotifier.new,
);

class ScrollBehaviorNotifier extends Notifier<QueueScrollBehavior> {
  @override
  QueueScrollBehavior build() => QueueScrollBehavior.none;

  void setIntent(QueueScrollBehavior intent) {
    state = intent;
  }
}

/// Tracks if a reorder drag is in progress to suppress hover effects and prevent flickering.
final queueIsDraggingProvider = NotifierProvider<QueueIsDraggingNotifier, bool>(QueueIsDraggingNotifier.new);

class QueueIsDraggingNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setDragging(bool dragging) {
    state = dragging;
  }
}
