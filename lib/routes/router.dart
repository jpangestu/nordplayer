import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nordplayer/pages/albums_page.dart';
import 'package:nordplayer/pages/artists_page.dart';
import 'package:nordplayer/pages/library_page.dart';
import 'package:nordplayer/pages/app_layout.dart';
import 'package:nordplayer/pages/playlists_page.dart';
import 'package:nordplayer/pages/playlist_details_page.dart';
import 'package:nordplayer/pages/settings/advanced_page.dart';
import 'package:nordplayer/pages/settings/appearance_page.dart';
import 'package:nordplayer/pages/settings/library_management_page.dart';
import 'package:nordplayer/pages/settings/settings_layout.dart';
import 'package:nordplayer/routes/routes.dart';

class LastMainRoute extends Notifier<String> {
  @override
  String build() => Routes.libraryPage;

  void updateRoute(String newRoute) {
    state = newRoute;
  }
}

final lastMainRouteProvider = NotifierProvider<LastMainRoute, String>(() {
  return LastMainRoute();
});

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

final router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: Routes.libraryPage,
  routes: [
    GoRoute(path: '/', redirect: (context, state) => Routes.libraryPage),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          AppLayout(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.libraryPage,
              builder: (context, state) => const LibraryPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.playlistsPage,
              builder: (context, state) => const PlaylistsPage(),
              routes: [
                GoRoute(
                  path: ':id',
                  builder: (context, state) {
                    final playlistIdStr = state.pathParameters['id']!;
                    final playlistId = int.parse(playlistIdStr);

                    return PlaylistDetailPage(playlistId: playlistId);
                  },
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.albumsPage,
              builder: (context, state) => const AlbumsPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.artistsPage,
              builder: (context, state) => const ArtistsPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.settingsPage,
              redirect: (context, state) =>
                  state.uri.path == Routes.settingsPage
                  ? '/settings/appearance'
                  : null,
              routes: [
                StatefulShellRoute.indexedStack(
                  builder: (context, state, navigationShell) =>
                      SettingsLayout(navigationShell: navigationShell),
                  branches: [
                    StatefulShellBranch(
                      routes: [
                        GoRoute(
                          path: Routes.appearancePage,
                          builder: (context, state) => const AppearancePage(),
                        ),
                      ],
                    ),
                    StatefulShellBranch(
                      routes: [
                        GoRoute(
                          path: Routes.libraryManagementPage,
                          builder: (context, state) =>
                              const LibraryManagementPage(),
                        ),
                      ],
                    ),
                    StatefulShellBranch(
                      routes: [
                        GoRoute(
                          path: Routes.advancePage,
                          builder: (context, state) => const AdvancedPage(),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
);
