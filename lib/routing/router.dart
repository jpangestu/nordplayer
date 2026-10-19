import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nordplayer/ui/library/library_view.dart';

abstract final class Routes {
  static const libraryView = '/library';
  static const tracksView = '/tracks';
  static const playlistsView = '/playlists';
  static const albumsView = '/albums';
  static const artistsView = '/artists';
}

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

final router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: Routes.libraryView,
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) => navigationShell,
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(path: Routes.libraryView, builder: (context, state) => const LibraryView()),
          ],
        ),
      ],
    ),
  ],
);
