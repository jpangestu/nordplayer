import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nordplayer/core/layout/layout_edit_controller.dart';
import 'package:nordplayer/core/layout/layout_node.dart';
import 'package:nordplayer/core/layout/layout_solver.dart';

/// Context passed to a zone's widget builder when rendering a [LayoutWidgetItem].
@immutable
class const LayoutWidgetRenderContext({
  required final GroupContainer group,
  required final bool isEditing,
  required final bool hasBoundedWidth,
  required final bool hasBoundedHeight,
}) {
  bool get isHorizontalGroup => group.axis == LayoutAxis.horizontal;
  bool get isFitContent => group.size is FitContentSize;
}

typedef LayoutWidgetBuilder = Widget Function(
  BuildContext context,
  LayoutWidgetItem item,
  LayoutWidgetRenderContext renderContext,
);

typedef LayoutDragFeedbackBuilder = Widget Function(BuildContext context, String widgetType);

/// Generic renderer for any [LayoutNode] tree ([SplitContainer] + [GroupContainer]).
///
/// Guarantees **zero layout shift** between normal mode and edit mode by overlaying
/// selection outlines, drop insertion indicators, and resize handles directly onto seams.
class const LayoutTreeView({
  super.key,
  required final LayoutNode root,
  required final LayoutWidgetBuilder widgetBuilder,
  required final LayoutDragFeedbackBuilder dragFeedbackBuilder,
  final LayoutEditController? editController,
  final ValueChanged<MouseCursor?>? onCursorOverrideChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = editController;
    if (controller == null) {
      return _LayoutNodeView(
        node: root,
        isRoot: true,
        hasBoundedWidth: true,
        hasBoundedHeight: true,
        widgetBuilder: widgetBuilder,
        dragFeedbackBuilder: dragFeedbackBuilder,
        editController: null,
        selectedNodeId: null,
        onCursorOverrideChanged: onCursorOverrideChanged,
      );
    }

    return ValueListenableBuilder<LayoutEditState>(
      valueListenable: controller,
      builder: (context, editState, _) {
        final activeController = editState.isEditing ? controller : null;
        return _LayoutNodeView(
          node: root,
          isRoot: true,
          hasBoundedWidth: true,
          hasBoundedHeight: true,
          widgetBuilder: widgetBuilder,
          dragFeedbackBuilder: dragFeedbackBuilder,
          editController: activeController,
          selectedNodeId: editState.isEditing ? editState.selectedNode?.id : null,
          onCursorOverrideChanged: onCursorOverrideChanged,
        );
      },
    );
  }
}

class const _LayoutNodeView({
  super.key,
  required final LayoutNode node,
  required final bool isRoot,
  required final bool hasBoundedWidth,
  required final bool hasBoundedHeight,
  required final LayoutWidgetBuilder widgetBuilder,
  required final LayoutDragFeedbackBuilder dragFeedbackBuilder,
  required final LayoutEditController? editController,
  required final String? selectedNodeId,
  required final ValueChanged<MouseCursor?>? onCursorOverrideChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return switch (node) {
      SplitContainer() => _SplitContainerView(
        split: node as SplitContainer,
        isRoot: isRoot,
        hasBoundedWidth: hasBoundedWidth,
        hasBoundedHeight: hasBoundedHeight,
        widgetBuilder: widgetBuilder,
        dragFeedbackBuilder: dragFeedbackBuilder,
        editController: editController,
        selectedNodeId: selectedNodeId,
        onCursorOverrideChanged: onCursorOverrideChanged,
      ),
      GroupContainer() => _GroupContainerView(
        group: node as GroupContainer,
        isRoot: isRoot,
        hasBoundedWidth: hasBoundedWidth,
        hasBoundedHeight: hasBoundedHeight,
        widgetBuilder: widgetBuilder,
        dragFeedbackBuilder: dragFeedbackBuilder,
        editController: editController,
        selectedNodeId: selectedNodeId,
      ),
    };
  }
}

// ================================================================================================
// SplitContainer View + Zero-Shift Custom RenderBox
// ================================================================================================

class const _SplitContainerView({
  required final SplitContainer split,
  required final bool isRoot,
  required final bool hasBoundedWidth,
  required final bool hasBoundedHeight,
  required final LayoutWidgetBuilder widgetBuilder,
  required final LayoutDragFeedbackBuilder dragFeedbackBuilder,
  required final LayoutEditController? editController,
  required final String? selectedNodeId,
  required final ValueChanged<MouseCursor?>? onCursorOverrideChanged,
}) extends StatefulWidget {
  @override
  State<_SplitContainerView> createState() => _SplitContainerViewState();
}

class _SplitContainerViewState extends State<_SplitContainerView> {
  final GlobalKey _splitBoxKey = GlobalKey();

  double? _extentOfPane(int index) {
    final renderObj = _splitBoxKey.currentContext?.findRenderObject();
    if (renderObj is _RenderSplitLayout) {
      return renderObj.extentOfPane(index);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final split = widget.split;
    final edit = widget.editController;
    final isEditing = edit != null;
    final isSelected = isEditing && widget.selectedNodeId == split.id;
    final isHorizontal = split.axis == LayoutAxis.horizontal;
    final colorScheme = Theme.of(context).colorScheme;

    final slotChildren = <Widget>[];

    // Pane children (always identical geometry in normal & edit modes).
    for (var i = 0; i < split.children.length; i++) {
      final child = split.children[i];
      final childIsFit = child.size is FitContentSize;
      final childHasBoundedWidth = isHorizontal
          ? (!childIsFit && widget.hasBoundedWidth)
          : widget.hasBoundedWidth;
      final childHasBoundedHeight = isHorizontal
          ? widget.hasBoundedHeight
          : (!childIsFit && widget.hasBoundedHeight);

      slotChildren.add(
        _SplitPaneSlot(
          key: ValueKey('pane_${child.id}'),
          index: i,
          paneSize: child.size,
          child: _LayoutNodeView(
            key: ValueKey(child.id),
            node: child,
            isRoot: false,
            hasBoundedWidth: childHasBoundedWidth,
            hasBoundedHeight: childHasBoundedHeight,
            widgetBuilder: widget.widgetBuilder,
            dragFeedbackBuilder: widget.dragFeedbackBuilder,
            editController: edit,
            selectedNodeId: widget.selectedNodeId,
            onCursorOverrideChanged: widget.onCursorOverrideChanged,
          ),
        ),
      );
    }

    // Overlaid resize handles (only added in edit mode; zero effect on pane positions).
    if (isEditing) {
      for (var i = 0; i < split.children.length - 1; i++) {
        final first = split.children[i];
        final second = split.children[i + 1];
        if (!canResizeDivider(first.size, second.size)) continue;

        slotChildren.add(
          _SplitHandleSlot(
            key: ValueKey('handle_${split.id}_$i'),
            dividerIndex: i,
            child: _OverlayResizeHandle(
              splitId: split.id,
              dividerIndex: i,
              axis: split.axis,
              firstSize: first.size,
              secondSize: second.size,
              readPaneExtent: _extentOfPane,
              editController: edit,
              onCursorOverrideChanged: widget.onCursorOverrideChanged,
            ),
          ),
        );
      }
    }

    final splitBox = Padding(
      padding: split.padding,
      child: _SplitLayoutBox(
        key: _splitBoxKey,
        axis: split.axis,
        spacing: split.spacing,
        children: slotChildren,
      ),
    );

    if (!isEditing) return splitBox;

    // Subtle selection outline when a SplitContainer itself is selected.
    return Stack(
      fit: StackFit.passthrough,
      clipBehavior: Clip.none,
      children: [
        splitBox,
        if (isSelected)
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: colorScheme.primary.withValues(alpha: 0.9), width: 1.5),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class const _OverlayResizeHandle({
  required final String splitId,
  required final int dividerIndex,
  required final LayoutAxis axis,
  required final LayoutSize firstSize,
  required final LayoutSize secondSize,
  required final double? Function(int paneIndex) readPaneExtent,
  required final LayoutEditController editController,
  required final ValueChanged<MouseCursor?>? onCursorOverrideChanged,
}) extends StatefulWidget {
  @override
  State<_OverlayResizeHandle> createState() => _OverlayResizeHandleState();
}

class _OverlayResizeHandleState extends State<_OverlayResizeHandle> {
  bool _hovered = false;
  bool _dragging = false;

  double? _startPointer;
  LayoutSize? _startFirstSize;
  LayoutSize? _startSecondSize;
  double? _startFirstExtent;
  double? _startSecondExtent;

  bool get _isHorizontal => widget.axis == LayoutAxis.horizontal;

  void _onDragStart(Offset globalPosition) {
    final firstExtent = widget.readPaneExtent(widget.dividerIndex);
    final secondExtent = widget.readPaneExtent(widget.dividerIndex + 1);
    if (firstExtent == null || secondExtent == null) return;

    _dragging = true;
    _startPointer = _isHorizontal ? globalPosition.dx : globalPosition.dy;
    _startFirstSize = widget.firstSize;
    _startSecondSize = widget.secondSize;
    _startFirstExtent = firstExtent;
    _startSecondExtent = secondExtent;

    widget.editController.beginResize();
    widget.onCursorOverrideChanged?.call(
      _isHorizontal ? SystemMouseCursors.resizeLeftRight : SystemMouseCursors.resizeUpDown,
    );
    setState(() {});
  }

  void _onDragUpdate(Offset globalPosition) {
    if (_startPointer == null ||
        _startFirstSize == null ||
        _startSecondSize == null ||
        _startFirstExtent == null ||
        _startSecondExtent == null) {
      return;
    }

    final current = _isHorizontal ? globalPosition.dx : globalPosition.dy;
    widget.editController.updateResize(
      splitId: widget.splitId,
      dividerIndex: widget.dividerIndex,
      firstStartSize: _startFirstSize!,
      secondStartSize: _startSecondSize!,
      firstStartExtent: _startFirstExtent!,
      secondStartExtent: _startSecondExtent!,
      deltaPixels: current - _startPointer!,
    );
  }

  void _onDragEnd() {
    _dragging = false;
    _startPointer = null;
    _startFirstSize = null;
    _startSecondSize = null;
    _startFirstExtent = null;
    _startSecondExtent = null;
    widget.editController.endResize();
    widget.onCursorOverrideChanged?.call(null);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final active = _hovered || _dragging;
    final cursor = _isHorizontal
        ? SystemMouseCursors.resizeLeftRight
        : SystemMouseCursors.resizeUpDown;

    return MouseRegion(
      cursor: cursor,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragStart: _isHorizontal ? (d) => _onDragStart(d.globalPosition) : null,
        onHorizontalDragUpdate: _isHorizontal ? (d) => _onDragUpdate(d.globalPosition) : null,
        onHorizontalDragEnd: _isHorizontal ? (_) => _onDragEnd() : null,
        onHorizontalDragCancel: _isHorizontal ? _onDragEnd : null,
        onVerticalDragStart: !_isHorizontal ? (d) => _onDragStart(d.globalPosition) : null,
        onVerticalDragUpdate: !_isHorizontal ? (d) => _onDragUpdate(d.globalPosition) : null,
        onVerticalDragEnd: !_isHorizontal ? (_) => _onDragEnd() : null,
        onVerticalDragCancel: !_isHorizontal ? _onDragEnd : null,
        child: Tooltip(
          message: 'Drag to resize',
          waitDuration: const Duration(milliseconds: 500),
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              width: _isHorizontal ? (active ? 4 : 2.5) : (active ? 30 : 20),
              height: _isHorizontal ? (active ? 30 : 20) : (active ? 4 : 2.5),
              decoration: BoxDecoration(
                color: active
                    ? colorScheme.primary
                    : colorScheme.outlineVariant.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(2),
                boxShadow: active
                    ? [BoxShadow(color: colorScheme.primary.withValues(alpha: 0.45), blurRadius: 6)]
                    : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SplitParentData extends ContainerBoxParentData<RenderBox> {
  bool isHandle = false;
  int index = 0;
  LayoutSize paneSize = const FlexSize(1.0);
}

class const _SplitPaneSlot({
  super.key,
  required final int index,
  required final LayoutSize paneSize,
  required super.child,
}) extends ParentDataWidget<_SplitParentData> {
  @override
  void applyParentData(RenderObject renderObject) {
    final pd = renderObject.parentData! as _SplitParentData;
    var needsLayout = false;
    if (pd.isHandle) {
      pd.isHandle = false;
      needsLayout = true;
    }
    if (pd.index != index) {
      pd.index = index;
      needsLayout = true;
    }
    if (pd.paneSize != paneSize) {
      pd.paneSize = paneSize;
      needsLayout = true;
    }
    if (needsLayout) {
      renderObject.parent?.markNeedsLayout();
    }
  }

  @override
  Type get debugTypicalAncestorWidgetClass => _SplitLayoutBox;
}

class const _SplitHandleSlot({super.key, required final int dividerIndex, required super.child})
    extends ParentDataWidget<_SplitParentData> {
  @override
  void applyParentData(RenderObject renderObject) {
    final pd = renderObject.parentData! as _SplitParentData;
    var needsLayout = false;
    if (!pd.isHandle) {
      pd.isHandle = true;
      needsLayout = true;
    }
    if (pd.index != dividerIndex) {
      pd.index = dividerIndex;
      needsLayout = true;
    }
    if (needsLayout) {
      renderObject.parent?.markNeedsLayout();
    }
  }

  @override
  Type get debugTypicalAncestorWidgetClass => _SplitLayoutBox;
}

class const _SplitLayoutBox({
  super.key,
  required final LayoutAxis axis,
  required final double spacing,
  required super.children,
}) extends MultiChildRenderObjectWidget {
  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderSplitLayout(axis: axis, spacing: spacing);
  }

  @override
  void updateRenderObject(BuildContext context, _RenderSplitLayout renderObject) {
    renderObject
      ..axis = axis
      ..spacing = spacing;
  }
}

class _RenderSplitLayout({required LayoutAxis axis, required double spacing})
    extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _SplitParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _SplitParentData> {
  static const double _handleHitThickness = 10.0;

  LayoutAxis _axis = axis;
  set axis(LayoutAxis value) {
    if (_axis == value) return;
    _axis = value;
    markNeedsLayout();
  }

  double _spacing = spacing;
  set spacing(double value) {
    if (_spacing == value) return;
    _spacing = value;
    markNeedsLayout();
  }

  List<double> _lastPaneExtents = const [];

  double? extentOfPane(int index) {
    if (index < 0 || index >= _lastPaneExtents.length) return null;
    return _lastPaneExtents[index];
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _SplitParentData) {
      child.parentData = _SplitParentData();
    }
  }

  @override
  void performLayout() {
    final panes = <RenderBox>[];
    final handles = <RenderBox>[];

    var child = firstChild;
    while (child != null) {
      final pd = child.parentData! as _SplitParentData;
      if (pd.isHandle) {
        handles.add(child);
      } else {
        panes.add(child);
      }
      child = pd.nextSibling;
    }

    if (panes.isEmpty) {
      _lastPaneExtents = const [];
      size = constraints.smallest;
      return;
    }

    final isHorizontal = _axis == LayoutAxis.horizontal;
    final maxMain = isHorizontal ? constraints.maxWidth : constraints.maxHeight;
    final maxCross = isHorizontal ? constraints.maxHeight : constraints.maxWidth;
    final totalSpacing = panes.length > 1 ? _spacing * (panes.length - 1) : 0.0;

    late final List<double> extents;
    late final double resolvedMain;
    late final double resolvedCross;

    if (!maxMain.isFinite) {
      // Unbounded main axis (e.g. nested inside a FitContent parent): size to intrinsic sum.
      extents = List<double>.filled(panes.length, 0.0);
      var crossMax = 0.0;
      for (var i = 0; i < panes.length; i++) {
        final pane = panes[i];
        final paneConstraints = isHorizontal
            ? BoxConstraints(
                minHeight: maxCross.isFinite ? maxCross : 0.0,
                maxHeight: maxCross.isFinite ? maxCross : double.infinity,
              )
            : BoxConstraints(
                minWidth: maxCross.isFinite ? maxCross : 0.0,
                maxWidth: maxCross.isFinite ? maxCross : double.infinity,
              );
        pane.layout(paneConstraints, parentUsesSize: true);
        extents[i] = isHorizontal ? pane.size.width : pane.size.height;
        crossMax = math.max(crossMax, isHorizontal ? pane.size.height : pane.size.width);
      }
      resolvedMain = extents.fold<double>(0.0, (a, b) => a + b) + totalSpacing;
      resolvedCross = maxCross.isFinite ? maxCross : crossMax;
    } else {
      final available = math.max(0.0, maxMain - totalSpacing);
      final sizes = <LayoutSize>[];
      final fitExtents = List<double?>.filled(panes.length, null);
      var measuredCrossMax = 0.0;

      // Pass 1: Measure FitContentSize panes to obtain their exact intrinsic extent.
      for (var i = 0; i < panes.length; i++) {
        final pane = panes[i];
        final spec = (pane.parentData! as _SplitParentData).paneSize;
        sizes.add(spec);
        if (spec is FitContentSize) {
          final looseConstraints = isHorizontal
              ? BoxConstraints(
                  minWidth: 0.0,
                  maxWidth: available,
                  minHeight: maxCross.isFinite ? maxCross : 0.0,
                  maxHeight: maxCross.isFinite ? maxCross : double.infinity,
                )
              : BoxConstraints(
                  minWidth: maxCross.isFinite ? maxCross : 0.0,
                  maxWidth: maxCross.isFinite ? maxCross : double.infinity,
                  minHeight: 0.0,
                  maxHeight: available,
                );
          pane.layout(looseConstraints, parentUsesSize: true);
          fitExtents[i] = isHorizontal ? pane.size.width : pane.size.height;
          measuredCrossMax = math.max(
            measuredCrossMax,
            isHorizontal ? pane.size.height : pane.size.width,
          );
        }
      }

      // Pass 2: Solve exact pixel extents for all panes.
      extents = solveSplitExtents(availableExtent: available, sizes: sizes, fitExtents: fitExtents);

      // Pass 3: Lay out all panes with exact solved extents.
      for (var i = 0; i < panes.length; i++) {
        final pane = panes[i];
        // Skip re-layout if FitContentSize already laid out at this exact extent.
        if (sizes[i] is FitContentSize && fitExtents[i] == extents[i]) continue;
        final paneConstraints = isHorizontal
            ? BoxConstraints(
                minWidth: extents[i],
                maxWidth: extents[i],
                minHeight: maxCross.isFinite ? maxCross : 0.0,
                maxHeight: maxCross.isFinite ? maxCross : double.infinity,
              )
            : BoxConstraints(
                minWidth: maxCross.isFinite ? maxCross : 0.0,
                maxWidth: maxCross.isFinite ? maxCross : double.infinity,
                minHeight: extents[i],
                maxHeight: extents[i],
              );
        pane.layout(paneConstraints, parentUsesSize: true);
        if (!maxCross.isFinite) {
          measuredCrossMax = math.max(
            measuredCrossMax,
            isHorizontal ? pane.size.height : pane.size.width,
          );
        }
      }

      resolvedMain = maxMain;
      resolvedCross = maxCross.isFinite ? maxCross : measuredCrossMax;
    }

    _lastPaneExtents = extents;
    size = constraints.constrain(
      isHorizontal ? Size(resolvedMain, resolvedCross) : Size(resolvedCross, resolvedMain),
    );

    // Pass 4: Position panes at their exact offsets.
    final paneOffsets = List<double>.filled(panes.length, 0.0);
    var cursor = 0.0;
    for (var i = 0; i < panes.length; i++) {
      paneOffsets[i] = cursor;
      final pd = panes[i].parentData! as _SplitParentData;
      pd.offset = isHorizontal ? Offset(cursor, 0.0) : Offset(0.0, cursor);
      cursor += extents[i] + _spacing;
    }

    // Pass 5: Position overlaid resize handles directly on top of pane seams (zero shift!).
    for (final handle in handles) {
      final pd = handle.parentData! as _SplitParentData;
      final idx = pd.index;
      if (idx < 0 || idx >= panes.length - 1) {
        handle.layout(BoxConstraints.tight(Size.zero), parentUsesSize: true);
        pd.offset = Offset.zero;
        continue;
      }

      final seam = paneOffsets[idx] + extents[idx] + (_spacing / 2);
      final handleConstraints = isHorizontal
          ? BoxConstraints.tightFor(width: _handleHitThickness, height: size.height)
          : BoxConstraints.tightFor(width: size.width, height: _handleHitThickness);
      handle.layout(handleConstraints, parentUsesSize: true);

      if (isHorizontal) {
        final maxLeft = math.max(0.0, size.width - _handleHitThickness);
        pd.offset = Offset((seam - _handleHitThickness / 2).clamp(0.0, maxLeft), 0.0);
      } else {
        final maxTop = math.max(0.0, size.height - _handleHitThickness);
        pd.offset = Offset(0.0, (seam - _handleHitThickness / 2).clamp(0.0, maxTop));
      }
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    return defaultHitTestChildren(result, position: position);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    defaultPaint(context, offset);
  }
}

// ================================================================================================
// GroupContainer View (Zero-Shift Edit Chrome + Half-Box Drop Indicators)
// ================================================================================================

class const _GroupContainerView({
  required final GroupContainer group,
  required final bool isRoot,
  required final bool hasBoundedWidth,
  required final bool hasBoundedHeight,
  required final LayoutWidgetBuilder widgetBuilder,
  required final LayoutDragFeedbackBuilder dragFeedbackBuilder,
  required final LayoutEditController? editController,
  required final String? selectedNodeId,
}) extends StatefulWidget {
  @override
  State<_GroupContainerView> createState() => _GroupContainerViewState();
}

class _GroupContainerViewState extends State<_GroupContainerView> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final group = widget.group;
    final edit = widget.editController;
    final isEditing = edit != null;
    final isSelected = isEditing && widget.selectedNodeId == group.id;
    final isHorizontal = group.axis == LayoutAxis.horizontal;
    final hasBoundedMain = isHorizontal ? widget.hasBoundedWidth : widget.hasBoundedHeight;
    final hasBoundedCross = isHorizontal ? widget.hasBoundedHeight : widget.hasBoundedWidth;
    final effectiveCrossAlign =
        (group.crossAlignment == LayoutCrossAlign.stretch && !hasBoundedCross)
        ? CrossAxisAlignment.center
        : group.crossAlignment.crossAxis;
    final colorScheme = Theme.of(context).colorScheme;

    final renderContext = LayoutWidgetRenderContext(
      group: group,
      isEditing: isEditing,
      hasBoundedWidth: widget.hasBoundedWidth,
      hasBoundedHeight: widget.hasBoundedHeight,
    );

    Widget buildFlexContent() {
      final children = <Widget>[];
      for (var i = 0; i < group.items.length; i++) {
        if (i > 0 && group.gap > 0 && group.alignment != LayoutAlign.spaceBetween) {
          children.add(isHorizontal ? SizedBox(width: group.gap) : SizedBox(height: group.gap));
        }

        final item = group.items[i];
        final built = widget.widgetBuilder(context, item, renderContext);

        if (!isEditing) {
          children.add(built);
        } else {
          // If the host builder wrapped an expanding widget in Expanded/Flexible, lift that
          // Flex ParentDataWidget outside _EditableGroupWidget so it stays a direct Flex child.
          if (built is Flexible) {
            children.add(
              Flexible(
                flex: built.flex,
                fit: built.fit,
                child: _EditableGroupWidget(
                  item: item,
                  index: i,
                  groupId: group.id,
                  axis: group.axis,
                  dragFeedbackBuilder: widget.dragFeedbackBuilder,
                  editController: edit,
                  child: built.child,
                ),
              ),
            );
          } else {
            children.add(
              _EditableGroupWidget(
                item: item,
                index: i,
                groupId: group.id,
                axis: group.axis,
                dragFeedbackBuilder: widget.dragFeedbackBuilder,
                editController: edit,
                child: built,
              ),
            );
          }
        }
      }

      return Padding(
        padding: group.padding,
        child: Flex(
          direction: isHorizontal ? Axis.horizontal : Axis.vertical,
          mainAxisAlignment: group.alignment.mainAxis,
          mainAxisSize: hasBoundedMain ? MainAxisSize.max : MainAxisSize.min,
          crossAxisAlignment: effectiveCrossAlign,
          children: children,
        ),
      );
    }

    if (!isEditing) {
      return group.items.isEmpty ? const SizedBox.shrink() : buildFlexContent();
    }

    // Edit mode: exact same content geometry + overlaid border/badge + full-group fallback drop target.
    final tag = '${isHorizontal ? 'Row' : 'Col'} · ${group.size.shortLabel}';

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => edit.select(group.id),
        child: DragTarget<LayoutWidgetDragPayload>(
          onWillAcceptWithDetails: (_) => true,
          onAcceptWithDetails: (details) => edit.placeWidget(
            payload: details.data,
            targetGroupId: group.id,
            targetIndex: group.items.length,
          ),
          builder: (context, candidateData, _) {
            final isGroupDropHover = candidateData.isNotEmpty;

            return Stack(
              fit: StackFit.passthrough,
              clipBehavior: Clip.none,
              children: [
                if (group.items.isEmpty)
                  Center(
                    child: Text(
                      isGroupDropHover
                          ? 'Drop widget here'
                          : 'Empty ${isHorizontal ? 'Row' : 'Col'}',
                      maxLines: 1,
                      overflow: .ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontSize: 10,
                        color: isGroupDropHover || isSelected
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                    ),
                  )
                else
                  buildFlexContent(),

                // Overlaid selection / hover / drop chrome — zero layout shift!
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 110),
                      decoration: BoxDecoration(
                        color: isGroupDropHover
                            ? colorScheme.primary.withValues(alpha: 0.12)
                            : isSelected
                            ? colorScheme.primary.withValues(alpha: 0.06)
                            : Colors.transparent,
                        border: Border.all(
                          color: isGroupDropHover || isSelected
                              ? colorScheme.primary.withValues(alpha: 0.9)
                              : _hovered
                              ? colorScheme.primary.withValues(alpha: 0.45)
                              : colorScheme.outlineVariant.withValues(alpha: 0.35),
                          width: isGroupDropHover || isSelected ? 1.5 : 1.0,
                        ),
                      ),
                    ),
                  ),
                ),

                if (isSelected || _hovered)
                  Positioned(
                    top: 0,
                    left: 0,
                    child: IgnorePointer(
                      child: Container(
                        padding: const .symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? colorScheme.primary
                              : colorScheme.surfaceContainerHigh,
                          borderRadius: const BorderRadius.only(bottomRight: Radius.circular(4)),
                        ),
                        child: Text(
                          tag,
                          style: TextStyle(
                            fontFamily: 'jetbrains_mono',
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? colorScheme.onPrimary
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Zero-shift editable widget wrapper:
/// - Wraps the real widget in [IgnorePointer] so drags move the item instead of clicking/seeking.
/// - Detects leading-half vs trailing-half pointer hover during drag and overlays an insertion line.
class const _EditableGroupWidget({
  required final LayoutWidgetItem item,
  required final int index,
  required final String groupId,
  required final LayoutAxis axis,
  required final LayoutDragFeedbackBuilder dragFeedbackBuilder,
  required final LayoutEditController editController,
  required final Widget child,
}) extends StatefulWidget {
  @override
  State<_EditableGroupWidget> createState() => _EditableGroupWidgetState();
}

class _EditableGroupWidgetState extends State<_EditableGroupWidget> {
  bool _hovered = false;
  bool? _insertBefore; // null = no drag over; true = leading edge; false = trailing edge

  bool get _isHorizontal => widget.axis == LayoutAxis.horizontal;

  void _updateSide(Offset globalOffset) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final local = box.globalToLocal(globalOffset);
    final before = _isHorizontal ? local.dx < box.size.width / 2 : local.dy < box.size.height / 2;
    if (_insertBefore != before) {
      setState(() => _insertBefore = before);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final draggable = Draggable<LayoutWidgetDragPayload>(
      data: LayoutWidgetDragPayload(widgetType: widget.item.type, sourceItemId: widget.item.id),
      dragAnchorStrategy: pointerDragAnchorStrategy,
      feedback: widget.dragFeedbackBuilder(context, widget.item.type),
      childWhenDragging: Opacity(opacity: 0.25, child: IgnorePointer(child: widget.child)),
      child: MouseRegion(
        cursor: SystemMouseCursors.grab,
        child: IgnorePointer(child: widget.child),
      ),
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: DragTarget<LayoutWidgetDragPayload>(
        onWillAcceptWithDetails: (details) => details.data.sourceItemId != widget.item.id,
        onMove: (details) => _updateSide(details.offset),
        onLeave: (_) {
          if (_insertBefore != null) setState(() => _insertBefore = null);
        },
        onAcceptWithDetails: (details) {
          final targetIdx = (_insertBefore ?? true) ? widget.index : widget.index + 1;
          setState(() => _insertBefore = null);
          widget.editController.placeWidget(
            payload: details.data,
            targetGroupId: widget.groupId,
            targetIndex: targetIdx,
          );
        },
        builder: (context, candidateData, _) {
          final showInsert = candidateData.isNotEmpty && _insertBefore != null;
          final before = _insertBefore ?? true;

          return Stack(
            fit: StackFit.passthrough,
            clipBehavior: Clip.none,
            children: [
              draggable,

              // Overlaid hover highlight border (zero shift)
              if (_hovered)
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.7)),
                      ),
                    ),
                  ),
                ),

              // Overlaid drop insertion bar (zero shift)
              if (showInsert)
                Positioned(
                  left: _isHorizontal ? (before ? -1.5 : null) : 0,
                  right: _isHorizontal ? (before ? null : -1.5) : 0,
                  top: _isHorizontal ? 0 : (before ? -1.5 : null),
                  bottom: _isHorizontal ? 0 : (before ? null : -1.5),
                  child: IgnorePointer(
                    child: Container(
                      width: _isHorizontal ? 3 : null,
                      height: _isHorizontal ? null : 3,
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.primary.withValues(alpha: 0.55),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Quick-remove badge on hover
              if (_hovered)
                Positioned(
                  top: -5,
                  right: -5,
                  child: GestureDetector(
                    onTap: () => widget.editController.removeWidget(widget.item.id),
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: colorScheme.error,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 4),
                          ],
                        ),
                        child: Icon(LucideIcons.x, size: 10, color: colorScheme.onError),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
