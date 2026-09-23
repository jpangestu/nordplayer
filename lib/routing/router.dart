import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nordplayer/ui/albums/album_detail_view.dart';
import 'package:nordplayer/ui/albums/albums_view.dart';
import 'package:nordplayer/ui/artists/artists_view.dart';
import 'package:nordplayer/ui/library/library_view.dart';
import 'package:nordplayer/ui/playlists/playlist_detail_view.dart';
import 'package:nordplayer/ui/playlists/playlists_view.dart';
import 'package:nordplayer/ui/settings/about/about_view.dart';
import 'package:nordplayer/ui/settings/about/license_view.dart';
import 'package:nordplayer/ui/settings/advanced/advanced_settings_view.dart';
import 'package:nordplayer/ui/settings/appearance/appearance_view.dart';
import 'package:nordplayer/ui/settings/library_indexer/duplicates_view.dart';
import 'package:nordplayer/ui/settings/library_indexer/ignored_paths_view.dart';
import 'package:nordplayer/ui/settings/library_indexer/library_indexer_view.dart';
import 'package:nordplayer/ui/settings/settings_layout.dart';
import 'package:nordplayer/ui/shell/app_layout.dart';
import 'package:nordplayer/ui/tracks/tracks_view.dart';

class Routes {
  static const albumsPage = '/albums';
  static const tracksPage = '/tracks';
  static const artistsPage = '/artists';
  static const libraryPage = '/library';
  static const playlistsPage = '/playlists';

  static const aboutPage = '/settings/about';
  static const licensesPage = 'licenses';
  static const advancePage = '/settings/advance';
  static const appearancePage = '/settings/appearance';
  static const libraryIndexerPage = '/settings/libraryIndexer';
  static const duplicatesPage = 'duplicates';
  static const ignoredPathsPage = 'ignoredPaths';
}

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

final router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: Routes.libraryPage,
  routes: [
    // Just so the user can go back to initial page if routing went wrong
    GoRoute(path: '/', redirect: (context, state) => Routes.libraryPage),

    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) => AppLayout(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [GoRoute(path: Routes.libraryPage, builder: (context, state) => const LibraryView())],
        ),
        StatefulShellBranch(
          routes: [GoRoute(path: Routes.tracksPage, builder: (context, state) => const TracksView())],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.playlistsPage,
              builder: (context, state) => const PlaylistsView(),
              routes: [
                GoRoute(
                  path: ':id',
                  builder: (context, state) {
                    final playlistIdStr = state.pathParameters['id']!;
                    final playlistId = int.parse(playlistIdStr);

                    return PlaylistDetailView(playlistId: playlistId);
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
              builder: (context, state) => const AlbumsView(),
              routes: [
                GoRoute(
                  path: ':id',
                  builder: (context, state) {
                    final albumIdStr = state.pathParameters['id']!;
                    final albumId = int.parse(albumIdStr);

                    return AlbumDetailView(albumId: albumId);
                  },
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [GoRoute(path: Routes.artistsPage, builder: (context, state) => const ArtistsView())],
        ),
        StatefulShellBranch(
          routes: [
            StatefulShellRoute.indexedStack(
              builder: (context, state, navigationShell) => SettingsLayout(navigationShell: navigationShell),
              branches: [
                StatefulShellBranch(
                  routes: [GoRoute(path: Routes.appearancePage, builder: (context, state) => const AppearanceView())],
                ),
                StatefulShellBranch(
                  routes: [
                    GoRoute(
                      path: Routes.libraryIndexerPage,
                      builder: (context, state) => const LibraryIndexerView(),
                      routes: [
                        GoRoute(
                          path: Routes.duplicatesPage,
                          builder: (context, state) {
                            return const DuplicatesView();
                          },
                          routes: [
                            GoRoute(
                              path: Routes.ignoredPathsPage,
                              builder: (context, state) => const IgnoredPathsView(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                StatefulShellBranch(
                  routes: [
                    GoRoute(path: Routes.advancePage, builder: (context, state) => const AdvancedSettingsView()),
                  ],
                ),
                StatefulShellBranch(
                  routes: [
                    GoRoute(
                      path: Routes.aboutPage,
                      builder: (context, state) => const AboutView(),
                      routes: [GoRoute(path: Routes.licensesPage, builder: (context, state) => const LicensesView())],
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
