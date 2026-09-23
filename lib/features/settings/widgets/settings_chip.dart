import 'package:material_ui/material_ui.dart';
import 'package:nordplayer/widgets/app_icon.dart';
import 'package:nordplayer/widgets/frosted_glass.dart';

class SettingsChip extends StatelessWidget {
  final String label;
  final VoidCallback? onDelete;
  final bool isAdaptive;

  const SettingsChip({
    super.key,
    required this.label,
    this.onDelete,
    this.isAdaptive = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FrostedGlass(
      borderRadius: 8.0,
      backgroundColor: isAdaptive
          ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
          : theme.colorScheme.surfaceContainerHighest,
      blurSigma: isAdaptive ? 8.0 : 0.0,
      child: Container(
        height: 32, // Matches VisualDensity.compact
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(color: theme.colorScheme.outline.withValues(alpha: isAdaptive ? 0.3 : 0.8), width: 1),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(width: 10),
              Text('"$label"', style: theme.textTheme.labelLarge),
              if (onDelete != null) ...[
                const SizedBox(width: 4),
                InkWell(
                  borderRadius: BorderRadius.circular(50),
                  onTap: onDelete,
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: AppIcon(Icons.close, size: 16, color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
                const SizedBox(width: 4),
              ] else ...[
                const SizedBox(width: 10),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
