import 'package:flutter/material.dart';
import 'package:suara/models/texture_profile';
import 'package:suara/services/theme_service.dart';

class Styling extends StatefulWidget {
  const Styling({super.key});

  @override
  State<Styling> createState() => _StylingState();
}

class _StylingState extends State<Styling> {
  double? _tempBlur;
  double? _tempTextureOpacity;
  double? _tempDim;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: ThemeService().themeStream,
      initialData: ThemeService().currentTheme,
      builder: (context, snapshot) {
        return StreamBuilder(
          stream: ThemeService().adaptiveBackgroundStream,
          initialData: ThemeService().adaptiveBackground,
          builder: (context, snapshot) {
            return StreamBuilder(
              stream: ThemeService().texturedLayeredStream,
              builder: (context, snapshot) {
                return StreamBuilder(
                  stream: ThemeService().dimmerStream,
                  builder: (context, snapshot) {
                    final currentTheme = ThemeService().currentTheme;

                    // Adaptive Background
                    final adaptiveBackground =
                        ThemeService().adaptiveBackground;
                    final currentBlur = _tempBlur ?? adaptiveBackground.blur;

                    // Texture
                    final texturedLayer = ThemeService().texturedLayer;
                    final currentTextrueOpacity =
                        _tempTextureOpacity ?? texturedLayer.opacity;
                    List<TextureProfile> allTextures =
                        ThemeService().allTextures;

                    final currentDim = _tempBlur ?? snapshot.data ?? ThemeService().dimmerLevel;

                    return ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _buildSectionHeader('Appearance'),
                        ListTile(
                          leading: const Icon(Icons.settings_display_outlined),
                          title: const Text('App Theme'),
                          trailing: DropdownMenu<ThemeMode>(
                            initialSelection: currentTheme,
                            dropdownMenuEntries: const [
                              DropdownMenuEntry(
                                value: ThemeMode.system,
                                label: 'System Default',
                              ),
                              DropdownMenuEntry(
                                value: ThemeMode.dark,
                                label: 'Dark',
                              ),
                              DropdownMenuEntry(
                                value: ThemeMode.light,
                                label: 'Light',
                              ),
                            ],
                            onSelected: (value) {
                              if (value != null) {
                                ThemeService().setTheme(value);
                              }
                            },
                          ),
                        ),

                        const SizedBox(height: 16),
                        const Divider(),
                        _buildSectionHeader('Immersive Background'),

                        SwitchListTile(
                          value: adaptiveBackground.isEnabled,
                          title: const Text('Adaptive Background'),
                          subtitle: const Text('Use album art as background'),
                          onChanged: (value) {
                            setState(() {
                              ThemeService().setAdaptiveBackgroundMode(value);
                            });
                          },
                        ),

                        if (adaptiveBackground.isEnabled) ...[
                          const SizedBox(height: 8),

                          ListTile(
                            title: const Text('Album Art Placement (Fit)'),
                            trailing: DropdownMenu<BoxFit>(
                              initialSelection: adaptiveBackground.fit,
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
                              onSelected: (BoxFit? value) {
                                if (value != null) {
                                  ThemeService().setAdaptiveBackgroundFit(
                                    value,
                                  );
                                }
                              },
                            ),
                          ),

                          _buildSliderRow(
                            label: 'Blur',
                            value: currentBlur,
                            min: 0,
                            max: 100,
                            valueText: '${currentBlur.round()}px',
                            onChanged: (val) => setState(() => _tempBlur = val),
                            onChangeEnd: (val) =>
                                ThemeService().setAdaptiveBackgroundBlur(val),
                          ),

                          const SizedBox(height: 16),
                        ],

                        const Divider(),

                        SwitchListTile(
                          value: texturedLayer.isEnabled,
                          title: const Text('Textured Layer'),
                          subtitle: const Text(
                            'Add texture layer on top of the album art',
                          ),
                          onChanged: (value) {
                            setState(() {
                              ThemeService().setTexturedLayerMode(value);
                            });
                          },
                        ),

                        if (texturedLayer.isEnabled) ...[
                          const SizedBox(height: 8),

                          ListTile(
                            title: const Text('Select Texture'),
                            trailing: DropdownMenu<TextureProfile>(
                              // Force redraw on change
                              key: ValueKey(ThemeService().currentTexture),
                              initialSelection: ThemeService().currentTexture,
                              dropdownMenuEntries: allTextures
                                  .map<DropdownMenuEntry<TextureProfile>>((
                                    TextureProfile value,
                                  ) {
                                    return DropdownMenuEntry(
                                      value: value,
                                      label: value.name,
                                    );
                                  })
                                  .toList(),
                              onSelected: (TextureProfile? value) {
                                if (value != null) {
                                  ThemeService().setTexture(value);
                                }
                              },
                            ),
                          ),

                          SizedBox(height: 16),

                          ListTile(
                            title: const Text('Textured Layer Placement (Fit)'),
                            trailing: DropdownMenu<BoxFit>(
                              initialSelection: texturedLayer.fit,
                              dropdownMenuEntries: const [
                                DropdownMenuEntry(
                                  value: BoxFit.none,
                                  label: 'Tile (Repeat patterns)',
                                ),
                                DropdownMenuEntry(
                                  value: BoxFit.fill,
                                  label: 'Fill (Stretch)',
                                ),
                                DropdownMenuEntry(
                                  value: BoxFit.cover,
                                  label: 'Cover (Crop to fill)',
                                ),
                                DropdownMenuEntry(
                                  value: BoxFit.contain,
                                  label: 'Contain (Fit inside)',
                                ),
                              ],
                              onSelected: (BoxFit? value) {
                                if (value != null) {
                                  ThemeService().setTexturedLayerFit(value);
                                }
                              },
                            ),
                          ),

                          _buildSliderRow(
                            label: 'Opacity',
                            value: currentTextrueOpacity,
                            min: 0,
                            max: 1,
                            valueText:
                                '${(currentTextrueOpacity * 100).round()}%',
                            onChanged: (val) =>
                                setState(() => _tempTextureOpacity = val),
                            onChangeEnd: (val) =>
                                ThemeService().setTexturedLayerOpacity(val),
                          ),

                          const SizedBox(height: 16),
                        ],

                        const Divider(),

                        _buildSliderRow(
                          label: 'Dimmer',
                          value: currentDim,
                          min: 0,
                          max: 1,
                          valueText: '${(currentDim * 100).round()}%',
                          onChanged: (val) => setState(() => _tempDim = val),
                          onChangeEnd: (val) =>
                              ThemeService().setDimmerLevel(val),
                        ),
                      ],
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 8),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildSliderRow({
    required String label,
    required double value,
    required double min,
    required double max,
    required String valueText,
    required ValueChanged<double> onChanged,
    required ValueChanged<double> onChangeEnd,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // The Label
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),

          // The Slider
          Expanded(
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: 20,
              label: valueText,
              onChanged: onChanged,
              onChangeEnd: onChangeEnd,
            ),
          ),

          // The Value
          SizedBox(
            width: 50,
            child: Text(
              valueText,
              textAlign: TextAlign.end, // Align numbers to the right
              style: const TextStyle(
                fontFeatures: [FontFeature.tabularFigures()],
              ),
              // 'tabularFigures' prevents jitter by making all numbers the same width
            ),
          ),
        ],
      ),
    );
  }
}
