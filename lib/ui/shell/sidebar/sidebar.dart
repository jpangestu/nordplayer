import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nordplayer/config/app_config.dart';
import 'package:nordplayer/ui/shell/adaptive_surface.dart';

class Sidebar extends ConsumerWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appConfig = ref.watch(appConfigProvider);
    final sidebarWidth = ref.watch(appConfig.ui.sidebar.width.provider);

    return AdaptiveSurface(elevation: .mid, width: sidebarWidth, child: const Placeholder());
  }
}
