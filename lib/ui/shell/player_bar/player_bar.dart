import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nordplayer/config/app_config.dart';
import 'package:nordplayer/ui/shell/adaptive_surface.dart';

class PlayerBar extends ConsumerWidget {
  const PlayerBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appConfig = ref.watch(appConfigProvider);
    final playerBarHeight = ref.watch(appConfig.ui.playerBar.height.provider);

    return AdaptiveSurface(elevation: .mid, height: playerBarHeight, child: const Placeholder());
  }
}
