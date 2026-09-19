import 'package:flutter/painting.dart';

/// Configuration describing the layout and visibility properties of a table column.
class TableColumnConfig {
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

  /// The alignment of the cell content. Defaults to [Alignment.centerLeft].
  final Alignment alignment;

  /// Determines if the layout should calculate and render this column.
  final bool isVisible;

  const TableColumnConfig({
    required this.id,
    required this.label,
    this.minWidth = 50.0,
    this.width,
    this.flex,
    this.alignment = Alignment.centerLeft,
    this.isVisible = true,
  }) : assert(
         (width != null || flex != null) && !(width != null && flex != null),
         'A TableColumnConfig must provide exactly one of either width or flex.',
       );

  TableColumnConfig copyWith({
    bool? isVisible,
    double? width,
    double? flex,
  }) {
    return TableColumnConfig(
      id: id,
      label: label,
      minWidth: minWidth,
      width: width ?? this.width,
      flex: flex ?? this.flex,
      alignment: alignment,
      isVisible: isVisible ?? this.isVisible,
    );
  }
}
