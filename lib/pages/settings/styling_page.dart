import 'package:flutter/material.dart';
import 'package:nordplayer/models/app_config.dart';
import 'package:nordplayer/models/app_theme.dart';
import 'package:nordplayer/services/config_service.dart';
import 'package:nordplayer/widgets/section_header.dart';
import 'package:nordplayer/widgets/slider_tile.dart';

class StylingSettingPage extends StatefulWidget {
  const StylingSettingPage({super.key});

  @override
  State<StylingSettingPage> createState() => _StylingSettingPageState();
}

class _StylingSettingPageState extends State<StylingSettingPage> {
  Map<String, String> keyLabel = AppTheme.labels;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: ListenableBuilder(
              listenable: ConfigService(),
              builder: (context, child) {
                AppConfig appConfig = ConfigService().appConfig;

                return ListView(
                  padding: const .all(16),
                  children: [
                    const SectionHeader(label: 'Appearance'),
                    Padding(
                      padding: .symmetric(vertical: 8),
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
                            ConfigService().update(theme: selectedTheme);
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),
                    const Divider(),
                    SectionHeader(label: 'Typography'),

                    SliderTile(
                      label: 'Font Scale',
                      value: appConfig.textScale,
                      min: 0.75,
                      max: 1.5,
                      labelBuilder: (val) => "${(val * 100).toInt()}%",
                      onChanged: (val) {
                        double roundedValue = (val * 100).round() / 100;
                        ConfigService().update(
                          textScale: roundedValue,
                          save: false,
                        );
                      },
                      onChangeEnd: (val) {
                        double roundedValue = (val * 100).round() / 100;
                        ConfigService().update(textScale: roundedValue);
                      },
                    ),

                    const SizedBox(height: 8),
                    const Divider(),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
