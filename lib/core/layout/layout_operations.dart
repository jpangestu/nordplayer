import 'package:nordplayer/core/layout/layout_node.dart';

/// Pure, immutable tree queries and operations with automatic invariant cleanup:
/// - Flattens nested same-axis [SplitContainer]s.
/// - Auto-unwraps single-child [SplitContainer]s.
abstract final class LayoutOps {
  static LayoutNode? findNode(LayoutNode root, String targetId) {
    if (root.id == targetId) return root;
    if (root is SplitContainer) {
      for (final child in root.children) {
        final found = findNode(child, targetId);
        if (found != null) return found;
      }
    }
    return null;
  }

  static SplitContainer? parentOf(LayoutNode root, String childId) {
    if (root is! SplitContainer) return null;
    for (final child in root.children) {
      if (child.id == childId) return root;
      final found = parentOf(child, childId);
      if (found != null) return found;
    }
    return null;
  }

  static List<LayoutNode> pathTo(LayoutNode root, String targetId) {
    if (root.id == targetId) return [root];
    if (root is SplitContainer) {
      for (final child in root.children) {
        final sub = pathTo(child, targetId);
        if (sub.isNotEmpty) return [root, ...sub];
      }
    }
    return const [];
  }

  static int depthOf(LayoutNode root, String targetId) {
    final path = pathTo(root, targetId);
    return path.isEmpty ? -1 : path.length - 1;
  }

  static bool containsWidgetType(LayoutNode root, String widgetType) {
    return switch (root) {
      GroupContainer(:final items) => items.any((i) => i.type == widgetType),
      SplitContainer(:final children) => children.any((c) => containsWidgetType(c, widgetType)),
    };
  }

  /// Normalizes the tree to preserve invariants:
  /// 1. Flattens any child [SplitContainer] that shares the same [LayoutAxis] as its parent.
  /// 2. Unwraps any [SplitContainer] with a single child (promoting that child while keeping the split's size).
  static LayoutNode normalize(LayoutNode node) {
    if (node is GroupContainer) return node;

    final split = node as SplitContainer;
    final normalizedChildren = <LayoutNode>[];

    for (final child in split.children) {
      final normChild = normalize(child);
      if (normChild is SplitContainer && normChild.axis == split.axis) {
        normalizedChildren.addAll(normChild.children);
      } else {
        normalizedChildren.add(normChild);
      }
    }

    if (normalizedChildren.isEmpty) {
      return GroupContainer(id: split.id, size: split.size, axis: split.axis);
    }

    if (normalizedChildren.length == 1) {
      return normalizedChildren.first.withSize(split.size);
    }

    return split.copyWith(children: normalizedChildren);
  }

  /// Transforms the node matching [targetId] and normalizes the tree.
  static LayoutNode updateNode(
    LayoutNode root,
    String targetId,
    LayoutNode Function(LayoutNode node) transform,
  ) {
    LayoutNode visit(LayoutNode current) {
      if (current.id == targetId) return transform(current);
      if (current is SplitContainer) {
        var changed = false;
        final next = <LayoutNode>[];
        for (final child in current.children) {
          final updated = visit(child);
          if (!identical(updated, child)) changed = true;
          next.add(updated);
        }
        return changed ? current.copyWith(children: next) : current;
      }
      return current;
    }

    return normalize(visit(root));
  }

  /// Splits [targetId] along [axis], adding a new empty [GroupContainer] right after it.
  ///
  /// If [targetId]'s parent is already a [SplitContainer] with the same [axis], the new pane is
  /// inserted directly as a sibling (flat invariant) rather than nesting same-axis splits.
  static ({LayoutNode root, String createdId}) splitNode(
    LayoutNode root,
    String targetId, {
    required LayoutAxis axis,
    bool insertBefore = false,
  }) {
    final newGroup = GroupContainer(
      id: nextLayoutId('g'),
      size: const FlexSize(1.0),
      axis: LayoutAxis.horizontal,
      alignment: LayoutAlign.center,
    );

    final parent = parentOf(root, targetId);
    if (parent != null && parent.axis == axis) {
      final nextRoot = updateNode(root, parent.id, (n) {
        final s = n as SplitContainer;
        final idx = s.children.indexWhere((c) => c.id == targetId);
        if (idx == -1) return s;
        final list = List<LayoutNode>.of(s.children);
        list.insert(insertBefore ? idx : idx + 1, newGroup);
        return s.copyWith(children: list);
      });
      return (root: nextRoot, createdId: newGroup.id);
    }

    final nextRoot = updateNode(root, targetId, (target) {
      final existingAsChild = target.withSize(const FlexSize(1.0));
      return SplitContainer(
        id: nextLayoutId('s'),
        size: target.size,
        axis: axis,
        spacing: axis == LayoutAxis.horizontal ? 8.0 : 2.0,
        children: insertBefore ? [newGroup, existingAsChild] : [existingAsChild, newGroup],
      );
    });
    return (root: nextRoot, createdId: newGroup.id);
  }

  /// Removes a container node by [nodeId]. Cannot remove the root node itself.
  static LayoutNode removeNode(LayoutNode root, String nodeId) {
    if (root.id == nodeId) return root;

    LayoutNode? visit(LayoutNode current) {
      if (current.id == nodeId) return null;
      if (current is SplitContainer) {
        final next = <LayoutNode>[];
        var changed = false;
        for (final child in current.children) {
          final result = visit(child);
          if (result == null) {
            changed = true;
          } else {
            if (!identical(result, child)) changed = true;
            next.add(result);
          }
        }
        if (!changed) return current;
        if (next.isEmpty) return null;
        return current.copyWith(children: next);
      }
      return current;
    }

    final pruned = visit(root);
    return pruned != null ? normalize(pruned) : root;
  }

  /// Updates the sizes of two adjacent children inside [splitId].
  static LayoutNode updateChildSizes(
    LayoutNode root, {
    required String splitId,
    required int firstIndex,
    required LayoutSize firstSize,
    required LayoutSize secondSize,
  }) {
    return updateNode(root, splitId, (node) {
      if (node is! SplitContainer) return node;
      if (firstIndex < 0 || firstIndex + 1 >= node.children.length) return node;
      final list = List<LayoutNode>.of(node.children);
      list[firstIndex] = list[firstIndex].withSize(firstSize);
      list[firstIndex + 1] = list[firstIndex + 1].withSize(secondSize);
      return node.copyWith(children: list);
    });
  }

  /// Removes a widget item by [itemId] from whichever [GroupContainer] owns it.
  static LayoutNode removeWidgetItem(LayoutNode root, String itemId) {
    LayoutNode visit(LayoutNode current) {
      return switch (current) {
        GroupContainer(:final items) => () {
          final filtered = items.where((i) => i.id != itemId).toList();
          return filtered.length == items.length ? current : current.copyWith(items: filtered);
        }(),
        SplitContainer(:final children) => () {
          var changed = false;
          final next = <LayoutNode>[];
          for (final c in children) {
            final updated = visit(c);
            if (!identical(updated, c)) changed = true;
            next.add(updated);
          }
          return changed ? current.copyWith(children: next) : current;
        }(),
      };
    }

    return visit(root);
  }

  /// Removes all widget items of [widgetType] across the entire tree.
  static LayoutNode removeWidgetTypeEverywhere(LayoutNode root, String widgetType) {
    LayoutNode visit(LayoutNode current) {
      return switch (current) {
        GroupContainer(:final items) => () {
          final filtered = items.where((i) => i.type != widgetType).toList();
          return filtered.length == items.length ? current : current.copyWith(items: filtered);
        }(),
        SplitContainer(:final children) => () {
          var changed = false;
          final next = <LayoutNode>[];
          for (final c in children) {
            final updated = visit(c);
            if (!identical(updated, c)) changed = true;
            next.add(updated);
          }
          return changed ? current.copyWith(children: next) : current;
        }(),
      };
    }

    return visit(root);
  }

  /// Moves or inserts a widget into [targetGroupId] at [targetIndex].
  static LayoutNode placeWidget({
    required LayoutNode root,
    required String widgetType,
    required String targetGroupId,
    required int targetIndex,
    String? sourceItemId,
    bool allowMultiple = false,
  }) {
    var nextRoot = root;
    var adjustedIndex = targetIndex;

    if (sourceItemId != null) {
      final target = findNode(nextRoot, targetGroupId);
      if (target is GroupContainer) {
        final oldIdx = target.items.indexWhere((i) => i.id == sourceItemId);
        if (oldIdx != -1 && oldIdx < adjustedIndex) {
          adjustedIndex--;
        }
      }
      nextRoot = removeWidgetItem(nextRoot, sourceItemId);
    } else if (!allowMultiple) {
      final target = findNode(nextRoot, targetGroupId);
      if (target is GroupContainer) {
        final existingIdx = target.items.indexWhere((i) => i.type == widgetType);
        if (existingIdx != -1 && existingIdx < adjustedIndex) {
          adjustedIndex--;
        }
      }
      nextRoot = removeWidgetTypeEverywhere(nextRoot, widgetType);
    }

    final item = LayoutWidgetItem(id: sourceItemId ?? nextLayoutId('w'), type: widgetType);
    return updateNode(nextRoot, targetGroupId, (node) {
      if (node is! GroupContainer) return node;
      final list = List<LayoutWidgetItem>.of(node.items);
      list.insert(adjustedIndex.clamp(0, list.length), item);
      return node.copyWith(items: list);
    });
  }
}
