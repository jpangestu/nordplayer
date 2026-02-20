import 'package:flutter/material.dart';

enum LabelType { h1, h2, h3 }

class SectionHeader extends StatelessWidget {
  final String label;
  final LabelType labelType;

  const SectionHeader({
    super.key,
    required this.label,
    required this.labelType,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final textStyle = switch (labelType) {
      LabelType.h1 => theme.textTheme.titleLarge!.copyWith(color: theme.colorScheme.primary),
      LabelType.h2 => theme.textTheme.titleMedium!.copyWith(color: theme.colorScheme.primary),
      LabelType.h3 => theme.textTheme.titleSmall!.copyWith(color: theme.colorScheme.primary),
    };

    return Padding(
      padding: const .symmetric(vertical: 8),
      child: Text(
        label,
        style: textStyle,
      ),
    );
  }
}
