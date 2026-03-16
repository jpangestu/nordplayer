import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nordplayer/routes/router.dart';
import 'package:nordplayer/routes/routes.dart';

class NordplayerAppBar extends ConsumerStatefulWidget
    implements PreferredSizeWidget {
  const NordplayerAppBar({super.key});

  @override
  ConsumerState<NordplayerAppBar> createState() => _NordplayerAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(60.0);
}

class _NordplayerAppBarState extends ConsumerState<NordplayerAppBar> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final currentRoute = GoRouterState.of(context).uri.toString();
    final bool isSettingsRoute = currentRoute.startsWith(Routes.settingsPage);
    final bool canPop = context.canPop();

    return AppBar(
      backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.90),
      toolbarHeight: 60,
      scrolledUnderElevation: 0,
      leading: (isSettingsRoute || canPop)
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                if (isSettingsRoute) {
                  // Your custom settings exit logic
                  final lastRoute = ref.read(lastMainRouteProvider);
                  context.go(lastRoute);
                } else if (canPop) {
                  // Standard back navigation for playlists, albums, etc.
                  context.pop();
                }
              },
            )
          : null,
      centerTitle: true,
      title: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: (MediaQuery.sizeOf(context).width * 0.4).clamp(200, 500),
        ),
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(22),
          ),
          child: TextField(
            decoration: InputDecoration(
              hintText: "Ctrl + k to focus",
              hintStyle: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              prefixIcon: const Icon(Icons.search, size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
            onChanged: (value) {},
          ),
        ),
      ),
      actions: [
        IconButton(
          onPressed: () {
            if (isSettingsRoute) {
              final lastRoute = ref.read(lastMainRouteProvider);
              context.go(lastRoute);
            } else {
              ref
                  .read(lastMainRouteProvider.notifier)
                  .updateRoute(currentRoute);
              context.go('/settings/appearance');
            }
          },
          icon: const Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings),
          isSelected: isSettingsRoute,
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}
