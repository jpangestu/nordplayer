import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nordplayer/models/app_config.dart';
import 'package:nordplayer/routes/router.dart';
import 'package:nordplayer/services/library_watcher.dart';
import 'package:nordplayer/services/player_service.dart';
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

  // Set here because PlayerService and MediaKitAudioHandler need the same player instance
  final player = Player();
  await AudioService.init(
    builder: () => MediaKitAudioHandler(player),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.nordplayer.nordplayer.channel.audio',
      androidNotificationChannelName: 'Audio Playback',
    ),
  );

  runApp(
    ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
        playerServiceProvider.overrideWith((ref) {
          final service = PlayerService.withPlayer(ref, player);
          ref.onDispose(() => service.dispose());
          return service;
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

class _NordplayerAppState extends ConsumerState<NordplayerApp>
    with WindowListener {
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

  @override
  void onWindowRestore() => windowManager.setMinimumSize(const Size(800, 600));

  @override
  void onWindowUnmaximize() =>
      windowManager.setMinimumSize(const Size(800, 600));

  @override
  void onWindowResize() => windowManager.setMinimumSize(const Size(800, 600));

  @override
  void onWindowFocus() => windowManager.setMinimumSize(const Size(800, 600));

  @override
  Widget build(BuildContext context) {
    // Scan and watch for changes in library after config loaded
    ref.listen<AsyncValue<AppConfig>>(configServiceProvider, (previous, next) {
      if (previous is AsyncLoading && next is AsyncData) {
        ref.read(playerServiceProvider).init();
        ref.read(libraryWatcherProvider).startWatching();
        ref.read(libraryScannerProvider).scanLibrary();
        ref.read(playerServiceProvider).initializeQueueFromDatabase();
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
