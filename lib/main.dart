import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:nordplayer/models/app_theme.dart';
import 'package:nordplayer/services/config_service.dart';
import 'package:nordplayer/services/preference_service.dart';
import 'package:nordplayer/pages/main_page.dart';

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

  // Initialize Config and Preference Service
  await ConfigService().init();
  await PreferenceService().init();

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
    return ListenableBuilder(
      listenable: ConfigService(),
      builder: (context, _) {
        final config = ConfigService().appConfig;

        return MaterialApp(
          title: 'Nordplayer',
          theme: AppTheme.getTheme(config.theme),
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(config.textScale), 
              ),
              child: child!,
            );
          },
          home: const MainPage(),
        );
      }
    );
  }
}