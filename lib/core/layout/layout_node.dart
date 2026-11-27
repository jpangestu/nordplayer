import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart'
    show CrossAxisAlignment, EdgeInsets, MainAxisAlignment;

/// Direction along which a container lays out its children.
enum const LayoutAxis(final String label) {
  horizontal('Horizontal'),
  vertical('Vertical');

  LayoutAxis get opposite =>
      this == LayoutAxis.horizontal ? LayoutAxis.vertical : LayoutAxis.horizontal;
}

/// Main-axis alignment for widgets inside a [GroupContainer].
enum const LayoutAlign(final String label) {
  start('Start'),
  center('Center'),
  end('End'),
  spaceBetween('Space Between');

  MainAxisAlignment get mainAxis => switch (this) {
    LayoutAlign.start => MainAxisAlignment.start,
    LayoutAlign.center => MainAxisAlignment.center,
    LayoutAlign.end => MainAxisAlignment.end,
    LayoutAlign.spaceBetween => MainAxisAlignment.spaceBetween,
  };
}

/// Cross-axis alignment for widgets inside a [GroupContainer]
/// (vertical alignment on a horizontal Row; horizontal alignment on a vertical Column).
enum const LayoutCrossAlign(final String label) {
  start('Start'),
  center('Center'),
  end('End'),
  stretch('Stretch');

  CrossAxisAlignment get crossAxis => switch (this) {
    LayoutCrossAlign.start => CrossAxisAlignment.start,
    LayoutCrossAlign.center => CrossAxisAlignment.center,
    LayoutCrossAlign.end => CrossAxisAlignment.end,
    LayoutCrossAlign.stretch => CrossAxisAlignment.stretch,
  };
}

/// Sizing policy of a pane inside a [SplitContainer].
@immutable
sealed class const LayoutSize({final double minExtent = 32.0, final double? maxExtent}) {
  String get shortLabel;

  Map<String, dynamic> toJson();

  static LayoutSize fromJson(dynamic json) {
    if (json is! Map) return const FlexSize(1.0);
    final type = json['type'];
    final minExtent = (json['minExtent'] is num)
        ? (json['minExtent'] as num).toDouble().clamp(0.0, 2000.0)
        : 32.0;
    final maxExtent = (json['maxExtent'] is num) ? (json['maxExtent'] as num).toDouble() : null;

    return switch (type) {
      'fixed' => FixedSize(
        (json['pixels'] is num) ? (json['pixels'] as num).toDouble().clamp(16.0, 4000.0) : 160.0,
        minExtent: minExtent,
        maxExtent: maxExtent,
      ),
      'fit' => FitContentSize(minExtent: minExtent, maxExtent: maxExtent),
      _ => FlexSize(
        (json['weight'] is num) ? (json['weight'] as num).toDouble().clamp(0.1, 100.0) : 1.0,
        minExtent: minExtent,
        maxExtent: maxExtent,
      ),
    };
  }
}

/// Proportional share of remaining space inside a [SplitContainer].
final class const FlexSize(final double weight, {super.minExtent = 32.0, super.maxExtent})
    extends LayoutSize {
  FlexSize copyWith({double? weight, double? minExtent, double? maxExtent}) => FlexSize(
    weight ?? this.weight,
    minExtent: minExtent ?? this.minExtent,
    maxExtent: maxExtent ?? this.maxExtent,
  );

  @override
  String get shortLabel => '${weight.toStringAsFixed(1)}fr';

  @override
  Map<String, dynamic> toJson() => {
    'type': 'flex',
    'weight': weight,
    if (minExtent != 32.0) 'minExtent': minExtent,
    if (maxExtent != null) 'maxExtent': maxExtent,
  };

  @override
  bool operator ==(Object other) =>
      other is FlexSize &&
      other.weight == weight &&
      other.minExtent == minExtent &&
      other.maxExtent == maxExtent;

  @override
  int get hashCode => Object.hash('flex', weight, minExtent, maxExtent);
}

/// Fixed pixel size inside a [SplitContainer] (still resizable via drag handles).
final class const FixedSize(final double pixels, {super.minExtent = 32.0, super.maxExtent})
    extends LayoutSize {
  FixedSize copyWith({double? pixels, double? minExtent, double? maxExtent}) => FixedSize(
    pixels ?? this.pixels,
    minExtent: minExtent ?? this.minExtent,
    maxExtent: maxExtent ?? this.maxExtent,
  );

  @override
  String get shortLabel => '${pixels.round()}px';

  @override
  Map<String, dynamic> toJson() => {
    'type': 'fixed',
    'pixels': pixels,
    if (minExtent != 32.0) 'minExtent': minExtent,
    if (maxExtent != null) 'maxExtent': maxExtent,
  };

  @override
  bool operator ==(Object other) =>
      other is FixedSize &&
      other.pixels == pixels &&
      other.minExtent == minExtent &&
      other.maxExtent == maxExtent;

  @override
  int get hashCode => Object.hash('fixed', pixels, minExtent, maxExtent);
}

/// Shrink-wraps to the child's intrinsic content extent along the parent split axis.
final class const FitContentSize({super.minExtent = 0.0, super.maxExtent}) extends LayoutSize {
  @override
  String get shortLabel => 'fit';

  @override
  Map<String, dynamic> toJson() => {
    'type': 'fit',
    if (minExtent != 0.0) 'minExtent': minExtent,
    if (maxExtent != null) 'maxExtent': maxExtent,
  };

  @override
  bool operator ==(Object other) =>
      other is FitContentSize && other.minExtent == minExtent && other.maxExtent == maxExtent;

  @override
  int get hashCode => Object.hash('fit', minExtent, maxExtent);
}

/// A generic widget entry inside a [GroupContainer].
@immutable
class const LayoutWidgetItem({required final String id, required final String type}) {
  Map<String, dynamic> toJson() => {'id': id, 'type': type};

  static LayoutWidgetItem? tryFromJson(dynamic json) {
    if (json is! Map) return null;
    final type = json['type'];
    if (type is! String || type.isEmpty) return null;
    final id = json['id'] is String && (json['id'] as String).isNotEmpty
        ? json['id'] as String
        : nextLayoutId('w');
    return LayoutWidgetItem(id: id, type: type);
  }

  @override
  bool operator ==(Object other) =>
      other is LayoutWidgetItem && other.id == id && other.type == type;

  @override
  int get hashCode => Object.hash(id, type);
}

int _layoutIdCounter = 0;

String nextLayoutId([String prefix = 'n']) => '${prefix}_${++_layoutIdCounter}';

/// Base class for all container nodes in a layout tree.
@immutable
sealed class const LayoutNode({
  required final String id,
  final LayoutSize size = const FlexSize(1.0),
}) {
  LayoutNode withSize(LayoutSize nextSize);

  Map<String, dynamic> toJson();

  static LayoutNode? tryFromJson(dynamic json) {
    if (json is! Map) return null;
    return switch (json['node']) {
      'split' => SplitContainer.tryFromJson(json),
      'group' => GroupContainer.tryFromJson(json),
      _ => null,
    };
  }
}

/// Structural container that divides space along [axis] into resizable child panes.
final class const SplitContainer({
  required super.id,
  super.size = const FlexSize(1.0),
  final LayoutAxis axis = LayoutAxis.horizontal,
  final double spacing = 0.0,
  final EdgeInsets padding = EdgeInsets.zero,
  final List<LayoutNode> children = const [],
}) extends LayoutNode {
  @override
  SplitContainer withSize(LayoutSize nextSize) => copyWith(size: nextSize);

  SplitContainer copyWith({
    LayoutSize? size,
    LayoutAxis? axis,
    double? spacing,
    EdgeInsets? padding,
    List<LayoutNode>? children,
  }) {
    return SplitContainer(
      id: id,
      size: size ?? this.size,
      axis: axis ?? this.axis,
      spacing: spacing ?? this.spacing,
      padding: padding ?? this.padding,
      children: children != null ? List.unmodifiable(children) : this.children,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'node': 'split',
    'id': id,
    'size': size.toJson(),
    'axis': axis.name,
    if (spacing != 0.0) 'spacing': spacing,
    if (padding != EdgeInsets.zero)
      'padding': [padding.left, padding.top, padding.right, padding.bottom],
    'children': [for (final child in children) child.toJson()],
  };

  static SplitContainer? tryFromJson(dynamic json) {
    if (json is! Map) return null;
    final id = json['id'] is String && (json['id'] as String).isNotEmpty
        ? json['id'] as String
        : nextLayoutId('s');
    final axis =
        LayoutAxis.values.where((a) => a.name == json['axis']).firstOrNull ?? LayoutAxis.horizontal;
    final spacing = (json['spacing'] is num)
        ? (json['spacing'] as num).toDouble().clamp(0.0, 64.0)
        : 0.0;
    final size = LayoutSize.fromJson(json['size']);

    var padding = EdgeInsets.zero;
    if (json['padding'] is List && (json['padding'] as List).length == 4) {
      final p = (json['padding'] as List).map((v) => v is num ? v.toDouble() : 0.0).toList();
      padding = EdgeInsets.fromLTRB(p[0], p[1], p[2], p[3]);
    }

    final parsedChildren = <LayoutNode>[];
    if (json['children'] is List) {
      for (final raw in json['children'] as List) {
        final node = LayoutNode.tryFromJson(raw);
        if (node != null) parsedChildren.add(node);
      }
    }
    if (parsedChildren.isEmpty) return null;

    return SplitContainer(
      id: id,
      size: size,
      axis: axis,
      spacing: spacing,
      padding: padding,
      children: List.unmodifiable(parsedChildren),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is SplitContainer &&
      other.id == id &&
      other.size == size &&
      other.axis == axis &&
      other.spacing == spacing &&
      other.padding == padding &&
      listEquals(other.children, children);

  @override
  int get hashCode =>
      Object.hash('split', id, size, axis, spacing, padding, Object.hashAll(children));
}

/// Leaf container that arranges widgets along [axis] with [mainAlignment], [crossAlignment], [gap],
/// and [padding].
final class const GroupContainer({
  required super.id,
  super.size = const FlexSize(1.0),
  final LayoutAxis axis = LayoutAxis.horizontal,
  final LayoutAlign mainAlignment = LayoutAlign.center,
  final LayoutCrossAlign crossAlignment = LayoutCrossAlign.center,
  final double gap = 2.0,
  final EdgeInsets padding = EdgeInsets.zero,
  final List<LayoutWidgetItem> items = const [],
}) extends LayoutNode {
  @override
  GroupContainer withSize(LayoutSize nextSize) => copyWith(size: nextSize);

  GroupContainer copyWith({
    LayoutSize? size,
    LayoutAxis? axis,
    LayoutAlign? mainAlignment,
    LayoutCrossAlign? crossAlignment,
    double? gap,
    EdgeInsets? padding,
    List<LayoutWidgetItem>? items,
  }) {
    return GroupContainer(
      id: id,
      size: size ?? this.size,
      axis: axis ?? this.axis,
      mainAlignment: mainAlignment ?? this.mainAlignment,
      crossAlignment: crossAlignment ?? this.crossAlignment,
      gap: gap ?? this.gap,
      padding: padding ?? this.padding,
      items: items != null ? List.unmodifiable(items) : this.items,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'node': 'group',
    'id': id,
    'size': size.toJson(),
    'axis': axis.name,
    'mainAlignment': mainAlignment.name,
    'crossAlignment': crossAlignment.name,
    if (gap != 2.0) 'gap': gap,
    if (padding != EdgeInsets.zero)
      'padding': [padding.left, padding.top, padding.right, padding.bottom],
    'items': [for (final item in items) item.toJson()],
  };

  static GroupContainer? tryFromJson(dynamic json) {
    if (json is! Map) return null;
    final id = json['id'] is String && (json['id'] as String).isNotEmpty
        ? json['id'] as String
        : nextLayoutId('g');
    final axis =
        LayoutAxis.values.where((a) => a.name == json['axis']).firstOrNull ?? LayoutAxis.horizontal;
    final mainAlignment =
        LayoutAlign.values.where((a) => a.name == json['mainAlignment']).firstOrNull ??
        LayoutAlign.center;
    final crossAlignment =
        LayoutCrossAlign.values.where((a) => a.name == json['crossAlignment']).firstOrNull ??
        LayoutCrossAlign.center;
    final gap = (json['gap'] is num) ? (json['gap'] as num).toDouble().clamp(0.0, 48.0) : 2.0;
    final size = LayoutSize.fromJson(json['size']);

    var padding = EdgeInsets.zero;
    if (json['padding'] is List && (json['padding'] as List).length == 4) {
      final p = (json['padding'] as List).map((v) => v is num ? v.toDouble() : 0.0).toList();
      padding = EdgeInsets.fromLTRB(p[0], p[1], p[2], p[3]);
    }

    final parsedItems = <LayoutWidgetItem>[];
    if (json['items'] is List) {
      for (final raw in json['items'] as List) {
        final item = LayoutWidgetItem.tryFromJson(raw);
        if (item != null) parsedItems.add(item);
      }
    }

    return GroupContainer(
      id: id,
      size: size,
      axis: axis,
      mainAlignment: mainAlignment,
      crossAlignment: crossAlignment,
      gap: gap,
      padding: padding,
      items: List.unmodifiable(parsedItems),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is GroupContainer &&
      other.id == id &&
      other.size == size &&
      other.axis == axis &&
      other.mainAlignment == mainAlignment &&
      other.crossAlignment == crossAlignment &&
      other.gap == gap &&
      other.padding == padding &&
      listEquals(other.items, items);

  @override
  int get hashCode => Object.hash(
    'group',
    id,
    size,
    axis,
    mainAlignment,
    crossAlignment,
    gap,
    padding,
    Object.hashAll(items),
  );
}
