import 'package:flutter/material.dart';
import 'package:nordplayer/models/app_theme.dart';
// import 'package:nordplayer/theme/nord_theme.dart';
import 'package:nordplayer/widgets/section_header.dart';

class StylingSettingPage extends StatefulWidget {
  const StylingSettingPage({super.key});

  @override
  State<StylingSettingPage> createState() => _StylingSettingPageState();
}

class _StylingSettingPageState extends State<StylingSettingPage> {
  var themeDataMap = AppTheme().getThemeDataMap();
  @override
  Widget build(BuildContext context) {
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
                  trailing: DropdownMenu<ThemeData>(
                    initialSelection: themeDataMap['nord'],
                    dropdownMenuEntries: [
                      DropdownMenuEntry(
                        value: themeDataMap['nord']!,
                        label: 'Nord',
                      ),
                      DropdownMenuEntry(
                        value: themeDataMap['dark']!,
                        label: 'Default Dark',
                      ),
                      DropdownMenuEntry(
                        value: themeDataMap['light']!,
                        label: 'Default Light',
                      ),
                    ],
                    onSelected: (val) {},
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
