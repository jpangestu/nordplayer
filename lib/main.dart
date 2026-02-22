import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nordplayer/models/app_config.dart';
import 'package:nordplayer/routes/router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';
import 'package:metadata_god/metadata_god.dart';
import 'package:media_kit/media_kit.dart';
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

  // SharedPreferencesWithCache must be loaded once at startup
  final prefs = await SharedPreferencesWithCache.create(
    cacheOptions: const SharedPreferencesWithCacheOptions(
      allowList: PrefConstants.allowList,
    ),
  );

  runApp(
    ProviderScope(
      overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
      child: const NordplayerApp(),
    ),
  );
}

class NordplayerApp extends ConsumerStatefulWidget {
  const NordplayerApp({super.key});

  @override
  ConsumerState<NordplayerApp> createState() => _NordplayerAppState();
}

class _NordplayerAppState extends ConsumerState<NordplayerApp>
    with WindowListener {
  @override
  Widget build(BuildContext context) {
    // Scan library after config loaded
    ref.listen<AsyncValue<AppConfig>>(configServiceProvider, (previous, next) {
      if (previous is AsyncLoading && next is AsyncData) {
        ref.read(libraryScannerProvider).scanLibrary();
      }
    });

    final configState = ref.watch(configServiceProvider);

    return configState.when(
      loading: () => const SizedBox.shrink(),

      error: (err, stack) => MaterialApp(
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        themeMode: ThemeMode.system,
        home: Scaffold(body: Center(child: Text('Disk Error: $err'))),
      ),

      data: (config) {
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
