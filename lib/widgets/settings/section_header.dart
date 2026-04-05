import 'package:flutter/material.dart';

enum LabelType { h1, h2, h3 }

class SectionHeader extends StatelessWidget {
  final String label;
  final LabelType labelType;
  final EdgeInsetsGeometry padding;

  const SectionHeader({
    super.key,
    required this.label,
    required this.labelType,
    this.padding = const .symmetric(vertical: 8),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final textStyle = switch (labelType) {
      LabelType.h1 => theme.textTheme.titleLarge!.copyWith(
        color: theme.colorScheme.onSurface,
      ),
      LabelType.h2 => theme.textTheme.titleMedium!.copyWith(
        color: theme.colorScheme.onSurface,
      ),
      LabelType.h3 => theme.textTheme.titleSmall!.copyWith(
        color: theme.colorScheme.onSurface,
      ),
    };

    return Padding(
      padding: padding,
      child: Text(label, style: textStyle),
    );
  }
}
