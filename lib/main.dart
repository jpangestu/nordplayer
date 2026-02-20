import 'package:flutter/material.dart';
import 'package:nordplayer/routes/router.dart';
import 'package:nordplayer/services/player_service.dart';
import 'package:window_manager/window_manager.dart';
import 'package:metadata_god/metadata_god.dart';
import 'package:media_kit/media_kit.dart';
import 'package:nordplayer/database/app_database.dart';
import 'package:nordplayer/services/library_scanner.dart';
import 'package:nordplayer/models/app_theme.dart';
import 'package:nordplayer/services/config_service.dart';
import 'package:nordplayer/services/preference_service.dart';

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

  await MetadataGod.initialize();
  MediaKit.ensureInitialized();

  // Initialize Services
  await ConfigService().init();
  await PreferenceService().init();
  await PlayerService().init();

  LibraryScanner().scanLibrary(AppDatabase());

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

        return MaterialApp.router(
          routerConfig: router,
          title: 'Nordplayer',
          theme: AppTheme.getTheme(config.theme),
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(config.textScale)),
              child: child!,
            );
          },
        );
      },
    );
  }
}
