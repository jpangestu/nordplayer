import 'package:flutter/material.dart';
import 'package:suara/services/theme_service.dart';
import 'package:window_manager/window_manager.dart';
import 'package:metadata_god/metadata_god.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';

import 'package:suara/main_layout.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Handle app window size
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    // Default (not expanded) size at app first launch
    size: Size(1200, 720),
    minimumSize: Size(800, 600),
    center: true,
    titleBarStyle: TitleBarStyle.normal,
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  // Initalize metadata parser
  await MetadataGod.initialize();

  // Initialize just_audio
  JustAudioMediaKit.ensureInitialized();

  // Load current theme
  await ThemeService().loadTheme();

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
    windowManager.addListener(this);
  }

  @override
  void dispose() {
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
    return StreamBuilder<ThemeMode>(
      stream: ThemeService().themeStream,
      initialData: ThemeService().currentTheme,
      builder: (context, snapshot) {
        return MaterialApp(
          title: 'Suara',
          // The Magic:
          themeMode: snapshot.data,
          theme: ThemeData.light(), // Customize these later
          darkTheme: ThemeData.dark(),
          home: const MainLayout(),
        );
      },
    );
  }
}
