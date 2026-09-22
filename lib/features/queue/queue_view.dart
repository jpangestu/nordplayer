import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nordplayer/core/models/queue_scroll_behavior.dart';
import 'package:nordplayer/core/theme/icon-sets/app_icon_set.dart';
import 'package:nordplayer/domain/models/models.dart';
import 'package:nordplayer/features/queue/queue_viewmodel.dart';
import 'package:nordplayer/features/tracks/widgets/track_context_menu.dart';
import 'package:nordplayer/widgets/app_icon.dart';
import 'package:nordplayer/widgets/frosted_glass.dart';
import 'package:nordplayer/widgets/music_tile.dart';

/// Pure presentation View for the active playback queue sidebar,
/// observing [QueueUiState] via [queueViewModelProvider].
class QueueView extends ConsumerStatefulWidget {
  const QueueView({super.key});

  @override
  ConsumerState<QueueView> createState() => _QueueViewState();
}

class _QueueViewState extends ConsumerState<QueueView> {
  late ScrollController _scrollController;

  /// The height of MusicTile + padding (50 + 8 + 8).
  static const double _itemHeight = 66.0;
  bool _isHeaderHovered = false;

  @override
  void initState() {
    super.initState();

    // Read initial queue index when page first opens
    final initialIndex = ref.read(queueViewModelProvider).currentIndex;
    final initialOffset = initialIndex > 0 ? initialIndex * _itemHeight : 0.0;
    _scrollController = ScrollController(initialScrollOffset: initialOffset);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToCurrentTrack() {
    final currentIndex = ref.read(queueViewModelProvider).currentIndex;

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
    final theme = Theme.of(context);
    final appIconSet = ref.watch(appIconProvider);
    final uiState = ref.watch(queueViewModelProvider);
    final viewModel = ref.read(queueViewModelProvider.notifier);

    // Auto-scroll when active track index advances
    ref.listen<int>(queueViewModelProvider.select((s) => s.currentIndex), (previous, next) {
      if (next != previous && next >= 0 && _scrollController.hasClients) {
        final scrollBehavior = ref.read(queueViewModelProvider).scrollBehavior;

        if (scrollBehavior == QueueScrollBehavior.animate) {
          _scrollController.animateTo(
            next * _itemHeight,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
          );
        } else if (scrollBehavior == QueueScrollBehavior.jump) {
          _scrollController.jumpTo(next * _itemHeight);
        }

        viewModel.resetScrollBehavior();
      }
    });

    final currentTracks = uiState.tracks;
    final selectedIndices = uiState.selectedIndices;

    return FrostedGlass(
      blurSigma: uiState.adaptiveBgPanelBlur,
      child: SizedBox(
        width: 300,
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: uiState.isAdaptiveBg ? Colors.transparent : theme.colorScheme.surfaceContainer,
            toolbarHeight: 60,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0.0,
            shadowColor: Colors.black,
            titleSpacing: 0,
            flexibleSpace: uiState.isAdaptiveBg
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
                        onPressed: viewModel.closeQueue,
                        icon: AppIcon(appIconSet.sidebarOpen),
                        tooltip: 'Close Queue',
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text('Queue', style: theme.textTheme.titleLarge),
                  ],
                ),
              ),
            ),
          ),
          backgroundColor: uiState.isAdaptiveBg
              ? theme.colorScheme.surfaceContainerLow.withValues(alpha: uiState.adaptiveBgThemeOverlay)
              : theme.colorScheme.surfaceContainerLow,
          body: ReorderableList(
            padding: const .symmetric(vertical: 8),
            controller: _scrollController,
            onReorderStart: (_) => viewModel.setDragging(true),
            onReorderEnd: (_) => viewModel.setDragging(false),
            onReorderItem: (oldIndex, newIndex) => viewModel.moveTrack(oldIndex, newIndex),
            itemCount: currentTracks.length,
            itemExtent: _itemHeight,
            itemBuilder: (context, index) {
              final trackItem = currentTracks[index];
              final isSelected = selectedIndices.contains(index);
              final isCurrentlyPlaying = uiState.isCurrentlyPlaying(trackItem);

              return _QueueItem(
                key: ObjectKey(trackItem),
                index: index,
                trackItem: trackItem,
                isSelected: isSelected,
                isCurrentlyPlaying: isCurrentlyPlaying,
                isDragging: uiState.isDragging,
                onRemove: () {
                  if (selectedIndices.contains(index)) {
                    viewModel.removeSelectedTracks(selectedIndices.toList());
                  } else {
                    viewModel.removeTrack(index);
                  }
                },
                onClick: (idx, {required isCtrl, required isShift}) {
                  viewModel.selectTrack(idx, isCtrl: isCtrl, isShift: isShift);
                },
                onDoubleClick: (idx) {
                  viewModel.jumpToTrack(idx);
                },
                onRightClick: (idx, globalPosition) {
                  // If right-clicking an unselected item, select it first and clear others
                  if (!selectedIndices.contains(idx)) {
                    viewModel.selectTrack(idx, isCtrl: false, isShift: false);
                  }

                  final updatedSelection = ref.read(queueViewModelProvider).selectedIndices;
                  final sortedIndices = updatedSelection.toList()..sort();
                  final selectedTracks = sortedIndices
                      .where((i) => i >= 0 && i < currentTracks.length)
                      .map((i) => currentTracks[i])
                      .toList();

                  TrackContextMenu.show(
                    context: context,
                    ref: ref,
                    isAdaptive: uiState.isAdaptiveBg,
                    globalPosition: globalPosition,
                    tracks: currentTracks,
                    clickedIndex: idx,
                    selectedTracks: selectedTracks,
                    playbackContextType: 'queue',
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

class _QueueItem extends StatefulWidget {
  final int index;
  final TrackWithArtists trackItem;
  final bool isSelected;
  final bool isCurrentlyPlaying;
  final bool isDragging;
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
    required this.isDragging,
    required this.onRemove,
    required this.onClick,
    required this.onDoubleClick,
    required this.onRightClick,
  });

  @override
  State<_QueueItem> createState() => _QueueItemState();
}

class _QueueItemState extends State<_QueueItem> {
  bool _isHovered = false;
  bool _isHoveringActions = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // If we start dragging, hide hover actions immediately
    final effectiveHover = _isHovered && !widget.isDragging;

    return MouseRegion(
      onEnter: (_) {
        if (!widget.isDragging) setState(() => _isHovered = true);
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
                    padding: .only(left: 16, top: 8, bottom: 8, right: effectiveHover ? 90.0 : 16.0),
                    title: widget.trackItem.track.title,
                    artists: widget.trackItem.artists.map<String>((artist) => artist.name).toList(),
                    albumArtPath: widget.trackItem.album.albumArtPath,
                  ),
                ),
              ),

              // Show action buttons only when hovered
              if (effectiveHover)
                Padding(
                  padding: const .only(right: 8.0),
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
