import 'package:flutter/material.dart';
import 'package:nordplayer/models/app_config.dart';
import 'package:nordplayer/models/app_theme.dart';
import 'package:nordplayer/services/config_service.dart';
import 'package:nordplayer/widgets/section_header.dart';

class StylingSettingPage extends StatefulWidget {
  const StylingSettingPage({super.key});

  @override
  State<StylingSettingPage> createState() => _StylingSettingPageState();
}

class _StylingSettingPageState extends State<StylingSettingPage> {
  Map<String, String> keyLabel = AppTheme.labels;

  @override
  Widget build(BuildContext context) {
    AppConfig appConfig = ConfigService().appConfig;

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const .all(16),
              children: [
                const SectionHeader(label: 'Appearance'),
                ListTile(
                  leading: const Icon(Icons.settings_display_outlined),
                  title: const Text('App Theme'),
                  trailing: DropdownMenu<String>(
                    initialSelection: appConfig.theme,
                    dropdownMenuEntries: keyLabel.entries.map((entry) {
                      return DropdownMenuEntry(
                        value: entry.key,
                        label: entry.value,
                      );
                    }).toList(),

                    onSelected: (selectedTheme) {
                      if (selectedTheme == null) return;
                      ConfigService().update(theme: selectedTheme);
                    },
                  ),
                ),

                const SizedBox(height: 16),
                const Divider(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
