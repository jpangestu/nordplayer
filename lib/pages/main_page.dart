import 'package:flutter/material.dart';
import 'package:nordplayer/pages/albums_page.dart';
import 'package:nordplayer/pages/artists_page.dart';
import 'package:nordplayer/pages/library_page.dart';
import 'package:nordplayer/pages/settings/settings_page.dart';
import 'package:nordplayer/widgets/player_bar.dart';
import 'package:nordplayer/widgets/sidebar.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  int _selectedIndex = 0;
  bool isExpanded = false;

  void _onDestinationSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        _navigatorKey.currentState!.pushReplacementNamed('/library');
        break;
      case 1:
        _navigatorKey.currentState!.pushReplacementNamed('/albums');
        break;
      case 2:
        _navigatorKey.currentState!.pushReplacementNamed('/artists');
        break;
      case 3:
        _navigatorKey.currentState!.pushReplacementNamed('/settings');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Sidebar(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: _onDestinationSelected,
                ),
                Expanded(
                  child: Navigator(
                    key: _navigatorKey,
                    initialRoute: '/library',
                    onGenerateRoute: (RouteSettings settings) {
                      Widget page;
                      switch (settings.name) {
                        case '/library':
                          page = const LibraryPage();
                          break;
                        case '/albums':
                          page = const AlbumsPage();
                          break;
                        case '/artists':
                          page = const ArtistsPage();
                          break;
                        case '/settings':
                          page = const SettingsPage();
                          break;
                        default:
                          page = const LibraryPage();
                      }
                      return PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            page,
                        transitionDuration: Duration.zero,
                        reverseTransitionDuration: Duration.zero,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          PlayerBar(),
        ],
      ),
    );
  }
}
