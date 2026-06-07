import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nordplayer/theming/icon-sets/app_icon_set.dart';
import 'package:nordplayer/widgets/app_icon.dart';

class StackItem {
  final String key;
  final String imageUrl;
  final bool isExiting;
  final bool isIntroducing;
  final double? lastActiveLeftOffset;

  StackItem({
    required this.key,
    required this.imageUrl,
    this.isExiting = false,
    this.isIntroducing = false,
    this.lastActiveLeftOffset,
  });

  StackItem copyWith({
    bool? isExiting,
    bool? isIntroducing,
    double? lastActiveLeftOffset,
  }) {
    return StackItem(
      key: key,
      imageUrl: imageUrl,
      isExiting: isExiting ?? this.isExiting,
      isIntroducing: isIntroducing ?? this.isIntroducing,
      lastActiveLeftOffset: lastActiveLeftOffset ?? this.lastActiveLeftOffset,
    );
  }
}

class AlbumArtStack extends ConsumerStatefulWidget {
  final List<String> imageUrls;
  final double? size;
  final int maxLayers;
  final double sliceWidth;

  const AlbumArtStack({
    super.key,
    required this.imageUrls,
    this.size, // Defaults to null for dynamic scaling
    this.maxLayers = 5,
    this.sliceWidth = 16.0,
  });

  @override
  ConsumerState<AlbumArtStack> createState() => _AlbumArtStackState();
}

class _AlbumArtStackState extends ConsumerState<AlbumArtStack> {
  List<StackItem> _items = [];

  @override
  void initState() {
    super.initState();
    _initItems(widget.imageUrls);
  }

  @override
  void didUpdateWidget(covariant AlbumArtStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(widget.imageUrls, oldWidget.imageUrls)) {
      _updateItems(widget.imageUrls);
    }
  }

  void _initItems(List<String> urls) {
    final int count = urls.isEmpty ? 1 : math.min(urls.length, widget.maxLayers);
    final activeUrls = urls.take(count).toList();
    _items = activeUrls.asMap().entries.map((entry) {
      return StackItem(
        key: '${entry.value}_${entry.key}_${DateTime.now().microsecondsSinceEpoch}_${math.Random().nextInt(10000)}',
        imageUrl: entry.value,
        isExiting: false,
        isIntroducing: false,
      );
    }).toList();
  }

  void _updateItems(List<String> newUrls) {
    final int count = newUrls.isEmpty ? 1 : math.min(newUrls.length, widget.maxLayers);
    final activeUrls = newUrls.take(count).toList();
    
    final List<StackItem> updatedItems = [];
    final List<StackItem> exitingItems = [];

    // Mark current items as candidates for matching
    final List<StackItem> candidates = _items.where((item) => !item.isExiting).toList();

    for (final url in activeUrls) {
      // Find the first candidate that matches the URL
      final matchIndex = candidates.indexWhere((c) => c.imageUrl == url);
      if (matchIndex != -1) {
        // Found a match! Reuse the item (keeps the key and state!)
        final matchedItem = candidates.removeAt(matchIndex);
        updatedItems.add(matchedItem);
      } else {
        // No match found, this is a new image URL
        updatedItems.add(StackItem(
          key: '${url}_${DateTime.now().microsecondsSinceEpoch}_${math.Random().nextInt(10000)}',
          imageUrl: url,
          isExiting: false,
          isIntroducing: true, // Introduce smoothly!
        ));
      }
    }

    // Any remaining candidates are now exiting
    for (final remaining in candidates) {
      final oldActiveIndex = _items.where((item) => !item.isExiting).toList().indexOf(remaining);
      final double lastOffset = oldActiveIndex != -1 ? oldActiveIndex * widget.sliceWidth : 0.0;

      exitingItems.add(remaining.copyWith(
        isExiting: true,
        lastActiveLeftOffset: lastOffset,
      ));
    }

    setState(() {
      _items = [...updatedItems, ...exitingItems];
    });

    // Schedule a post-frame callback to trigger the transition of introducing items
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final hasIntroducing = _items.any((item) => item.isIntroducing);
        if (hasIntroducing) {
          setState(() {
            _items = _items.map((item) {
              if (item.isIntroducing) {
                return item.copyWith(isIntroducing: false);
              }
              return item;
            }).toList();
          });
        }
      }
    });

    // Clean up exiting items after the animation completes
    for (final exiting in exitingItems) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _items.removeWhere((item) => item.key == exiting.key);
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appIconSet = ref.watch(appIconProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate layer count and the extra width they take up based on active items only
        final int count = widget.imageUrls.isEmpty ? 1 : math.min(widget.imageUrls.length, widget.maxLayers);
        final double extraWidth = (count - 1) * widget.sliceWidth;

        // Find the largest square that fits in BOTH the height and width limits.
        double squareSize = widget.size ?? math.min(constraints.maxHeight, constraints.maxWidth - extraWidth);
        if (squareSize < 0) squareSize = 0;

        final double totalWidth = squareSize + extraWidth;

        Widget child;

        // -- EMPTY STATE --
        if (widget.imageUrls.isEmpty) {
          child = Center(
            key: const ValueKey('empty_state'),
            child: Container(
              width: squareSize,
              height: squareSize,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 6,
                    offset: const Offset(-1, 1),
                  ),
                ],
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [theme.colorScheme.primary, theme.colorScheme.tertiary],
                ),
              ),
              child: AppIcon(
                Icons.queue_music,
                color: theme.colorScheme.onPrimary,
                size: squareSize * 0.5, // Dynamically scale the icon
              ),
            ),
          );
        } else {
          // -- POPULATED STATE --
          final activeItems = _items.where((item) => !item.isExiting).toList();

          // Prepare list of items to render, sorted to maintain correct paint order:
          // Bottom-most (rendered first): items with larger depth (back of stack)
          // Top-most (rendered last): items with smaller depth (front of stack)
          // Exiting items maintain their last active depth, but paint on top of active items at the same depth
          final itemsToRender = List<StackItem>.from(_items);
          itemsToRender.sort((a, b) {
            final double depthA = a.isExiting
                ? (a.lastActiveLeftOffset ?? 0.0) / widget.sliceWidth
                : activeItems.indexOf(a).toDouble();
            final double depthB = b.isExiting
                ? (b.lastActiveLeftOffset ?? 0.0) / widget.sliceWidth
                : activeItems.indexOf(b).toDouble();

            if (depthA != depthB) {
              return depthB.compareTo(depthA);
            }

            // At the same depth, paint exiting items on top of active items
            if (a.isExiting && !b.isExiting) return 1;
            if (!a.isExiting && b.isExiting) return -1;
            return 0;
          });

          child = Center(
            key: const ValueKey('populated_state'),
            child: SizedBox(
              width: totalWidth,
              height: squareSize,
              child: Stack(
                clipBehavior: Clip.none,
                children: itemsToRender.map((item) {
                  final activeIndex = activeItems.indexOf(item);
                  
                  // Calculate layout parameters based on status
                  final double leftOffset;
                  final double opacity;
                  final double scale;

                  if (item.isExiting) {
                    leftOffset = item.lastActiveLeftOffset == 0.0
                        ? -squareSize * 0.4
                        : (item.lastActiveLeftOffset ?? 0.0) + widget.sliceWidth;
                    opacity = 0.0;
                    scale = 0.8;
                  } else if (item.isIntroducing) {
                    leftOffset = activeIndex == 0
                        ? -squareSize * 0.4
                        : activeIndex * widget.sliceWidth;
                    opacity = 0.0;
                    scale = activeIndex == 0 ? 0.9 : 1.0;
                  } else {
                    leftOffset = activeIndex * widget.sliceWidth;
                    opacity = 1.0;
                    scale = 1.0;
                  }

                  // Parse path whether it's a raw path or a file:// URI
                  File file;
                  if (item.imageUrl.startsWith('file://')) {
                    file = File(Uri.parse(item.imageUrl).toFilePath());
                  } else {
                    file = File(item.imageUrl);
                  }

                  final hasImage = item.imageUrl.isNotEmpty && file.existsSync();

                  return AnimatedPositioned(
                    key: ValueKey(item.key),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutCubic,
                    top: 0,
                    bottom: 0,
                    left: leftOffset,
                    width: squareSize,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOutCubic,
                      opacity: opacity,
                      child: AnimatedScale(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeOutCubic,
                        scale: scale,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 8,
                                offset: const Offset(-2, 2),
                              ),
                            ],
                            image: hasImage ? DecorationImage(image: FileImage(file), fit: BoxFit.cover) : null,
                            gradient: !hasImage
                                ? LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [theme.colorScheme.primary, theme.colorScheme.tertiary],
                                  )
                                : null,
                          ),
                          child: !hasImage
                              ? AppIcon(appIconSet.tracks, color: theme.colorScheme.onPrimary, size: squareSize * 0.3)
                              : null,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          );
        }

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: child,
        );
      },
    );
  }
}