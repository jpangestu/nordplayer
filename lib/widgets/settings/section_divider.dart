import 'package:material_ui/material_ui.dart';

class SectionDivider extends StatelessWidget {
  const SectionDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Divider(height: 1, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1));
  }
}
