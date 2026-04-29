import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nordplayer/routes/router.dart';
import 'package:nordplayer/services/config_service.dart';
import 'package:nordplayer/theming/icon-sets/app_icon_set.dart';
import 'package:nordplayer/widgets/app_icon.dart';

class NordplayerAppBar extends ConsumerStatefulWidget implements PreferredSizeWidget {
  const NordplayerAppBar({super.key});

  @override
  ConsumerState<NordplayerAppBar> createState() => _NordplayerAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(60.0);
}

class _NordplayerAppBarState extends ConsumerState<NordplayerAppBar> {
  @override
  Widget build(BuildContext context) {
    final appIconSet = ref.watch(appIconProvider);
    final theme = Theme.of(context);
    final appConfig = ref.watch(configServiceProvider).requireValue;

    final currentRoute = GoRouterState.of(context).uri.path;
    final bool isMainTabRoot =
        currentRoute == Routes.libraryPage ||
        currentRoute == Routes.allTracksPage ||
        currentRoute == Routes.playlistsPage ||
        currentRoute == Routes.albumsPage ||
        currentRoute == Routes.artistsPage;
    final bool isSettingsRoute = currentRoute.startsWith('/settings');
    final bool isSettingsRoot =
        currentRoute == Routes.appearancePage ||
        currentRoute == Routes.aboutPage ||
        currentRoute == Routes.advancePage ||
        currentRoute == Routes.libraryManagementPage;
    final bool isNestedPage = !isMainTabRoot && !isSettingsRoot;

    final bool showBackButton = isSettingsRoute || isNestedPage;

    return AppBar(
      backgroundColor: appConfig.adaptiveBg ? Colors.transparent : theme.colorScheme.surfaceContainer,
      toolbarHeight: 60,
      elevation: 0,
      // To disable the surface tint color when app bar is scrolled
      scrolledUnderElevation: 0,
      flexibleSpace: appConfig.adaptiveBg
          ? ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: appConfig.adaptiveBgPanelBlur,
                  sigmaY: appConfig.adaptiveBgPanelBlur,
                  tileMode: .mirror,
                ),
                child: Container(
                  color: Theme.of(
                    context,
                  ).colorScheme.surfaceContainer.withValues(alpha: appConfig.adaptiveBgThemeOverlay),
                ),
              ),
            )
          : const SizedBox.shrink(),
      leading: (showBackButton)
          ? IconButton(
              icon: AppIcon(appIconSet.navigationBack),
              onPressed: () {
                if (isSettingsRoot) {
                  // We are at the base of a settings tab. Go back to the main app.
                  final lastRoute = ref.read(lastMainRouteProvider);
                  context.go(lastRoute);
                } else {
                  // We are deep in a tab (e.g., /playlists/123 OR /settings/about/licenses).
                  // Dynamically slice the URL to go up one parent folder!
                  final parentRoute = currentRoute.substring(0, currentRoute.lastIndexOf('/'));

                  // Safety fallback: if string manipulation results in empty string, go to library
                  context.go(parentRoute.isEmpty ? Routes.libraryPage : parentRoute);
                }
              },
            )
          : null,
      centerTitle: true,
      title: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: (MediaQuery.sizeOf(context).width * 0.4).clamp(200, 500)),
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
              prefixIcon: AppIcon(appIconSet.search, size: 20),
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
              ref.read(lastMainRouteProvider.notifier).updateRoute(currentRoute);
              context.go('/settings/appearance');
            }
          },
          icon: AppIcon(appIconSet.settings, color: isSettingsRoute ? theme.colorScheme.primary : null),
          // selectedIcon: AppIcon(Icons.settings),
          // isSelected: isSettingsRoute,
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}
