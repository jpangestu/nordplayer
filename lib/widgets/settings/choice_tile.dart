import 'package:flutter/material.dart';

class ChoiceTile extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback onTap;
  final double verticalPadding;

  const ChoiceTile({
    super.key,
    required this.label,
    this.icon,
    required this.isSelected,
    required this.onTap,
    this.verticalPadding = 12,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final Color borderColor = isSelected ? colorScheme.primary : colorScheme.outlineVariant;
    final Color backgroundColor = isSelected ? colorScheme.primary.withValues(alpha: 0.1) : Colors.transparent;
    final Color contentColor = isSelected ? colorScheme.primary : colorScheme.onSurface;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: verticalPadding, horizontal: 16),
            decoration: BoxDecoration(
              color: backgroundColor,
              border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: .center,
              children: [
                if (icon != null) ...[Icon(icon, color: contentColor, size: 20), const SizedBox(width: 12)],
                Text(
                  label,
                  style: TextStyle(
                    color: contentColor,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 15,
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
