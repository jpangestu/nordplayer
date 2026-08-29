import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nordplayer/widgets/popover_panel.dart';

/// Represents a single selectable option in a [SelectPopover].
class const SelectPopoverOption<T>({
  required final String title,
  required final T value,
  final bool? isSelected,
  final VoidCallback? onTap,
}) {}

/// Base interface for popover sections to support heterogeneous option lists.
abstract class SelectPopoverSectionBase {
  String? get title;
  List<SelectPopoverOption<dynamic>> get options;
  bool isOptionSelected(SelectPopoverOption<dynamic> option);
  void selectOption(dynamic value);
}

/// Represents a grouped section of selectable options in a [SelectPopover].
class const SelectPopoverSection<T>({
  @override final String? title,
  @override required final List<SelectPopoverOption<T>> options,
  final T? selectedValue,
  final ValueChanged<T>? onSelected,
}) implements SelectPopoverSectionBase {
  @override
  bool isOptionSelected(SelectPopoverOption<dynamic> option) {
    if (option.isSelected != null) return option.isSelected!;
    return selectedValue != null && option.value == selectedValue;
  }

  @override
  void selectOption(dynamic value) {
    if (value is T) onSelected?.call(value);
  }
}

/// A 2-column option item row displaying a check icon when selected and the option title text.
class const SelectPopoverItem({
  super.key,
  required final String title,
  required final bool isSelected,
  final VoidCallback? onTap,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 1.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            height: 36.0,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                // Column 1: Checkmark symbol (visible when selected)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: isSelected ? Icon(Icons.check, size: 18, color: colorScheme.primary) : null,
                ),

                const SizedBox(width: 10),

                // Column 2: Option title
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A Popover content widget for displaying selectable option lists with checkmarks and sections.
class const SelectPopover({
  super.key,
  final List<SelectPopoverSectionBase>? sections,
  final List<SelectPopoverSectionBase> Function(BuildContext context, WidgetRef ref)? sectionsBuilder,
  final double width = 200.0,
  final bool closeOnSelect = true,
}) extends ConsumerWidget {
  this : assert(sections != null || sectionsBuilder != null, 'Sections or sectionsBuilder must be provided');

  /// Displays a [SelectPopover] anchored to [anchorKey].
  static Future<dynamic> show({
    required BuildContext context,
    required GlobalKey anchorKey,
    List<SelectPopoverSectionBase>? sections,
    List<SelectPopoverSectionBase> Function(BuildContext context, WidgetRef ref)? sectionsBuilder,
    double width = 200.0,
    EdgeInsets padding = const EdgeInsets.symmetric(vertical: 8.0, horizontal: 24.0),
    bool closeOnSelect = true,
  }) {
    return showPopover<dynamic>(
      context: context,
      anchorKey: anchorKey,
      width: width,
      padding: padding,
      child: SelectPopover(
        sections: sections,
        sectionsBuilder: sectionsBuilder,
        width: width,
        closeOnSelect: closeOnSelect,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final resolvedSections = sectionsBuilder?.call(context, ref) ?? sections ?? [];

    return PopoverPanel(
      width: width,
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < resolvedSections.length; i++) ...[
            if (i > 0)
              Divider(height: 12, thickness: 1, color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
            if (resolvedSections[i].title != null)
              Padding(
                padding: const EdgeInsets.only(left: 12.0, right: 12.0, top: 4.0, bottom: 6.0),
                child: Text(
                  resolvedSections[i].title!.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    letterSpacing: 1.0,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            for (final option in resolvedSections[i].options)
              SelectPopoverItem(
                title: option.title,
                isSelected: resolvedSections[i].isOptionSelected(option),
                onTap: () {
                  if (option.onTap != null) {
                    option.onTap!();
                  } else {
                    resolvedSections[i].selectOption(option.value);
                  }
                  if (closeOnSelect) {
                    Navigator.of(context, rootNavigator: true).pop(option.value);
                  }
                },
              ),
          ],
        ],
      ),
    );
  }
}
