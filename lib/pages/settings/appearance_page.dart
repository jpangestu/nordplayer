import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nordplayer/models/app_theme.dart';
import 'package:nordplayer/services/config_service.dart';
import 'package:nordplayer/widgets/settings/choice_tile.dart';
import 'package:nordplayer/widgets/settings/section_card.dart';
import 'package:nordplayer/widgets/settings/section_divider.dart';
import 'package:nordplayer/widgets/settings/section_header.dart';
import 'package:nordplayer/widgets/settings/slider_tile.dart';

class AppearancePage extends ConsumerWidget {
  const AppearancePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final appConfig = ref.watch(configServiceProvider).requireValue;

    return Scaffold(
      backgroundColor: appConfig.adaptiveBg ? Colors.transparent : theme.colorScheme.surface,
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SectionHeader(label: 'Theme', labelType: .h1, padding: EdgeInsets.only(bottom: 8)),
          Column(
            children: [
              SectionCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: .start,
                    children: [
                      Row(
                        children: [
                          ChoiceTile(
                            label: 'Static',
                            isSelected: appConfig.theme != 'adaptive',
                            onTap: () => ref.read(configServiceProvider.notifier).updateConfig(theme: 'nord'),
                          ),
                          const SizedBox(width: 12),
                          ChoiceTile(
                            label: 'Adaptive',
                            isSelected: appConfig.theme == 'adaptive',
                            onTap: () => ref.read(configServiceProvider.notifier).updateConfig(theme: 'adaptive'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      if (appConfig.theme == 'adaptive') ...[
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final useVerticalLayout = constraints.maxWidth < 380;
                            final tiles = [
                              ChoiceTile(
                                label: 'Light',
                                verticalPadding: 8,
                                isSelected: appConfig.themeBrightness == Brightness.light,
                                onTap: () => ref
                                    .read(configServiceProvider.notifier)
                                    .updateConfig(themeBrightness: Brightness.light),
                              ),
                              const SizedBox(width: 8),
                              ChoiceTile(
                                label: 'Dark',
                                verticalPadding: 8,
                                isSelected: appConfig.themeBrightness == Brightness.dark,
                                onTap: () => ref
                                    .read(configServiceProvider.notifier)
                                    .updateConfig(themeBrightness: Brightness.dark),
                              ),
                            ];

                            if (useVerticalLayout) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Base Brightness', style: theme.textTheme.bodyLarge),
                                  const SizedBox(height: 12),
                                  Row(children: tiles),
                                ],
                              );
                            }

                            return Row(
                              children: [
                                Text('Base Brightness', style: theme.textTheme.bodyLarge),
                                const SizedBox(width: 48),
                                Expanded(child: Row(children: tiles)),
                              ],
                            );
                          },
                        ),
                      ] else ...[
                        Row(
                          mainAxisAlignment: .spaceBetween,
                          children: [
                            Text('Color Theme', style: theme.textTheme.bodyLarge),
                            const SizedBox(width: 48),
                            DropdownMenu<String>(
                              initialSelection: appConfig.theme,
                              inputDecorationTheme: InputDecorationTheme(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                                isDense: true,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              menuStyle: MenuStyle(
                                backgroundColor: WidgetStatePropertyAll(
                                  appConfig.adaptiveBg
                                      ? theme.colorScheme.surfaceContainer.withValues(alpha: 0.8)
                                      : theme.colorScheme.surfaceContainer,
                                ),
                              ),
                              dropdownMenuEntries: AppTheme.labels.entries.where((e) => e.key != 'adaptive').map((
                                entry,
                              ) {
                                return DropdownMenuEntry(value: entry.key, label: entry.value);
                              }).toList(),
                              onSelected: (selectedTheme) {
                                if (selectedTheme == null) return;
                                ref.read(configServiceProvider.notifier).updateConfig(theme: selectedTheme);
                              },
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 4),

              SectionCard(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    title: Text('Icon Set', style: theme.textTheme.bodyLarge),
                    trailing: DropdownMenu<String>(
                      initialSelection: appConfig.iconSet,
                      inputDecorationTheme: InputDecorationTheme(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                        isDense: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      menuStyle: MenuStyle(
                        backgroundColor: WidgetStatePropertyAll(
                          appConfig.adaptiveBg
                              ? theme.colorScheme.surfaceContainer.withValues(alpha: 0.8)
                              : theme.colorScheme.surfaceContainer,
                        ),
                      ),
                      dropdownMenuEntries: const [
                        DropdownMenuEntry(value: 'lucide', label: 'Lucide'),
                        DropdownMenuEntry(value: 'material', label: 'Material'),
                      ],
                      onSelected: (selectedIconSet) {
                        if (selectedIconSet == null) return;
                        ref.read(configServiceProvider.notifier).updateConfig(iconSet: selectedIconSet);
                      },
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 4),

              SectionCard(
                child: Column(
                  children: [
                    SwitchListTile(
                      title: Text('Adaptive Background', style: theme.textTheme.bodyLarge),
                      subtitle: const Text("Use the currently played track's album art as the background"),
                      value: appConfig.adaptiveBg,
                      onChanged: (val) {
                        ref.read(configServiceProvider.notifier).updateConfig(adaptiveBg: val);
                      },
                    ),

                    if (appConfig.adaptiveBg) ...[
                      const SectionDivider(),

                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          title: Text('Album Art Fit', style: theme.textTheme.bodyLarge),
                          trailing: DropdownMenu<BoxFit>(
                            initialSelection: appConfig.adaptiveBgAlbumFit,
                            inputDecorationTheme: InputDecorationTheme(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                              isDense: true,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                            menuStyle: MenuStyle(
                              backgroundColor: WidgetStatePropertyAll(
                                appConfig.adaptiveBg
                                    ? theme.colorScheme.surfaceContainer.withValues(alpha: 0.8)
                                    : theme.colorScheme.surfaceContainer,
                              ),
                            ),
                            dropdownMenuEntries: const [
                              DropdownMenuEntry(value: .contain, label: 'Contain (Fit inside)'),
                              DropdownMenuEntry(value: .cover, label: 'Cover (Crop to fill)'),
                              DropdownMenuEntry(value: .fill, label: 'Fill (Stretch)'),
                            ],
                            onSelected: (selectedFit) {
                              if (selectedFit == null) return;
                              ref.read(configServiceProvider.notifier).updateConfig(albumFit: selectedFit);
                            },
                          ),
                        ),
                      ),

                      const SectionDivider(),

                      SliderTile(
                        label: 'Album Art Blur',
                        value: appConfig.adaptiveBgAlbumBlur,
                        min: 0.0,
                        max: 100.0,
                        labelBuilder: (val) => val.toInt().toString(),
                        onChanged: (val) {
                          ref.read(configServiceProvider.notifier).updateConfig(albumBlur: val, save: false);
                        },
                        onChangeEnd: (val) {
                          ref.read(configServiceProvider.notifier).updateConfig(albumBlur: val);
                        },
                      ),

                      SliderTile(
                        label: 'Panel Blur',
                        value: appConfig.adaptiveBgPanelBlur,
                        min: 0.0,
                        max: 100.0,
                        labelBuilder: (val) => val.toInt().toString(),
                        onChanged: (val) {
                          ref.read(configServiceProvider.notifier).updateConfig(panelBlur: val, save: false);
                        },
                        onChangeEnd: (val) {
                          ref.read(configServiceProvider.notifier).updateConfig(panelBlur: val);
                        },
                      ),

                      const SectionDivider(),

                      SliderTile(
                        label: 'Theme Overlay',
                        value: appConfig.adaptiveBgThemeOverlay,
                        min: 0.0,
                        max: 1.0,
                        labelBuilder: (val) => "${(val * 100).toInt()}%",
                        onChanged: (val) {
                          ref.read(configServiceProvider.notifier).updateConfig(tinter: val, save: false);
                        },
                        onChangeEnd: (val) {
                          ref.read(configServiceProvider.notifier).updateConfig(tinter: val);
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          const SectionHeader(label: 'Typography', labelType: .h1),

          SectionCard(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                title: Text('Font Family', style: theme.textTheme.bodyLarge),
                trailing: DropdownMenu<String>(
                  initialSelection: appConfig.fontFamily,
                  inputDecorationTheme: InputDecorationTheme(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  menuStyle: MenuStyle(
                    backgroundColor: WidgetStatePropertyAll(
                      appConfig.adaptiveBg
                          ? theme.colorScheme.surfaceContainer.withValues(alpha: 0.8)
                          : theme.colorScheme.surfaceContainer,
                    ),
                  ),
                  dropdownMenuEntries: AppTheme.availableFonts.entries.map((entry) {
                    return DropdownMenuEntry(
                      value: entry.key,
                      label: entry.value,
                      style: MenuItemButton.styleFrom(
                        textStyle: TextStyle(
                          fontFamily: entry.key,
                          fontSize: 16, // Slightly larger size makes the preview clearer
                        ),
                      ),
                    );
                  }).toList(),
                  onSelected: (selectedFont) {
                    if (selectedFont == null) return;
                    ref.read(configServiceProvider.notifier).updateConfig(fontFamily: selectedFont);
                  },
                ),
              ),
            ),
          ),

          const SizedBox(height: 4),

          SectionCard(
            child: SliderTile(
              label: 'Font Scale',
              value: appConfig.textScale,
              min: 0.75,
              max: 1.5,
              labelBuilder: (val) => "${(val * 100).toInt()}%",
              onChanged: (val) {
                double roundedValue = (val * 100).round() / 100;
                ref.read(configServiceProvider.notifier).updateConfig(textScale: roundedValue, save: false);
              },
              onChangeEnd: (val) {
                double roundedValue = (val * 100).round() / 100;
                ref.read(configServiceProvider.notifier).updateConfig(textScale: roundedValue);
              },
            ),
          ),
        ],
      ),
    );
  }
}
