import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/* Widget Architecture:
This widget is a desktop-class data table optimized for Flutter's scrollable Sliver ecosystem. It manages the entire
lifecycle of a resizable grid—from data mapping to cascading math—within a high-performance, monolithic structure.

1. The API & Structure ([SliverResizableTable<T>])
    The primary entry point. It bridges generic data models ([items]) with the physical Sliver architecture. It manages
    the high-level viewport structure, including the sticky header alignment and the [SliverFixedExtentList] for O(1)
    scroll performance.

2. Isolated Visual Components (State Optimization)
    Private stateful wrappers used to shield the heavy rendering pipeline from frequent rebuilds:
    - [_GenericTableRowInteractiveWrapper]: Isolates hover and selection colors so that interacting with one row does
      not trigger a rebuild of the entire table.
    - [_InteractiveHeaderContent]: Separates high-frequency drag-and-hover pointer events from expensive
      [BackdropFilter] (blur) layers and layout pass triggers.

3. The Math & Placement Engine
    The "Logic Layer" that operates behind the UI:
    - [_ResizableTableLayoutController]: A decoupled math core that handles width distribution, min-width clamping, and
      cascading resize logic independently of the widget tree.
    - [_TableHeaderLayoutDelegate]: A custom layout delegate for precise pixel positioning of header labels and
      the resize "grab-handles."

The Golden Rule of this Architecture: The Controller manages the logic, the Slivers ensure scroll performance, and the
Private Wrappers isolate the hover state to maximize performance. */

/// An optimized resizable data table designed for the Sliver ecosystem.
///
/// [SliverResizableTable] is the primary interface for building desktop-class data grids. It maps a strongly-typed
/// data list ([items]) to a set of column configurations ([columns]), automatically handling complex interactions
/// like cascading column resizing, row selection, and context menus.
///
/// Because it is a Sliver, it must be placed inside a viewport like a [CustomScrollView].
///
/// Example usage:
/// ```dart
/// SliverResizableTable<Employee>(
///   items: myEmployees,
///   isAdaptive: true,
///   columns: [
///     TableColumn(
///       id: 'id',
///       label: 'ID',
///       width: 80, // Fixed width
///       cellBuilder: (context, emp, index) => Text(emp.id),
///     ),
///     TableColumn(
///       id: 'name',
///       label: 'Name',
///       flex: 1,  // Takes remaining space
///       cellBuilder: (context, emp, index) => Text(emp.name),
///     ),
///   ],
/// )
/// ```
class SliverResizableTable<T> extends StatefulWidget {
  const SliverResizableTable({
    super.key,
    required this.items,
    required this.columns,
    this.selectedIndices = const {},
    this.onColumnsResized,
    this.onHeaderRightClick,
    this.onRowClick,
    this.onRowDoubleClick,
    this.onRowRightClick,
    this.headerHeight = 40.0,
    this.headerDecoration,
    this.headerTextStyle,
    this.rowHeight = 50.0,
    this.tablePadding = const EdgeInsets.only(left: 16, top: 8, bottom: 16, right: 16),
    this.cellPadding = const EdgeInsets.symmetric(horizontal: 16),
    this.isAdaptive = false,
    this.blurSigma = 10,
  });

  /// The strongly-typed data set that populates the table.
  ///
  /// Each element corresponds to a single horizontal row. The type [T] is passed
  /// down to the [cellBuilder] in your column configurations to ensure type safety
  /// when rendering data.
  final List<T> items;

  /// The structural blueprint for the table's vertical layout.
  ///
  /// This list dictates the number of columns, their header labels, and their
  /// sizing rules (fixed [width] vs. proportional [flex]).
  final List<TableColumn<T>> columns;

  /// A collection tracking which rows are currently highlighted or selected by the user.
  final Set<int> selectedIndices;

  /// Callback fired when the user finishes dragging a column resizer.
  /// Intended for when you want to save each columns width so it doesn't get reverted every rebuild
  final void Function(List<double> newWidths)? onColumnsResized;

  /// Callback fired when a user right-clicks the header.
  final void Function(Offset globalPosition)? onHeaderRightClick;

  /// Callback fired when a user left-clicks a row.
  /// Provides keyboard modifier states for multi-selection logic.
  final void Function(int index, {required bool isCtrl, required bool isShift})? onRowClick;

  /// Callback fired when a user double clicks a row.
  final void Function(int index)? onRowDoubleClick;

  /// Callback fired when a user right-clicks a row.
  final void Function(int index, Offset globalPosition)? onRowRightClick;

  /// The height of the header row. Defaults to 40.0.
  final double headerHeight;

  /// Decoration applied to the header row container.
  ///
  /// If null, a default bottom border using the theme's divider color is applied.
  final BoxDecoration? headerDecoration;

  /// Text style applied to the header labels.
  ///
  /// If null, a default style using the theme's body medium color is applied.
  final TextStyle? headerTextStyle;

  /// The height of each row, required for SliverFixedExtentList. Defaults to 50.0.
  final double rowHeight;

  /// The outer padding applied to the table's layout footprint.
  ///
  /// This padding dictates how the table sits within its parent viewport:
  /// * The horizontal values (`left` and `right`) indent both the sticky header and the data rows.
  /// * The vertical values (`top` and `bottom`) are applied **exclusively** to the scrollable data rows, leaving the
  ///   sticky header flush against the top edge. If you want the header to be taller, use the [headerHeight].
  final EdgeInsets tablePadding;

  /// The internal padding applied to the contents of every individual cell.
  ///
  /// This is applied identically to both the header labels and the data rows
  /// to guarantee perfect vertical alignment between a column's title and its data.
  ///
  /// **Warning:** Because the table relies on a highly optimized, strict [rowHeight], it is strongly recommended to
  /// only use horizontal padding (e.g., `EdgeInsets.symmetric(horizontal: 16)`). Excessive vertical padding will
  /// cause cell content to clip.
  final EdgeInsets cellPadding;

  /// Determines if the table header should use a frosted glass blur and the data rows transparent.
  final bool isAdaptive;

  /// The blur intensity when apdaptive mode isAdaptive == true
  final double blurSigma;

  @override
  State<SliverResizableTable<T>> createState() => _SliverResizableTableState<T>();
}

class _SliverResizableTableState<T> extends State<SliverResizableTable<T>> {
  final _ResizableTableLayoutController _controller = _ResizableTableLayoutController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visibleColumns = widget.columns.where((c) => c.isVisible).toList();

    return SliverLayoutBuilder(
      builder: (context, constraints) {
        // Use crossAxisExtent for sliver width constraints
        final availableWidth = constraints.crossAxisExtent - widget.tablePadding.horizontal;
        _controller.init(visibleColumns, availableWidth);

        return AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return SliverMainAxisGroup(
              slivers: [
                // -- STICKY HEADER --
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _StickyTableHeaderDelegate(
                    height: widget.headerHeight,
                    child: _buildHeader(context, visibleColumns),
                  ),
                ),
                // -- SCROLLABLE DATA ROWS --
                SliverPadding(
                  padding: widget.tablePadding,
                  sliver: SliverFixedExtentList.builder(
                    itemExtent: widget.rowHeight,
                    itemCount: widget.items.length,
                    itemBuilder: (context, index) {
                      final item = widget.items[index];
                      final isSelected = widget.selectedIndices.contains(index);
                      final isPreviousSelected = widget.selectedIndices.contains(index - 1);
                      final isNextSelected = widget.selectedIndices.contains(index + 1);

                      return _GenericTableRowInteractiveWrapper(
                        isSelected: isSelected,
                        isPreviousSelected: isPreviousSelected,
                        isNextSelected: isNextSelected,
                        height: widget.rowHeight,
                        onPointerDown: (event) {
                          if (event.buttons == kPrimaryMouseButton) {
                            final isCtrl =
                                HardwareKeyboard.instance.isControlPressed || HardwareKeyboard.instance.isMetaPressed;
                            final isShift = HardwareKeyboard.instance.isShiftPressed;
                            widget.onRowClick?.call(index, isCtrl: isCtrl, isShift: isShift);
                          } else if (event.buttons == kSecondaryMouseButton) {
                            widget.onRowRightClick?.call(index, event.position);
                          }
                        },
                        onDoubleTap: () => widget.onRowDoubleClick?.call(index),
                        child: Row(
                          children: [
                            for (int i = 0; i < visibleColumns.length; i++)
                              SizedBox(
                                width: _controller.widths[i],
                                child: Padding(
                                  padding: widget.cellPadding,
                                  child: Align(
                                    alignment: visibleColumns[i].alignment,
                                    child: visibleColumns[i].cellBuilder(context, item, index),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, List<TableColumn<T>> visibleColumns) {
    final theme = Theme.of(context);
    final defaultBorderColor = theme.dividerTheme.color ?? theme.colorScheme.outlineVariant;

    Widget headerContent = Container(
      color: widget.isAdaptive ? theme.colorScheme.surfaceContainer.withValues(alpha: 0.6) : theme.colorScheme.surface,
      child: Padding(
        padding: EdgeInsets.only(left: widget.tablePadding.left, right: widget.tablePadding.right),
        child: Container(
          height: widget.headerHeight,
          decoration:
              widget.headerDecoration ??
              BoxDecoration(
                border: Border(bottom: BorderSide(color: defaultBorderColor)),
              ),
          child: _InteractiveHeaderContent(
            columns: visibleColumns,
            widths: _controller.widths,
            cellPadding: widget.cellPadding,
            headerTextStyle: widget.headerTextStyle,
            onHeaderRightClick: widget.onHeaderRightClick,
            onDragUpdate: _controller.updateColumnWidth,
            onDragEnd: () => widget.onColumnsResized?.call(_controller.widths),
          ),
        ),
      ),
    );

    if (widget.isAdaptive) {
      return ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: widget.blurSigma, sigmaY: widget.blurSigma, tileMode: TileMode.mirror),
          child: headerContent,
        ),
      );
    }

    return headerContent;
  }
}

/// A configuration object defining the sizing and layout rules for a single column.
class TableColumn<T> {
  /// Unique identifier, useful for saving "hidden/visible" user preferences.
  final String id;

  /// The text label displayed in the column header.
  final String label;

  /// The absolute minimum width in pixels this column can be resized to.
  final double minWidth;

  /// The fixed width in pixels.
  final double? width;

  /// The flex factor for dynamic sizing.
  final double? flex;

  /// The alignment of the text within the header cell. Defaults to [Alignment.centerLeft].
  final Alignment alignment;

  /// Determines if the layout should calculate and render this column.
  final bool isVisible;

  /// Callback fired when the user left-clicks this column's header.
  final VoidCallback? onHeaderClick;

  /// The function that builds the UI for a single cell in this column.
  final Widget Function(BuildContext context, T item, int index) cellBuilder;

  const TableColumn({
    required this.id,
    required this.label,
    this.minWidth = 50.0,
    this.width,
    this.flex,
    this.alignment = Alignment.centerLeft,
    this.isVisible = true,
    this.onHeaderClick,
    required this.cellBuilder,
  }) : assert(
         (width != null || flex != null) && !(width != null && flex != null),
         'A TableColumn must provide exactly one of either width or flex.',
       );

  TableColumn<T> copyWith({bool? isVisible, double? width, double? flex}) {
    return TableColumn<T>(
      id: id,
      label: label,
      minWidth: minWidth,
      width: width ?? this.width,
      flex: flex ?? this.flex,
      alignment: alignment,
      isVisible: isVisible ?? this.isVisible,
      cellBuilder: cellBuilder,
    );
  }
}

/// A purely visual wrapper that handles hover/selection colors and raw pointer events.
class _GenericTableRowInteractiveWrapper extends StatefulWidget {
  final bool isSelected;
  final bool isPreviousSelected;
  final bool isNextSelected;
  final Widget child;
  final double height;
  final void Function(PointerDownEvent) onPointerDown;
  final VoidCallback? onDoubleTap;

  const _GenericTableRowInteractiveWrapper({
    required this.isSelected,
    required this.isPreviousSelected,
    required this.isNextSelected,
    required this.child,
    required this.height,
    required this.onPointerDown,
    this.onDoubleTap,
  });

  @override
  State<_GenericTableRowInteractiveWrapper> createState() => _GenericTableRowInteractiveWrapperState();
}

class _GenericTableRowInteractiveWrapperState extends State<_GenericTableRowInteractiveWrapper> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: widget.onPointerDown,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onDoubleTap: widget.onDoubleTap,
          child: Container(
            height: widget.height,
            decoration: BoxDecoration(
              borderRadius: !widget.isSelected
                  ? BorderRadius.circular(6)
                  : BorderRadius.vertical(
                      top: widget.isPreviousSelected ? Radius.zero : const Radius.circular(6),
                      bottom: widget.isNextSelected ? Radius.zero : const Radius.circular(6),
                    ),
              color: _isHovered
                  ? theme.colorScheme.primary.withValues(alpha: 0.05)
                  : widget.isSelected
                  ? theme.colorScheme.primary.withValues(alpha: 0.12)
                  : Colors.transparent,
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: widget.isSelected && _isHovered
                    ? theme.colorScheme.primary.withValues(alpha: 0.1)
                    : Colors.transparent,
              ),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Abstracted to handle the header's hover state separately
class _InteractiveHeaderContent extends StatefulWidget {
  final List<TableColumn> columns;
  final List<double> widths;
  final EdgeInsets cellPadding;
  final TextStyle? headerTextStyle;
  final void Function(Offset)? onHeaderRightClick;
  final void Function(int, double) onDragUpdate;
  final VoidCallback onDragEnd;

  const _InteractiveHeaderContent({
    required this.columns,
    required this.widths,
    required this.cellPadding,
    this.headerTextStyle,
    this.onHeaderRightClick,
    required this.onDragUpdate,
    required this.onDragEnd,
  });

  @override
  State<_InteractiveHeaderContent> createState() => _InteractiveHeaderContentState();
}

class _InteractiveHeaderContentState extends State<_InteractiveHeaderContent> {
  bool _isHeaderHovered = false;
  int? _hoveredHandleIndex;
  int? _activeDragHandleIndex;

  Color _getHandleColor(BuildContext context, int index) {
    final baseColor = Theme.of(context).colorScheme.onSurface;

    if (_activeDragHandleIndex != null) {
      return _activeDragHandleIndex == index ? baseColor : baseColor.withValues(alpha: 0.25);
    }

    if (!_isHeaderHovered) return Colors.transparent;

    return _hoveredHandleIndex == index ? baseColor.withValues(alpha: 0.54) : baseColor.withValues(alpha: 0.25);
  }

  void _handlePointerHover(PointerHoverEvent event) {
    final index = _findHandleIndex(event.localPosition.dx);
    if (index != _hoveredHandleIndex) {
      setState(() => _hoveredHandleIndex = index);
    }
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (event.buttons == kSecondaryMouseButton) {
      widget.onHeaderRightClick?.call(event.position);
      return;
    }

    final index = _findHandleIndex(event.localPosition.dx);
    if (index != null) {
      setState(() => _activeDragHandleIndex = index);
    }
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (_activeDragHandleIndex != null) {
      widget.onDragUpdate(_activeDragHandleIndex!, event.delta.dx);
    } else {
      final index = _findHandleIndex(event.localPosition.dx);
      if (index != _hoveredHandleIndex) {
        setState(() => _hoveredHandleIndex = index);
      }
    }
  }

  void _handlePointerUp(PointerEvent event) {
    if (_activeDragHandleIndex != null) {
      setState(() => _activeDragHandleIndex = null);
      widget.onDragEnd();
    }
  }

  int? _findHandleIndex(double xPosition) {
    double currentX = 0;
    for (int i = 0; i < widget.widths.length - 1; i++) {
      currentX += widget.widths[i];
      if ((xPosition - currentX).abs() < 8) {
        return i;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultTextColor = theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7) ?? Colors.grey;

    return Listener(
      onPointerDown: _handlePointerDown,
      onPointerMove: _handlePointerMove,
      onPointerUp: _handlePointerUp,
      onPointerCancel: _handlePointerUp,
      onPointerHover: _handlePointerHover,
      behavior: HitTestBehavior.translucent,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHeaderHovered = true),
        onExit: (_) => setState(() {
          _isHeaderHovered = false;
          _hoveredHandleIndex = null;
        }),
        cursor: _hoveredHandleIndex != null || _activeDragHandleIndex != null
            ? SystemMouseCursors.resizeColumn
            : SystemMouseCursors.basic,
        child: CustomMultiChildLayout(
          delegate: _TableHeaderLayoutDelegate(widths: widget.widths),
          children: [
            for (int i = 0; i < widget.columns.length; i++)
              LayoutId(
                id: 'label_$i',
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: widget.columns[i].onHeaderClick,
                  child: Container(
                    padding: widget.cellPadding,
                    alignment: widget.columns[i].alignment,
                    child: Text(
                      widget.columns[i].label,
                      style:
                          widget.headerTextStyle ??
                          TextStyle(color: defaultTextColor, fontSize: 13, fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            for (int i = 0; i < widget.columns.length - 1; i++)
              LayoutId(
                id: 'handle_$i',
                child: Container(color: _getHandleColor(context, i)),
              ),
          ],
        ),
      ),
    );
  }
}

// The delegate class required for the sticky sliver header
class _StickyTableHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double height;
  final Widget child;

  _StickyTableHeaderDelegate({required this.height, required this.child});

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => child;

  @override
  bool shouldRebuild(covariant _StickyTableHeaderDelegate oldDelegate) => true;
}

class _TableHeaderLayoutDelegate extends MultiChildLayoutDelegate {
  final List<double> widths;

  _TableHeaderLayoutDelegate({required this.widths});

  @override
  void performLayout(Size size) {
    double currentX = 0;

    for (int i = 0; i < widths.length; i++) {
      final width = widths[i];
      if (hasChild('label_$i')) {
        layoutChild('label_$i', BoxConstraints.tightFor(width: width, height: size.height));
        positionChild('label_$i', Offset(currentX, 0));
      }
      currentX += width;
    }

    currentX = 0;
    for (int i = 0; i < widths.length - 1; i++) {
      currentX += widths[i];
      if (hasChild('handle_$i')) {
        layoutChild('handle_$i', BoxConstraints.tightFor(width: 1, height: size.height * 0.5));
        positionChild('handle_$i', Offset(currentX, size.height * 0.25));
      }
    }
  }

  @override
  bool shouldRelayout(_TableHeaderLayoutDelegate oldDelegate) => true;
}

/// An internal controller responsible for calculating and distributing column widths.
class _ResizableTableLayoutController extends ChangeNotifier {
  List<double> _widths = [];
  List<TableColumn> _columns = [];
  double _totalWidth = 0;

  List<double> get widths => _widths;

  void init(List<TableColumn> columns, double maxWidth) {
    bool columnsChanged = _columns.length != columns.length;
    if (!columnsChanged) {
      for (int i = 0; i < columns.length; i++) {
        if (_columns[i].width != columns[i].width ||
            _columns[i].flex != columns[i].flex ||
            _columns[i].minWidth != columns[i].minWidth) {
          columnsChanged = true;
          break;
        }
      }
    }

    if (!columnsChanged && _totalWidth == maxWidth) return;

    _columns = columns;
    _totalWidth = maxWidth;
    _calculateInitialWidths();
  }

  void _calculateInitialWidths() {
    _widths = List.filled(_columns.length, 0.0);
    double availableSpace = _totalWidth;

    List<int> flexibleIndices = [];
    for (int i = 0; i < _columns.length; i++) {
      if (_columns[i].width != null) {
        _widths[i] = _columns[i].width!;
        availableSpace -= _widths[i];
      } else if (_columns[i].flex != null) {
        flexibleIndices.add(i);
      } else {
        _widths[i] = _columns[i].minWidth;
        availableSpace -= _widths[i];
      }
    }

    bool recalculate;
    do {
      recalculate = false;
      double currentTotalFlex = 0;

      for (int i in flexibleIndices) {
        currentTotalFlex += _columns[i].flex!;
      }

      if (currentTotalFlex <= 0) break;

      List<int> remainingFlexibleIndices = [];

      for (int i in flexibleIndices) {
        double share = (_columns[i].flex! / currentTotalFlex) * availableSpace;

        if (share <= _columns[i].minWidth) {
          _widths[i] = _columns[i].minWidth;
          availableSpace -= _columns[i].minWidth;
          availableSpace = math.max(0.0, availableSpace);
          recalculate = true;
        } else {
          remainingFlexibleIndices.add(i);
        }
      }

      if (recalculate) {
        flexibleIndices = remainingFlexibleIndices;
      } else {
        for (int i in flexibleIndices) {
          _widths[i] = (_columns[i].flex! / currentTotalFlex) * availableSpace;
        }
      }
    } while (recalculate && flexibleIndices.isNotEmpty);

    notifyListeners();
  }

  void updateColumnWidth(int handleIndex, double delta) {
    if (delta == 0) return;

    final bool isGrowingRight = delta > 0;
    final int growIdx = isGrowingRight ? handleIndex : handleIndex + 1;
    final List<int> shrinkIndices = [];

    if (isGrowingRight) {
      for (int i = handleIndex + 1; i < _widths.length; i++) shrinkIndices.add(i);
    } else {
      for (int i = handleIndex; i >= 0; i--) shrinkIndices.add(i);
    }

    double available = 0;
    for (int i in shrinkIndices) {
      available += (_widths[i] - _columns[i].minWidth);
    }

    double actualDelta = math.min(delta.abs(), available);
    if (actualDelta <= 0) return;

    List<double> newWidths = List.from(_widths);
    newWidths[growIdx] += actualDelta;

    double remainingShrink = actualDelta;
    for (int i in shrinkIndices) {
      if (remainingShrink <= 0) break;
      double canShrink = newWidths[i] - _columns[i].minWidth;
      double shrinkAmt = math.min(remainingShrink, canShrink);
      newWidths[i] -= shrinkAmt;
      remainingShrink -= shrinkAmt;
    }

    _widths = newWidths;
    notifyListeners();
  }
}
