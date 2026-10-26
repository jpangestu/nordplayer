import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nordplayer/config/app_config.dart';

class LibraryView extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<LibraryView> createState() => LibraryViewState();
}

class LibraryViewState extends ConsumerState<LibraryView> {
  @override
  Widget build(BuildContext context) {
    final appConfig = ref.watch(appConfigProvider);
    final themeMode = ref.watch(appConfig.themeMode.provider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Current Theme: ${themeMode.name.toUpperCase()}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
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
          ],
        ),
      ),
    );
  }
}
