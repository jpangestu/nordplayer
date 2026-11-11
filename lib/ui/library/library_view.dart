import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nordplayer/config/app_config.dart';
import 'package:nordplayer/core/window/native_window.dart';
import 'package:nordplayer/routing/router.dart';

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
    final themeOverlayOpacity = ref.watch(appConfig.windowBackdrop.themeOverlayOpacity.provider);
    final windowBackdropType = ref.watch(appConfig.windowBackdrop.type.provider);
    final platformStyle = ref.watch(appConfig.windowBackdrop.platformStyle.windows.provider);
    final albumArtBlur = ref.watch(appConfig.windowBackdrop.albumArt.blurRadius.provider);
    final albumArtFit = ref.watch(appConfig.windowBackdrop.albumArt.fit.provider);

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
                  'Window Background: ${windowBackdropType.name.toUpperCase()}',
                  style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                SegmentedButton<WindowBackdropType>(
                  segments: const [
                    ButtonSegment<WindowBackdropType>(
                      value: WindowBackdropType.solid,
                      icon: Icon(Icons.stop_outlined),
                      label: Text('Solid'),
                    ),
                    ButtonSegment<WindowBackdropType>(
                      value: WindowBackdropType.platformStyle,
                      icon: Icon(Icons.blur_on_outlined),
                      label: Text('Platform Style'),
                    ),
                    ButtonSegment<WindowBackdropType>(
                      value: WindowBackdropType.albumArt,
                      icon: Icon(Icons.album_outlined),
                      label: Text('Album Art'),
                    ),
                  ],
                  selected: {windowBackdropType},
                  onSelectionChanged: (newSelection) {
                    appConfig.windowBackdrop.type.value = newSelection.first;
                  },
                ),
                if (windowBackdropType == WindowBackdropType.platformStyle) ...[
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
                      appConfig.windowBackdrop.platformStyle.windows.value = newSelection.first;
                    },
                  ),
                ],
                if (windowBackdropType == WindowBackdropType.albumArt) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Album Art Blur: ${albumArtBlur.round()}px',
                    style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Slider(
                    value: albumArtBlur.clamp(0.0, 100.0),
                    min: 0.0,
                    max: 100.0,
                    divisions: 100,
                    label: '${albumArtBlur.round()}px',
                    onChanged: (newVal) {
                      appConfig.windowBackdrop.albumArt.blurRadius.value = newVal;
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Album Art Fit: ${albumArtFit.name.toUpperCase()}',
                    style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<BoxFit>(
                    segments: const [
                      ButtonSegment<BoxFit>(
                        value: BoxFit.cover,
                        icon: Icon(Icons.crop_free_outlined),
                        label: Text('Cover'),
                      ),
                      ButtonSegment<BoxFit>(
                        value: BoxFit.contain,
                        icon: Icon(Icons.fit_screen_outlined),
                        label: Text('Contain'),
                      ),
                      ButtonSegment<BoxFit>(
                        value: BoxFit.fill,
                        icon: Icon(Icons.aspect_ratio_outlined),
                        label: Text('Fill'),
                      ),
                      ButtonSegment<BoxFit>(
                        value: BoxFit.fitWidth,
                        icon: Icon(Icons.swap_horiz_outlined),
                        label: Text('Fit Width'),
                      ),
                    ],
                    selected: {albumArtFit},
                    onSelectionChanged: (newSelection) {
                      appConfig.windowBackdrop.albumArt.fit.value = newSelection.first;
                    },
                  ),
                ],
                const SizedBox(height: 32),
                Text(
                  'Theme Overlay Opacity: ${(themeOverlayOpacity * 100).round()}%',
                  style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Slider(
                  value: themeOverlayOpacity.clamp(0.0, 1.0),
                  min: 0.0,
                  max: 1.0,
                  divisions: 100,
                  label: '${(themeOverlayOpacity * 100).round()}%',
                  onChanged: windowBackdropType != WindowBackdropType.solid
                      ? (newVal) {
                          appConfig.windowBackdrop.themeOverlayOpacity.value = newVal;
                        }
                      : null,
                ),
                const SizedBox(height: 36),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonalIcon(
                    icon: const Icon(Icons.grid_view_rounded),
                    label: const Text('Open AdaptiveSurface Test Suite'),
                    onPressed: () => context.push(Routes.surfaceBenchmark),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
