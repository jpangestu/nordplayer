import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nordplayer/models/app_theme.dart';
import 'package:nordplayer/services/config_service.dart';
import 'package:nordplayer/widgets/section_header.dart';
import 'package:nordplayer/widgets/slider_tile.dart';

class AppearancePage extends ConsumerWidget {
  const AppearancePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Map<String, String> keyLabel = AppTheme.labels;
    final theme = Theme.of(context);
    final appConfig = ref.watch(configServiceProvider).requireValue;

    return Scaffold(
      backgroundColor: appConfig.adaptiveBg
          ? theme.colorScheme.surfaceContainer.withValues(alpha: 0.5)
          : theme.colorScheme.surface,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SectionHeader(label: 'Theme', labelType: LabelType.h1),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              leading: const Icon(Icons.settings_display_outlined),
              title: const Text('App Theme'),
              trailing: DropdownMenu<String>(
                initialSelection: appConfig.theme,
                inputDecorationTheme: const InputDecorationTheme(
                  contentPadding: EdgeInsets.symmetric(horizontal: 8),
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                dropdownMenuEntries: keyLabel.entries.map((entry) {
                  return DropdownMenuEntry(
                    value: entry.key,
                    label: entry.value,
                  );
                }).toList(),
                onSelected: (selectedTheme) {
                  if (selectedTheme == null) return;
                  ref
                      .read(configServiceProvider.notifier)
                      .updateConfig(theme: selectedTheme);
                },
              ),
            ),
          ),

          SwitchListTile(
            title: const Text('Adaptive Background'),
            subtitle: const Text('Use blurred album art as the background'),
            value: appConfig.adaptiveBg,
            onChanged: (val) {
              ref
                  .read(configServiceProvider.notifier)
                  .updateConfig(adaptiveBg: val);
            },
          ),

          // Only show granular settings if the background is enabled
          if (appConfig.adaptiveBg) ...[
            SliderTile(
              label: 'Blur Intensity',
              value: appConfig.blur,
              min: 0.0,
              max: 100.0, // Adjust max based on how intense you want the blur
              labelBuilder: (val) => val.toInt().toString(),
              onChanged: (val) {
                ref
                    .read(configServiceProvider.notifier)
                    .updateConfig(blur: val, save: false);
              },
              onChangeEnd: (val) {
                ref
                    .read(configServiceProvider.notifier)
                    .updateConfig(blur: val);
              },
            ),

            SliderTile(
              label: 'Background Dimmer',
              value: appConfig.dimmer,
              min: 0.0,
              max: 1.0,
              labelBuilder: (val) => "${(val * 100).toInt()}%",
              onChanged: (val) {
                ref
                    .read(configServiceProvider.notifier)
                    .updateConfig(dimmer: val, save: false);
              },
              onChangeEnd: (val) {
                ref
                    .read(configServiceProvider.notifier)
                    .updateConfig(dimmer: val);
              },
            ),

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading: const Icon(Icons.aspect_ratio),
                title: const Text('Image Fit'),
                trailing: DropdownMenu<BoxFit>(
                  initialSelection: appConfig.boxFit,
                  inputDecorationTheme: const InputDecorationTheme(
                    contentPadding: EdgeInsets.symmetric(horizontal: 8),
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  dropdownMenuEntries: BoxFit.values.map((fit) {
                    return DropdownMenuEntry(value: fit, label: fit.name);
                  }).toList(),
                  onSelected: (selectedFit) {
                    if (selectedFit == null) return;
                    ref
                        .read(configServiceProvider.notifier)
                        .updateConfig(boxFit: selectedFit);
                  },
                ),
              ),
            ),
          ],

          const SizedBox(height: 8),
          const Divider(),
          const SectionHeader(label: 'Typography', labelType: LabelType.h1),

          SliderTile(
            label: 'Font Scale',
            value: appConfig.textScale,
            min: 0.75,
            max: 1.5,
            labelBuilder: (val) => "${(val * 100).toInt()}%",
            onChanged: (val) {
              double roundedValue = (val * 100).round() / 100;
              ref
                  .read(configServiceProvider.notifier)
                  .updateConfig(textScale: roundedValue, save: false);
            },
            onChangeEnd: (val) {
              double roundedValue = (val * 100).round() / 100;
              ref
                  .read(configServiceProvider.notifier)
                  .updateConfig(textScale: roundedValue);
            },
          ),

          const SizedBox(height: 8),
          const Divider(),
        ],
      ),
    );
  }
}
