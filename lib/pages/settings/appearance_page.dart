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
    final appConfig = ref.watch(configServiceProvider).requireValue;

    return Scaffold(
      body: ListView(
        padding: const .all(16),
        children: [
          const SectionHeader(label: 'Theme', labelType: .h1),
          Padding(
            padding: const .symmetric(vertical: 8),
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

          const SizedBox(height: 8),
          const Divider(),
          const SectionHeader(label: 'Typography', labelType: .h1),

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
