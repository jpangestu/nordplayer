import 'dart:io';
import 'dart:ui' show AppExitResponse;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nordplayer/core/utils/directory_helper.dart';
import 'package:path/path.dart' as p;
import 'package:typed_config/typed_config.dart';
import 'package:window_manager/window_manager.dart';

import 'config/app_config.dart';
import 'routing/router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await windowManager.ensureInitialized();

  final appSupportDir = await getConfigDirectory();
  final configFile = File(p.join(appSupportDir.path, 'config.json'));
  final config = await Config.initialize(
    configFile: configFile,
    create: AppConfig.new,
    schemaVersion: currentSchemaVersion,
  );

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

  runApp(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWith((ref) {
          ref.onDispose(config.dispose);
          return config;
        }),
      ],
      child: const NordplayerApp(),
    ),
  );
}

class NordplayerApp extends ConsumerStatefulWidget {
  const NordplayerApp({super.key});

  @override
  ConsumerState<NordplayerApp> createState() => _NordplayerAppState();
}

class _NordplayerAppState extends ConsumerState<NordplayerApp> with WindowListener {
  late final AppLifecycleListener _lifecycleListener;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);

    _lifecycleListener = AppLifecycleListener(
      onExitRequested: () async {
        // Flushes any debounced dirty config changes before window closes
        await ref.read(appConfigProvider).flush();
        return AppExitResponse.exit;
      },
    );
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowRestore() => windowManager.setMinimumSize(const Size(800, 600));

  @override
  void onWindowUnmaximize() => windowManager.setMinimumSize(const Size(800, 600));

  @override
  void onWindowResize() => windowManager.setMinimumSize(const Size(800, 600));

  @override
  void onWindowFocus() => windowManager.setMinimumSize(const Size(800, 600));

  @override
  Widget build(BuildContext context) {
    final appConfig = ref.watch(appConfigProvider);
    final themeMode = ref.watch(appConfig.themeMode.provider);

    return MaterialApp.router(routerConfig: router, themeMode: themeMode, title: 'Nordplayer');
  }
}
