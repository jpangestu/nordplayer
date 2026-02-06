import 'package:flutter/material.dart';
import 'package:nordplayer/theme/nord_theme.dart';
import 'package:nordplayer/pages/main_page.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    size: Size(1080, 720),
    minimumSize: Size(800, 600),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    windowButtonVisibility: true,
    title: 'Nordplayer',
    titleBarStyle: .normal,
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const NordplayerApp());
}

class NordplayerApp extends StatefulWidget {
  const NordplayerApp({super.key});

  @override
  State<NordplayerApp> createState() => _NordplayerAppState();
}

class _NordplayerAppState extends State<NordplayerApp> with WindowListener {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nordplayer',
      theme: nordTheme,
      home: const MainPage(),
    );
  }
}
