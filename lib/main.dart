import 'dart:io';
import 'dart:ui' show AppExitResponse;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nordplayer/core/utils/directory_helper.dart';
import 'package:nordplayer/theme/app_theme.dart';
import 'package:path/path.dart' as p;
import 'package:typed_config/typed_config.dart';

import 'config/app_config.dart';
import 'routing/router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final appSupportDir = await getConfigDirectory();
  final configFile = File(p.join(appSupportDir.path, 'config.json'));
  final config = await TypedConfig.initialize(
    configFile: configFile,
    watchConfigFile: true,
    create: AppConfig.new,
    saveDefaultValue: true,
    schemaVersion: currentSchemaVersion,
  );

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

class _NordplayerAppState extends ConsumerState<NordplayerApp> {
  late final AppLifecycleListener _lifecycleListener;

  @override
  void initState() {
    super.initState();

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appConfig = ref.watch(appConfigProvider);
    final themeMode = ref.watch(appConfig.themeMode.provider);
    final appTheme = ref.watch(appThemeProvider);

    return MaterialApp.router(
      routerConfig: router,
      theme: appTheme.lightTheme,
      darkTheme: appTheme.darkTheme,
      themeMode: appTheme.resolveThemeMode(themeMode),
      title: 'Nordplayer',
    );
  }
}
