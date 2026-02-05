import 'package:flutter/material.dart';
import 'package:suara/pages/albums_page.dart';
import 'package:suara/pages/artists_page.dart';
import 'package:suara/pages/library_page.dart';
import 'package:suara/pages/settings/settings_page.dart';
import 'package:suara/widgets/dynamic_background_scaffold.dart';
import 'package:suara/widgets/player_bar.dart';
import 'package:suara/widgets/sidebar.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  int _selectedIndex = 0;

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

  Route<dynamic> _onGenerateRoute(RouteSettings settings) {
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
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
    );

    // return PageRouteBuilder(
    //   pageBuilder: (context, animation, secondaryAnimation) => page,
    //   transitionsBuilder: (context, animation, secondaryAnimation, child) {
    //     // Defines how the new page appears
    //     return FadeTransition(opacity: animation, child: child);
    //   },
    // );

    // return PageRouteBuilder(
    //   pageBuilder: (context, animation, secondaryAnimation) => page,
    //   transitionDuration: const Duration(milliseconds: 300), // Slower/Faster
    //   transitionsBuilder: (context, animation, secondaryAnimation, child) {
    //     const begin = Offset(1.0, 0.0); // Slide from Right
    //     // const begin = Offset(0.0, 1.0); // Slide from Bottom
    //     const end = Offset.zero;
    //     const curve = Curves.easeInOut;

    //     var tween = Tween(
    //       begin: begin,
    //       end: end,
    //     ).chain(CurveTween(curve: curve));

    //     return SlideTransition(position: animation.drive(tween), child: child);
    //   },
    // );
  }

  @override
  Widget build(BuildContext context) {
    return DynamicBackgroundScaffold(
      body: Row(
        children: [
          Sidebar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _onDestinationSelected,
          ),
          const VerticalDivider(width: 1),

          Expanded(
            child: Navigator(
              key: _navigatorKey,
              initialRoute: '/library',
              onGenerateRoute: _onGenerateRoute,
            ),
          ),
        ],
      ),
      bottomNavigationBar: const PlayerBar(),
    );
  }
}
