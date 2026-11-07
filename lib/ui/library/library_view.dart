import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nordplayer/config/app_config.dart';
import 'package:nordplayer/core/window/native_window.dart';

class LibraryView extends ConsumerStatefulWidget {
  const LibraryView({super.key});

  @override
  ConsumerState<LibraryView> createState() => LibraryViewState();
}

class LibraryViewState extends ConsumerState<LibraryView> {
  @override
  Widget build(BuildContext context) {
    final appConfig = ref.watch(appConfigProvider);
    final themeMode = ref.watch(appConfig.themeMode.provider);
    final windowBgType = ref.watch(appConfig.windowBg.type.provider);
    final platformStyle = ref.watch(appConfig.windowBg.platformStyle.windows.provider);
    final themeOverlay = ref.watch(appConfig.windowBg.albumArt.themeOverlay.provider);

    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Theme Mode: ${themeMode.name.toUpperCase()}',
                  style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment<ThemeMode>(
                      value: ThemeMode.system,
                      icon: Icon(Icons.brightness_auto_outlined),
                      label: Text('System'),
                    ),
                    ButtonSegment<ThemeMode>(
                      value: ThemeMode.light,
                      icon: Icon(Icons.light_mode_outlined),
                      label: Text('Light'),
                    ),
                    ButtonSegment<ThemeMode>(
                      value: ThemeMode.dark,
                      icon: Icon(Icons.dark_mode_outlined),
                      label: Text('Dark'),
                    ),
                  ],
                  selected: {themeMode},
                  onSelectionChanged: (newSelection) {
                    appConfig.themeMode.value = newSelection.first;
                  },
                ),
                const SizedBox(height: 32),
                Text(
                  'Window Background: ${windowBgType.name.toUpperCase()}',
                  style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                SegmentedButton<WindowBgType>(
                  segments: const [
                    ButtonSegment<WindowBgType>(
                      value: WindowBgType.solid,
                      icon: Icon(Icons.stop_outlined),
                      label: Text('Solid'),
                    ),
                    ButtonSegment<WindowBgType>(
                      value: WindowBgType.platformStyle,
                      icon: Icon(Icons.blur_on_outlined),
                      label: Text('Platform Style'),
                    ),
                    ButtonSegment<WindowBgType>(
                      value: WindowBgType.albumArt,
                      icon: Icon(Icons.album_outlined),
                      label: Text('Album Art'),
                    ),
                  ],
                  selected: {windowBgType},
                  onSelectionChanged: (newSelection) {
                    appConfig.windowBg.type.value = newSelection.first;
                  },
                ),
                if (windowBgType == WindowBgType.platformStyle) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Platform Style: ${platformStyle.name.toUpperCase()}',
                    style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<WindowsWindowStyle>(
                    segments: const [
                      ButtonSegment<WindowsWindowStyle>(
                        value: WindowsWindowStyle.acrylic,
                        icon: Icon(Icons.blur_on),
                        label: Text('Acrylic'),
                      ),
                      ButtonSegment<WindowsWindowStyle>(
                        value: WindowsWindowStyle.mica,
                        icon: Icon(Icons.auto_awesome_outlined),
                        label: Text('Mica'),
                      ),
                      ButtonSegment<WindowsWindowStyle>(
                        value: WindowsWindowStyle.micaAlt,
                        icon: Icon(Icons.tab_outlined),
                        label: Text('Mica Alt'),
                      ),
                    ],
                    selected: {platformStyle},
                    onSelectionChanged: (newSelection) {
                      appConfig.windowBg.platformStyle.windows.value = newSelection.first;
                    },
                  ),
                ],
                const SizedBox(height: 32),
                Text(
                  'Theme Overlay Opacity: ${(themeOverlay * 100).round()}%',
                  style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Slider(
                  value: themeOverlay.clamp(0.0, 1.0),
                  min: 0.0,
                  max: 1.0,
                  divisions: 100,
                  label: '${(themeOverlay * 100).round()}%',
                  onChanged: windowBgType != WindowBgType.solid
                      ? (newVal) {
                          appConfig.windowBg.albumArt.themeOverlay.value = newVal;
                        }
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
