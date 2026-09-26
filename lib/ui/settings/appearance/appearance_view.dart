import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nordplayer/ui/settings/appearance/appearance_viewmodel.dart';
import 'package:nordplayer/ui/settings/widgets/choice_tile.dart';
import 'package:nordplayer/ui/settings/widgets/slider_tile.dart';
import 'package:nordplayer/ui/shared/themes/app_theme.dart';
import 'package:nordplayer/ui/shared/ui/sections/section_container.dart';
import 'package:nordplayer/ui/shared/ui/sections/section_divider.dart';
import 'package:nordplayer/ui/shared/ui/sections/section_header.dart';

/// Pure presentation View for the Appearance settings screen, observing [AppearanceUiState].
class AppearanceView extends ConsumerWidget {
  const AppearanceView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final uiState = ref.watch(appearanceViewModelProvider);
    final viewModel = ref.read(appearanceViewModelProvider.notifier);

    return Scaffold(
      backgroundColor: uiState.adaptiveBg ? Colors.transparent : theme.colorScheme.surface,
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SectionHeader(label: 'Theme', labelType: .h1, padding: EdgeInsets.only(bottom: 8)),
          Column(
            children: [
              SectionContainer(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: .start,
                    children: [
                      Row(
                        children: [
                          ChoiceTile(
                            label: 'Static',
                            isSelected: uiState.theme != 'adaptive',
                            onTap: () => viewModel.setTheme('nord'),
                          ),
                          const SizedBox(width: 12),
                          ChoiceTile(
                            label: 'Adaptive',
                            isSelected: uiState.theme == 'adaptive',
                            onTap: () => viewModel.setTheme('adaptive'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      if (uiState.theme == 'adaptive') ...[
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final useVerticalLayout = constraints.maxWidth < 380;
                            final tiles = [
                              ChoiceTile(
                                label: 'Light',
                                verticalPadding: 8,
                                isSelected: uiState.themeBrightness == Brightness.light,
                                onTap: () => viewModel.setThemeBrightness(Brightness.light),
                              ),
                              const SizedBox(width: 8),
                              ChoiceTile(
                                label: 'Dark',
                                verticalPadding: 8,
                                isSelected: uiState.themeBrightness == Brightness.dark,
                                onTap: () => viewModel.setThemeBrightness(Brightness.dark),
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
                              initialSelection: uiState.theme,
                              inputDecorationTheme: InputDecorationTheme(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                                isDense: true,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              menuStyle: MenuStyle(
                                backgroundColor: WidgetStatePropertyAll(
                                  uiState.adaptiveBg
                                      ? theme.colorScheme.surfaceContainer.withValues(alpha: 0.8)
                                      : theme.colorScheme.surfaceContainer,
                                ),
                              ),
                              dropdownMenuEntries: AppTheme.labels.entries
                                  .where((e) => e.key != 'adaptive')
                                  .map((entry) => DropdownMenuEntry(value: entry.key, label: entry.value))
                                  .toList(),
                              onSelected: (selectedTheme) {
                                if (selectedTheme == null) return;
                                viewModel.setTheme(selectedTheme);
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

              SectionContainer(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    title: Text('Icon Set', style: theme.textTheme.bodyLarge),
                    trailing: DropdownMenu<String>(
                      initialSelection: uiState.iconSet,
                      inputDecorationTheme: InputDecorationTheme(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                        isDense: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      menuStyle: MenuStyle(
                        backgroundColor: WidgetStatePropertyAll(
                          uiState.adaptiveBg
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
                        viewModel.setIconSet(selectedIconSet);
                      },
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 4),

              SectionContainer(
                child: Column(
                  children: [
                    SwitchListTile(
                      title: Text('Adaptive Background', style: theme.textTheme.bodyLarge),
                      subtitle: const Text("Use the currently played track's album art as the background"),
                      value: uiState.adaptiveBg,
                      onChanged: viewModel.setAdaptiveBg,
                    ),

                    if (uiState.adaptiveBg) ...[
                      const SectionDivider(),

                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          title: Text('Album Art Fit', style: theme.textTheme.bodyLarge),
                          trailing: DropdownMenu<BoxFit>(
                            initialSelection: uiState.adaptiveBgAlbumFit,
                            inputDecorationTheme: InputDecorationTheme(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                              isDense: true,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                            menuStyle: MenuStyle(
                              backgroundColor: WidgetStatePropertyAll(
                                uiState.adaptiveBg
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
                              viewModel.setAlbumFit(selectedFit);
                            },
                          ),
                        ),
                      ),

                      const SectionDivider(),

                      SliderTile(
                        label: 'Album Art Blur',
                        value: uiState.adaptiveBgAlbumBlur,
                        min: 0.0,
                        max: 100.0,
                        labelBuilder: (val) => val.toInt().toString(),
                        onChanged: viewModel.setAlbumBlur,
                        onChangeEnd: viewModel.setAlbumBlur,
                      ),

                      const SectionDivider(),

                      SliderTile(
                        label: 'Panel Blur',
                        value: uiState.adaptiveBgPanelBlur,
                        min: 0.0,
                        max: 100.0,
                        labelBuilder: (val) => val.toInt().toString(),
                        onChanged: viewModel.setPanelBlur,
                        onChangeEnd: viewModel.setPanelBlur,
                      ),

                      const SectionDivider(),

                      SliderTile(
                        label: 'Theme Overlay',
                        value: uiState.adaptiveBgThemeOverlay,
                        min: 0.0,
                        max: 1.0,
                        labelBuilder: (val) => "${(val * 100).toInt()}%",
                        onChanged: viewModel.setThemeOverlay,
                        onChangeEnd: viewModel.setThemeOverlay,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          const SectionHeader(label: 'Typography', labelType: .h1),

          SectionContainer(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                title: Text('Font Family', style: theme.textTheme.bodyLarge),
                trailing: DropdownMenu<String>(
                  initialSelection: uiState.fontFamily,
                  inputDecorationTheme: InputDecorationTheme(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  menuStyle: MenuStyle(
                    backgroundColor: WidgetStatePropertyAll(
                      uiState.adaptiveBg
                          ? theme.colorScheme.surfaceContainer.withValues(alpha: 0.8)
                          : theme.colorScheme.surfaceContainer,
                    ),
                  ),
                  dropdownMenuEntries: AppTheme.availableFonts.entries.map((entry) {
                    return DropdownMenuEntry(
                      value: entry.key,
                      label: entry.value,
                      style: MenuItemButton.styleFrom(textStyle: TextStyle(fontFamily: entry.key, fontSize: 16)),
                    );
                  }).toList(),
                  onSelected: (selectedFont) {
                    if (selectedFont == null) return;
                    viewModel.setFontFamily(selectedFont);
                  },
                ),
              ),
            ),
          ),

          const SizedBox(height: 4),

          SectionContainer(
            child: SliderTile(
              label: 'Font Scale',
              value: uiState.textScale,
              min: 0.75,
              max: 1.5,
              labelBuilder: (val) => "${(val * 100).toInt()}%",
              onChanged: viewModel.setTextScale,
              onChangeEnd: viewModel.setTextScale,
            ),
          ),
        ],
      ),
    );
  }
}
