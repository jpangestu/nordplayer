import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nordplayer/models/app_theme.dart';
import 'package:nordplayer/services/config_service.dart';
import 'package:nordplayer/widgets/settings/section_header.dart';
import 'package:nordplayer/widgets/settings/section_divider.dart';
import 'package:nordplayer/widgets/settings/section_card.dart';
import 'package:nordplayer/widgets/settings/slider_tile.dart';

class AppearancePage extends ConsumerWidget {
  const AppearancePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Map<String, String> keyLabel = AppTheme.labels;
    final theme = Theme.of(context);
    final appConfig = ref.watch(configServiceProvider).requireValue;

    return Scaffold(
      backgroundColor: appConfig.adaptiveBg
          ? Colors.transparent
          : theme.colorScheme.surface,
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SectionHeader(
            label: 'Theme',
            labelType: LabelType.h1,
            padding: .only(bottom: 8),
          ),
          Column(
            children: [
              SectionWrapper(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading: const Icon(Icons.settings_display_outlined),
                    title: const Text('Color Theme'),
                    trailing: DropdownMenu<String>(
                      initialSelection: appConfig.theme,
                      inputDecorationTheme: InputDecorationTheme(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                        ),
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      menuStyle: MenuStyle(
                        backgroundColor: WidgetStatePropertyAll(
                          appConfig.adaptiveBg
                              ? theme.colorScheme.surfaceContainer.withValues(
                                  alpha: 0.8,
                                )
                              : theme.colorScheme.surfaceContainer,
                        ),
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
              ),

              SizedBox(height: 4),

              SectionWrapper(
                child: Column(
                  children: [
                    SwitchListTile(
                      secondary: const Icon(Icons.wallpaper_outlined),
                      title: const Text('Adaptive Background'),
                      subtitle: const Text(
                        "Use the currently played track's album art as the background",
                      ),
                      value: appConfig.adaptiveBg,
                      onChanged: (val) {
                        ref
                            .read(configServiceProvider.notifier)
                            .updateConfig(adaptiveBg: val);
                      },
                    ),

                    if (appConfig.adaptiveBg) ...[
                      SectionDivider(),

                      SliderTile(
                        label: 'Blur Intensity',
                        value: appConfig.adaptiveBgBlur,
                        min: 0.0,
                        max:
                            100.0, // Adjust max based on how intense you want the blur
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

                      SectionDivider(),

                      SliderTile(
                        label: 'Background Dimmer',
                        value: appConfig.adaptiveBgDimmer,
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

                      SectionDivider(),

                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          title: const Text('Album Art Fit'),
                          trailing: DropdownMenu<BoxFit>(
                            initialSelection: appConfig.adaptiveBgBoxFit,
                            inputDecorationTheme: InputDecorationTheme(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              isDense: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            menuStyle: MenuStyle(
                              backgroundColor: WidgetStatePropertyAll(
                                appConfig.adaptiveBg
                                    ? theme.colorScheme.surfaceContainer
                                          .withValues(alpha: 0.8)
                                    : theme.colorScheme.surfaceContainer,
                              ),
                            ),
                            dropdownMenuEntries: const [
                              DropdownMenuEntry(
                                value: BoxFit.cover,
                                label: 'Cover (Crop to fill)',
                              ),
                              DropdownMenuEntry(
                                value: BoxFit.fill,
                                label: 'Fill (Stretch)',
                              ),
                              DropdownMenuEntry(
                                value: BoxFit.contain,
                                label: 'Contain (Fit inside)',
                              ),
                              DropdownMenuEntry(
                                value: BoxFit.fitHeight,
                                label: 'Fit Height',
                              ),
                              DropdownMenuEntry(
                                value: BoxFit.fitWidth,
                                label: 'Fit Width',
                              ),
                            ],
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
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          const SectionHeader(label: 'Typography', labelType: LabelType.h1),

          SectionWrapper(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading: const Icon(Icons.font_download_outlined),
                title: const Text('Font Family'),
                trailing: DropdownMenu<String>(
                  initialSelection: appConfig.fontFamily,
                  inputDecorationTheme: InputDecorationTheme(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  menuStyle: MenuStyle(
                    backgroundColor: WidgetStatePropertyAll(
                      appConfig.adaptiveBg
                          ? theme.colorScheme.surfaceContainer.withValues(
                              alpha: 0.8,
                            )
                          : theme.colorScheme.surfaceContainer,
                    ),
                  ),
                  dropdownMenuEntries: AppTheme.availableFonts.entries.map((
                    entry,
                  ) {
                    final fontName = entry.key == 'System' ? null : entry.key;

                    return DropdownMenuEntry(
                      value: entry.key,
                      label: entry.value,
                      style: MenuItemButton.styleFrom(
                        textStyle: TextStyle(
                          fontFamily: fontName,
                          fontSize:
                              16, // Slightly larger size makes the preview clearer
                        ),
                      ),
                    );
                  }).toList(),
                  onSelected: (selectedFont) {
                    if (selectedFont == null) return;
                    ref
                        .read(configServiceProvider.notifier)
                        .updateConfig(fontFamily: selectedFont);
                  },
                ),
              ),
            ),
          ),

          SizedBox(height: 4),

          SectionWrapper(
            child: SliderTile(
              leading: Icon(Icons.format_size_outlined),
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
          ),
        ],
      ),
    );
  }
}
