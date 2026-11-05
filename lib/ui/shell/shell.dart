import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nordplayer/ui/shell/adaptive_scaffold.dart';
import 'package:nordplayer/ui/shell/title_bar/title_bar.dart';

class Shell extends ConsumerWidget {
  final Widget child;

  const Shell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdaptiveScaffold(
      child: Column(
        children: [
          const TitleBar(),
          Expanded(child: ClipRect(child: child)),
        ],
      ),
    );
  }
}
