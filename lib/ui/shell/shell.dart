import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nordplayer/ui/shell/title_bar/title_bar.dart';

class Shell extends ConsumerWidget {
  final Widget child;

  const new({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Column(
        children: [
          const TitleBar(),
          Expanded(child: ClipRect(child: child)),
        ],
      ),
    );
  }
}
