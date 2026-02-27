import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// A configuration object defining the sizing and layout rules for a single column
/// within a [SliverResizableTableLayout].
///
/// A column must be defined as either fixed-width (using [width]) or flexible
/// (using [flex]), but not both.
class TableColumn {
  /// The text label displayed in the column header.
  final String label;

  /// The absolute minimum width in pixels this column can be resized to.
  ///
  /// During a cascading resize, if a column hits this limit, the layout will
  /// attempt to shrink the next available neighbor. Defaults to 50.0.
  final double minWidth;

  /// The fixed width in pixels.
  ///
  /// If provided, this column will maintain this exact width unless manually
  /// resized by the user. Mutually exclusive with [flex].
  final double? width;

  /// The flex factor for dynamic sizing.
  ///
  /// If provided, this column will take up a proportional amount of the
  /// remaining space after all fixed-width columns have been allocated.
  /// Mutually exclusive with [width].
  final double? flex;

  /// The alignment of the text within the header cell. Defaults to [Alignment.centerLeft].
  final Alignment alignment;

  const TableColumn({
    required this.label,
    this.minWidth = 50.0,
    this.width,
    this.flex,
    this.alignment = Alignment.centerLeft,
  }) : assert(
         (width != null || flex != null) && !(width != null && flex != null),
         'A TableColumn must provide exactly one of either width or flex.',
       );
}

/// A resizable table layout widget.
///
/// This widget provides a desktop-class table experience similar to Spotify or Excel.
/// It supports a mix of fixed and flexible columns, and features "cascading" resize
/// logic—where shrinking a column past its minimum width will push adjacent columns.
class SliverResizableTableLayout extends StatefulWidget {
  /// The list of column configurations defining the table structure.
  final List<TableColumn> columns;

  /// The total number of rows to render.
  final int itemCount;

  /// A builder function responsible for rendering a single row of data.
  ///
  /// The [widths] parameter provides the current calculated pixel width for each
  /// column. The [cellPadding] matches the header's internal spacing.
  ///
  /// To maintain perfect alignment:
  /// 1. Wrap cell content in `SizedBox(width: widths[i])`.
  /// 2. Apply [cellPadding] inside the cell to match header text positioning.
  final Widget Function(
    BuildContext context,
    int index,
    List<double> widths,
    EdgeInsets cellPadding,
  )
  rowBuilder;

  /// The height of the header row. Defaults to 40.0.
  final double headerHeight;

  /// An optional scroll controller for the internal [ListView].
  final ScrollController? scrollController;

  /// Decoration applied to the header row container.
  ///
  /// If null, a default bottom border using the theme's divider color is applied.
  final BoxDecoration? headerDecoration;

  /// Text style applied to the header labels.
  ///
  /// If null, a default style using the theme's body medium color is applied.
  final TextStyle? headerTextStyle;

  /// The outer padding for the entire table component.
  ///
  /// This padding indents both the header's bottom border and the scrollable
  /// list area. The layout logic automatically subtracts this from the total
  /// width to prevent column overflow.
  ///
  /// Defaults to `EdgeInsets.only(left: 16, top: 8, bottom: 16, right: 16)`.
  final EdgeInsets padding;

  /// The internal horizontal padding for header labels and row cells.
  ///
  /// This is the "source of truth" for alignment. It is passed to [rowBuilder]
  /// so that row content starts at the exact same horizontal offset as the
  /// header text, regardless of column resizing.
  ///
  /// Defaults to `EdgeInsets.symmetric(horizontal: 16)`.
  final EdgeInsets cellPadding;

  const SliverResizableTableLayout({
    super.key,
    required this.columns,
    required this.itemCount,
    required this.rowBuilder,
    this.headerHeight = 40.0,
    this.scrollController,
    this.headerDecoration,
    this.headerTextStyle,
    this.padding = const EdgeInsets.only(
      left: 16,
      top: 8,
      bottom: 16,
      right: 16,
    ),
    this.cellPadding = const EdgeInsets.symmetric(horizontal: 16),
  });

  @override
  State<SliverResizableTableLayout> createState() => _SliverResizableTableLayoutState();
}

class _SliverResizableTableLayoutState extends State<SliverResizableTableLayout> {
  final FlexibleTableLayoutController _controller =
      FlexibleTableLayoutController();

  bool _isHeaderHovered = false;
  int? _hoveredHandleIndex;
  int? _activeDragHandleIndex;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // REFACTOR: Converted LayoutBuilder to SliverLayoutBuilder for direct CustomScrollView usage
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        // Use crossAxisExtent for sliver width constraints
        final availableWidth =
            constraints.crossAxisExtent - widget.padding.horizontal;
        _controller.init(widget.columns, availableWidth);

        return AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            // REFACTOR: Replaced Column with SliverMainAxisGroup
            return SliverMainAxisGroup(
              slivers: [
                // 1. STICKY HEADER
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _StickyTableHeaderDelegate(
                    height: widget.headerHeight,
                    child: _buildHeader(context),
                  ),
                ),
                // 2. SCROLLABLE DATA ROWS
                SliverPadding(
                  padding: widget.padding,
                  sliver: SliverList.builder(
                    itemCount: widget.itemCount,
                    itemBuilder: (context, index) {
                      return widget.rowBuilder(
                        context,
                        index,
                        _controller.widths,
                        widget.cellPadding,
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

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final defaultBorderColor =
        theme.dividerTheme.color ?? theme.colorScheme.outlineVariant;

    final defaultTextColor =
        theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7) ??
        Colors.grey;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHeaderHovered = true),
      onExit: (_) => setState(() {
        _isHeaderHovered = false;
        _hoveredHandleIndex = null;
      }),
      // REFACTOR: Added solid background container so scrolling tracks don't bleed through
      child: Container(
        color: theme.colorScheme.surface,
        child: Padding(
          padding: EdgeInsets.only(
            left: widget.padding.left,
            right: widget.padding.right,
          ),
          child: Container(
            height: widget.headerHeight,
            decoration:
                widget.headerDecoration ??
                BoxDecoration(
                  border: Border(bottom: BorderSide(color: defaultBorderColor)),
                ),
            child: Listener(
              onPointerDown: _handlePointerDown,
              onPointerMove: _handlePointerMove,
              onPointerUp: _handlePointerUp,
              onPointerCancel: _handlePointerUp,
              onPointerHover: _handlePointerHover,
              behavior: HitTestBehavior.translucent,
              child: MouseRegion(
                cursor:
                    _hoveredHandleIndex != null ||
                        _activeDragHandleIndex != null
                    ? SystemMouseCursors.resizeColumn
                    : SystemMouseCursors.basic,
                child: CustomMultiChildLayout(
                  delegate: _TableHeaderLayoutDelegate(
                    widths: _controller.widths,
                  ),
                  children: [
                    for (int i = 0; i < widget.columns.length; i++)
                      LayoutId(
                        id: 'label_$i',
                        child: Container(
                          padding: widget.cellPadding,
                          alignment: widget.columns[i].alignment,
                          child: Text(
                            widget.columns[i].label,
                            style:
                                widget.headerTextStyle ??
                                TextStyle(
                                  color: defaultTextColor,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
            ),
          ),
        ),
      ),
    );
  }

  Color _getHandleColor(BuildContext context, int index) {
    final baseColor = Theme.of(context).colorScheme.onSurface;

    if (_activeDragHandleIndex != null) {
      if (_activeDragHandleIndex == index) {
        return baseColor;
      } else {
        return baseColor.withValues(alpha: 0.25);
      }
    }

    if (!_isHeaderHovered) {
      return Colors.transparent;
    }

    if (_hoveredHandleIndex == index) {
      return baseColor.withValues(alpha: 0.54);
    }

    return baseColor.withValues(alpha: 0.25);
  }

  void _handlePointerHover(PointerHoverEvent event) {
    final index = _findHandleIndex(event.localPosition.dx);
    if (index != _hoveredHandleIndex) {
      setState(() => _hoveredHandleIndex = index);
    }
  }

  void _handlePointerDown(PointerDownEvent event) {
    final index = _findHandleIndex(event.localPosition.dx);
    if (index != null) {
      setState(() => _activeDragHandleIndex = index);
    }
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (_activeDragHandleIndex != null) {
      _controller.updateColumnWidth(_activeDragHandleIndex!, event.delta.dx);
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
    }
  }

  int? _findHandleIndex(double xPosition) {
    double currentX = 0;
    for (int i = 0; i < _controller.widths.length - 1; i++) {
      currentX += _controller.widths[i];
      if ((xPosition - currentX).abs() < 8) {
        return i;
      }
    }
    return null;
  }
}

// REFACTOR: Added the delegate class required for the sticky sliver header
/// A delegate to turn the table header into a pinned sliver.
class _StickyTableHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double height;
  final Widget child;

  _StickyTableHeaderDelegate({required this.height, required this.child});

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => child;

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
        layoutChild(
          'label_$i',
          BoxConstraints.tightFor(width: width, height: size.height),
        );
        positionChild('label_$i', Offset(currentX, 0));
      }
      currentX += width;
    }

    currentX = 0;
    for (int i = 0; i < widths.length - 1; i++) {
      currentX += widths[i];
      if (hasChild('handle_$i')) {
        layoutChild(
          'handle_$i',
          BoxConstraints.tightFor(width: 1, height: size.height * 0.5),
        );
        positionChild('handle_$i', Offset(currentX, size.height * 0.25));
      }
    }
  }

  @override
  bool shouldRelayout(_TableHeaderLayoutDelegate oldDelegate) => true;
}

/// An internal controller responsible for calculating and distributing column
/// widths based on flex ratios, constraints, and user resize interactions.
class FlexibleTableLayoutController extends ChangeNotifier {
  List<double> _widths = [];
  List<TableColumn> _columns = [];
  double _totalWidth = 0;

  /// The current calculated widths in pixels for each column.
  List<double> get widths => _widths;

  /// Initializes or updates the layout constraints.
  void init(List<TableColumn> columns, double maxWidth) {
    if (_columns == columns && _totalWidth == maxWidth) return;

    _columns = columns;
    _totalWidth = maxWidth;
    _calculateInitialWidths();
  }

  void _calculateInitialWidths() {
    double usedFixed = 0;
    double totalFlex = 0;

    for (var col in _columns) {
      if (col.width != null) usedFixed += col.width!;
      if (col.flex != null) totalFlex += col.flex!;
    }

    double availableFlex = math.max(0, _totalWidth - usedFixed);
    _widths = List.filled(_columns.length, 0.0);

    for (int i = 0; i < _columns.length; i++) {
      if (_columns[i].width != null) {
        _widths[i] = _columns[i].width!;
      } else {
        if (totalFlex > 0) {
          double share = (_columns[i].flex! / totalFlex) * availableFlex;
          _widths[i] = math.max(share, _columns[i].minWidth);
        } else {
          _widths[i] = _columns[i].minWidth;
        }
      }
    }
    notifyListeners();
  }

  /// Adjusts column widths in response to a drag event, applying a cascading
  /// shrink effect to neighboring columns if they reach their minimum width.
  void updateColumnWidth(int handleIndex, double delta) {
    if (delta == 0) return;
    List<double> newWidths = List.from(_widths);

    if (delta > 0) {
      final int growIdx = handleIndex;
      final List<int> shrinkIndices = [];
      for (int i = handleIndex + 1; i < newWidths.length; i++) {
        shrinkIndices.add(i);
      }

      double available = 0;
      for (int i in shrinkIndices) {
        available += (newWidths[i] - _columns[i].minWidth);
      }

      double actualDelta = math.min(delta, available);
      if (actualDelta <= 0) return;

      newWidths[growIdx] += actualDelta;
      double remainingShrink = actualDelta;
      for (int i in shrinkIndices) {
        if (remainingShrink <= 0) break;
        double canShrink = newWidths[i] - _columns[i].minWidth;
        double shrinkAmt = math.min(remainingShrink, canShrink);
        newWidths[i] -= shrinkAmt;
        remainingShrink -= shrinkAmt;
      }
    } else {
      final int growIdx = handleIndex + 1;
      final List<int> shrinkIndices = [];
      for (int i = handleIndex; i >= 0; i--) {
        shrinkIndices.add(i);
      }

      double available = 0;
      for (int i in shrinkIndices) {
        available += (newWidths[i] - _columns[i].minWidth);
      }

      double actualDelta = math.min(delta.abs(), available);
      if (actualDelta <= 0) return;

      newWidths[growIdx] += actualDelta;
      double remainingShrink = actualDelta;
      for (int i in shrinkIndices) {
        if (remainingShrink <= 0) break;
        double canShrink = newWidths[i] - _columns[i].minWidth;
        double shrinkAmt = math.min(remainingShrink, canShrink);
        newWidths[i] -= shrinkAmt;
        remainingShrink -= shrinkAmt;
      }
    }
    _widths = newWidths;
    notifyListeners();
  }
}
