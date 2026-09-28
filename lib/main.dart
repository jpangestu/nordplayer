import 'package:audio_service/audio_service.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_kit/media_kit.dart';
import 'package:nordplayer/data/repositories/ui_preferences_repository.dart';
import 'package:nordplayer/data/services/audio/audio_handler.dart';
import 'package:nordplayer/data/services/audio/audio_player_engine.dart' show audioPlayerProvider;
import 'package:nordplayer/data/services/audio/playback_controller.dart';
import 'package:nordplayer/data/services/indexer/library_indexer.dart';
import 'package:nordplayer/data/services/indexer/library_watcher.dart';
import 'package:nordplayer/data/services/system/config_service.dart';
import 'package:nordplayer/routing/router.dart';
import 'package:nordplayer/ui/shared/shortcuts.dart';
import 'package:nordplayer/ui/shared/themes/active_theme_provider.dart';
import 'package:nordplayer/ui/shared/ui/adaptive_scaffold.dart';
import 'package:nordplayer/utils/directory_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
    titleBarStyle: .hidden,
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  MediaKit.ensureInitialized();

  // Pre-load SharedPreferences and Config directory concurrently at startup
  final (prefs, configDir) = await (
    SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(allowList: UiPrefConstants.allowList),
    ),
    getConfigDirectory(),
  ).wait;

  final appConfig = await ConfigService.loadInitialConfig(configDir);

  // Set here because AudioPlayerEngine and AppAudioHandler need the same player instance
  final player = Player();
  final audioHandler = await AudioService.init(
    builder: () => AppAudioHandler(player),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.nordplayer.nordplayer.channel.audio',
      androidNotificationChannelName: 'Audio Playback',
    ),
  );

  runApp(
    ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
        configDirectoryProvider.overrideWithValue(configDir),
        initialAppConfigProvider.overrideWithValue(appConfig),
        audioPlayerProvider.overrideWithValue(player),
        audioHandlerProvider.overrideWithValue(audioHandler),
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
  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      ref.read(libraryWatcherProvider);

      await ref.read(playbackControllerProvider).restoreQueue();

      // Run scan library only when the main thread is idle (all UI render finished)
      SchedulerBinding.instance.scheduleTask(() {
        ref.read(libraryIndexerProvider).scanLibrary();
      }, Priority.idle);
    });
  }

  @override
  void dispose() {
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
    // Depends on activeThemeProvider, which only rebuilds when theme or fontFamily changes
    final themeData = ref.watch(activeThemeProvider);

    return MaterialApp.router(
      routerConfig: router,
      title: 'Nordplayer',
      theme: themeData,
      localizationsDelegates: [GlobalMaterialLocalizations.delegate],
      supportedLocales: const [Locale('en', 'US')],
      localeResolutionCallback: (locale, supportedLocales) {
        if (locale != null) {
          for (final supported in supportedLocales) {
            if (supported.languageCode == locale.languageCode) {
              return supported;
            }
          }
        }
        return supportedLocales.first;
      },
      builder: (context, child) {
        return Shortcuts(
          shortcuts: <ShortcutActivator, Intent>{
            const SingleActivator(LogicalKeyboardKey.keyK, control: true): const FocusSearchIntent(),
            const SingleActivator(LogicalKeyboardKey.space): const PlayOrPauseIntent(),
            const SingleActivator(LogicalKeyboardKey.arrowRight, control: true): const SkipToNextIntent(),
            const SingleActivator(LogicalKeyboardKey.arrowLeft, control: true): const SkipToPreviousIntent(),
            const CharacterActivator('s', control: true): const ToggleShuffleIntent(),
            const CharacterActivator('l', control: true): const CycleLoopIntent(),
            const SingleActivator(LogicalKeyboardKey.arrowUp, control: true): const VolumeUpIntent(),
            const SingleActivator(LogicalKeyboardKey.arrowDown, control: true): const VolumeDownIntent(),
            const CharacterActivator('m'): const MuteIntent(),
          },
          child: Actions(
            actions: <Type, Action<Intent>>{
              FocusSearchIntent: FocusSearchAction(ref),
              PlayOrPauseIntent: PlayOrPauseAction(ref),
              SkipToNextIntent: SkipToNextAction(ref),
              SkipToPreviousIntent: SkipToPreviousAction(ref),
              ToggleShuffleIntent: ToggleShuffleAction(ref),
              CycleLoopIntent: CycleLoopAction(ref),
              VolumeUpIntent: VolumeUpAction(ref),
              VolumeDownIntent: VolumeDownAction(ref),
              MuteIntent: MuteAction(ref),
            },
            child: Focus(
              child: Consumer(
                builder: (context, ref, _) {
                  // Localize text scale rebuilds to this sub-tree instead of rebuilding the entire MaterialApp.
                  final textScale = ref.watch(configServiceProvider.select((v) => v.textScale));
                  return MediaQuery(
                    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
                    child: AdaptiveScaffold(body: child!),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
