import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nordplayer/routing/navigation_history.dart';
import 'package:nordplayer/ui/shared/themes/icon_sets/app_icon_set.dart';
import 'package:nordplayer/ui/shared/ui/app_icon.dart';
import 'package:nordplayer/ui/shell/shell_viewmodel.dart';
import 'package:nordplayer/ui/shell/widgets/nord_search_bar.dart';

class NordAppBar extends ConsumerStatefulWidget implements PreferredSizeWidget {
  const NordAppBar({super.key});

  @override
  ConsumerState<NordAppBar> createState() => _NordplayerAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(60.0);
}

class _NordplayerAppBarState extends ConsumerState<NordAppBar> {
  @override
  Widget build(BuildContext context) {
    final appIconSet = ref.watch(appIconProvider);
    final theme = Theme.of(context);
    final shellState = ref.watch(shellViewModelProvider);

    final navHistory = ref.watch(navigationHistoryProvider);
    final canGoBack = navHistory.canGoBack;
    final canGoForward = navHistory.canGoForward;

    return AppBar(
      backgroundColor: shellState.isAdaptiveBg ? Colors.transparent : theme.colorScheme.surfaceContainer,
      toolbarHeight: 60,
      elevation: 0,
      // To disable the surface tint color when app bar is scrolled
      scrolledUnderElevation: 0,
      flexibleSpace: shellState.isAdaptiveBg
          ? ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: shellState.adaptiveBgPanelBlur,
                  sigmaY: shellState.adaptiveBgPanelBlur,
                  tileMode: TileMode.mirror,
                ),
                child: Container(
                  color: Theme.of(context).colorScheme.surfaceContainer
                      .withValues(alpha: shellState.adaptiveBgThemeOverlay),
                ),
              ),
            )
          : const SizedBox.shrink(),
      leadingWidth: 104,
      leading: Padding(
        padding: const EdgeInsets.only(left: 12.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              // Slight offset to look more centered
              icon: Transform.translate(offset: const Offset(-1.0, 0.0), child: AppIcon(appIconSet.navigationLeft)),
              padding: const EdgeInsets.all(6.0),
              constraints: const BoxConstraints(),
              style: IconButton.styleFrom(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
              onPressed: canGoBack ? () => ref.read(navigationHistoryProvider.notifier).goBack() : null,
            ),
            const SizedBox(width: 0),
            IconButton(
              icon: Transform.translate(offset: const Offset(1.0, 0.0), child: AppIcon(appIconSet.navigationRight)),
              padding: const EdgeInsets.all(6.0),
              constraints: const BoxConstraints(),
              style: IconButton.styleFrom(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
              onPressed: canGoForward ? () => ref.read(navigationHistoryProvider.notifier).goForward() : null,
            ),
          ],
        ),
      ),
      centerTitle: true,
      title: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: (MediaQuery.sizeOf(context).width * 0.4).clamp(200, 400)),
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(22),
          ),
          child: const NordSearchBar(),
        ),
      ),
    );
  }
}
