import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import 'package:suara/pages/main_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    size: Size(1200, 800),
    minimumSize: Size(800, 600),
    center: true,
    titleBarStyle: TitleBarStyle.normal,
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const SuaraApp());
}

class SuaraApp extends StatefulWidget {
  const SuaraApp({super.key});

  @override
  State<SuaraApp> createState() => _SuaraAppState();
}

class _SuaraAppState extends State<SuaraApp> with WindowListener {
  @override
  void initState() {
    super.initState();
    // Listen to window events
    windowManager.addListener(this);
  }

  @override
  void dispose() {
    // Clean up listener when app closes
    windowManager.removeListener(this);
    super.dispose();
  }

  // Watch for when the window is "Un-maximized"
  @override
  void onWindowUnmaximize() {
    // Force the minimum size again immediately after restoring
    windowManager.setMinimumSize(const Size(800, 600));
  }

  // Catch standard resizing too just to be safe
  @override
  void onWindowResize() {
    // Some Linux WMs need a constant reminder
    windowManager.setMinimumSize(const Size(800, 600));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Suara',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
      ),
      home: const MainPage(),
    );
  }
}
