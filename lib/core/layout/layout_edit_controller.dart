import 'package:flutter/foundation.dart';
import 'package:nordplayer/core/layout/layout_node.dart';
import 'package:nordplayer/core/layout/layout_operations.dart';
import 'package:nordplayer/core/layout/layout_solver.dart';

/// Drag payload for moving or inserting widgets across [GroupContainer]s.
@immutable
class const LayoutWidgetDragPayload({
  required final String widgetType,
  final String? sourceItemId,
  final bool allowMultiple = false,
});

/// Immutable editing state for any zone using the reusable layout system.
@immutable
class const LayoutEditState({
  final bool isEditing = false,
  final LayoutNode? draft,
  final String? selectedNodeId,
  final List<LayoutNode> undoStack = const [],
  final List<LayoutNode> redoStack = const [],
}) {
  bool get canUndo => undoStack.isNotEmpty;
  bool get canRedo => redoStack.isNotEmpty;

  LayoutNode? get selectedNode {
    final root = draft;
    if (root == null) return null;
    if (selectedNodeId != null) {
      final found = LayoutOps.findNode(root, selectedNodeId!);
      if (found != null) return found;
    }
    return root;
  }
}

/// Reusable [ValueNotifier] controller for editing a [LayoutNode] tree with draft/commit,
/// undo/redo, live zero-spam divider resizing, and tree invariants.
class LayoutEditController({final int maxNestingDepth = 3}) extends ValueNotifier<LayoutEditState> {
  this : super(const LayoutEditState());

  LayoutNode? _preResizeSnapshot;

  bool get isEditing => value.isEditing;
  LayoutNode? get draft => value.draft;
  LayoutNode? get selectedNode => value.selectedNode;
  bool get canUndo => value.canUndo;
  bool get canRedo => value.canRedo;

  /// Returns the live draft while editing, or [committed] otherwise.
  LayoutNode activeRoot(LayoutNode committed) =>
      (value.isEditing && value.draft != null) ? value.draft! : committed;

  void enter(LayoutNode initialRoot) {
    _preResizeSnapshot = null;
    value = LayoutEditState(isEditing: true, draft: initialRoot, selectedNodeId: initialRoot.id);
  }

  void exit() {
    _preResizeSnapshot = null;
    value = const LayoutEditState();
  }

  void select(String nodeId) {
    final current = value;
    if (!current.isEditing || current.draft == null) return;
    if (LayoutOps.findNode(current.draft!, nodeId) == null) return;
    if (current.selectedNodeId == nodeId) return;
    value = LayoutEditState(
      isEditing: true,
      draft: current.draft,
      selectedNodeId: nodeId,
      undoStack: current.undoStack,
      redoStack: current.redoStack,
    );
  }

  void push(LayoutNode nextRoot, {String? selectId}) {
    final current = value;
    final currentDraft = current.draft;
    if (!current.isEditing || currentDraft == null || currentDraft == nextRoot) return;
    final desiredSelection = selectId ?? current.selectedNodeId;
    final validSelection =
        desiredSelection != null && LayoutOps.findNode(nextRoot, desiredSelection) != null
        ? desiredSelection
        : nextRoot.id;
    value = LayoutEditState(
      isEditing: true,
      draft: nextRoot,
      selectedNodeId: validSelection,
      undoStack: [...current.undoStack, currentDraft],
      redoStack: const [],
    );
  }

  void undo() {
    final current = value;
    if (!current.canUndo || current.draft == null) return;
    final prev = current.undoStack.last;
    final validSel =
        current.selectedNodeId != null && LayoutOps.findNode(prev, current.selectedNodeId!) != null
        ? current.selectedNodeId
        : prev.id;
    value = LayoutEditState(
      isEditing: true,
      draft: prev,
      selectedNodeId: validSel,
      undoStack: current.undoStack.sublist(0, current.undoStack.length - 1),
      redoStack: [...current.redoStack, current.draft!],
    );
  }

  void redo() {
    final current = value;
    if (!current.canRedo || current.draft == null) return;
    final next = current.redoStack.last;
    final validSel =
        current.selectedNodeId != null && LayoutOps.findNode(next, current.selectedNodeId!) != null
        ? current.selectedNodeId
        : next.id;
    value = LayoutEditState(
      isEditing: true,
      draft: next,
      selectedNodeId: validSel,
      undoStack: [...current.undoStack, current.draft!],
      redoStack: current.redoStack.sublist(0, current.redoStack.length - 1),
    );
  }

  void split(String targetId, {required LayoutAxis axis, bool insertBefore = false}) {
    final root = value.draft;
    if (root == null) return;
    final parent = LayoutOps.parentOf(root, targetId);
    final willNest = parent == null || parent.axis != axis;
    final depth = LayoutOps.depthOf(root, targetId);
    if (willNest && depth >= maxNestingDepth) return;

    final result = LayoutOps.splitNode(root, targetId, axis: axis, insertBefore: insertBefore);
    push(result.root, selectId: result.createdId);
  }

  void removeNode(String nodeId) {
    final root = value.draft;
    if (root == null || root.id == nodeId) return;
    final parent = LayoutOps.parentOf(root, nodeId);
    final next = LayoutOps.removeNode(root, nodeId);
    push(next, selectId: parent?.id ?? next.id);
  }

  void updateNode(String nodeId, LayoutNode Function(LayoutNode) transform) {
    final root = value.draft;
    if (root == null) return;
    push(LayoutOps.updateNode(root, nodeId, transform));
  }

  void placeWidget({
    required LayoutWidgetDragPayload payload,
    required String targetGroupId,
    required int targetIndex,
  }) {
    final root = value.draft;
    if (root == null) return;
    final next = LayoutOps.placeWidget(
      root: root,
      widgetType: payload.widgetType,
      targetGroupId: targetGroupId,
      targetIndex: targetIndex,
      sourceItemId: payload.sourceItemId,
      allowMultiple: payload.allowMultiple,
    );
    push(next, selectId: targetGroupId);
  }

  void removeWidget(String itemId) {
    final root = value.draft;
    if (root == null) return;
    push(LayoutOps.removeWidgetItem(root, itemId));
  }

  void beginResize() {
    _preResizeSnapshot = value.draft;
  }

  void updateResize({
    required String splitId,
    required int dividerIndex,
    required LayoutSize firstStartSize,
    required LayoutSize secondStartSize,
    required double firstStartExtent,
    required double secondStartExtent,
    required double deltaPixels,
  }) {
    final current = value;
    final root = current.draft;
    if (!current.isEditing || root == null) return;
    final resized = solveDividerResize(
      firstSize: firstStartSize,
      secondSize: secondStartSize,
      firstExtent: firstStartExtent,
      secondExtent: secondStartExtent,
      deltaPixels: deltaPixels,
    );
    final nextRoot = LayoutOps.updateChildSizes(
      root,
      splitId: splitId,
      firstIndex: dividerIndex,
      firstSize: resized.first,
      secondSize: resized.second,
    );
    value = LayoutEditState(
      isEditing: true,
      draft: nextRoot,
      selectedNodeId: current.selectedNodeId,
      undoStack: current.undoStack,
      redoStack: current.redoStack,
    );
  }

  void endResize() {
    final snapshot = _preResizeSnapshot;
    _preResizeSnapshot = null;
    final current = value;
    if (snapshot == null || current.draft == null || snapshot == current.draft) return;
    value = LayoutEditState(
      isEditing: true,
      draft: current.draft,
      selectedNodeId: current.selectedNodeId,
      undoStack: [...current.undoStack, snapshot],
      redoStack: const [],
    );
  }
}
