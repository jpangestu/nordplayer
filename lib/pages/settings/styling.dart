import 'package:flutter/material.dart';
import 'package:suara/models/texture_profile';
import 'package:suara/services/theme_service.dart';

class Styling extends StatelessWidget {
  const Styling({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: ThemeService().themeStream,
      initialData: ThemeService().currentTheme,
      builder: (context, themeSnap) {
        return StreamBuilder(
          stream: ThemeService().adaptiveBackgroundStream,
          initialData: ThemeService().adaptiveBackground,
          builder: (context, bgSnap) {
            return StreamBuilder(
              stream: ThemeService().texturedLayeredStream,
              initialData: ThemeService().texturedLayer,
              builder: (context, textureSnap) {
                return StreamBuilder(
                  stream: ThemeService().dimmerStream,
                  initialData: ThemeService().dimmerLevel,
                  builder: (context, dimmerSnap) {
                    final currentTheme =
                        themeSnap.data ?? ThemeService().currentTheme;
                    final adaptiveBg =
                        bgSnap.data ?? ThemeService().adaptiveBackground;
                    final textureLayer =
                        textureSnap.data ?? ThemeService().texturedLayer;
                    final dimmerLevel =
                        dimmerSnap.data ?? ThemeService().dimmerLevel;

                    List<TextureProfile> allTextures =
                        ThemeService().allTextures;

                    return ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        const SectionHeader(title: 'Appearance'),

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
                            onSelected: (val) {
                              if (val != null) ThemeService().setTheme(val);
                            },
                          ),
                        ),

                        const SizedBox(height: 16),
                        const Divider(),

                        const SectionHeader(title: 'Immersive Background'),

                        SwitchListTile(
                          value: adaptiveBg.isEnabled,
                          title: const Text('Adaptive Background'),
                          subtitle: const Text('Use album art as background'),
                          onChanged: ThemeService().setAdaptiveBackgroundMode,
                        ),

                        if (adaptiveBg.isEnabled) ...[
                          const SizedBox(height: 8),
                          ListTile(
                            title: const Text('Album Art Placement (Fit)'),
                            trailing: DropdownMenu<BoxFit>(
                              initialSelection: adaptiveBg.fit,
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
                          InteractiveSliderTile(
                            label: 'Blur',
                            value: adaptiveBg.blur,
                            min: 0,
                            max: 100,
                            labelBuilder: (val) => '${val.round()}px',
                            onChanged: ThemeService().setAdaptiveBackgroundBlur,
                            onChangeEnd:
                                ThemeService().saveAdaptiveBackgroundBlur,
                          ),
                          const SizedBox(height: 16),
                        ],

                        const Divider(),

                        SwitchListTile(
                          value: textureLayer.isEnabled,
                          title: const Text('Textured Layer'),
                          subtitle: const Text(
                            'Add texture layer on top of album art',
                          ),
                          onChanged: ThemeService().setTexturedLayerMode,
                        ),

                        if (textureLayer.isEnabled) ...[
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
                              initialSelection: textureLayer.fit,
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

                          InteractiveSliderTile(
                            label: 'Opacity',
                            value: textureLayer.opacity,
                            min: 0,
                            max: 1,
                            labelBuilder: (val) => '${(val * 100).round()}%',
                            onChanged: ThemeService().setTexturedLayerOpacity,
                            onChangeEnd:
                                ThemeService().saveTexturedLayerOpacity,
                          ),
                          const SizedBox(height: 16),
                        ],

                        const Divider(),

                        InteractiveSliderTile(
                          label: 'Dimmer',
                          value: dimmerLevel,
                          min: 0,
                          max: 1,
                          labelBuilder: (val) => '${(val * 100).round()}%',
                          onChanged: (val) => ThemeService().setDimmer(val),
                          onChangeEnd: (_) => ThemeService().saveDimmerLevel(),
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
}

class SectionHeader extends StatelessWidget {
  final String title;

  const SectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
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
}

class InteractiveSliderTile extends StatefulWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final String Function(double)
  labelBuilder; // Custom text format (e.g. "50px")
  final ValueChanged<double>? onChanged; // Optional: for live preview
  final ValueChanged<double> onChangeEnd; // Commit data (save to DB/Service)

  const InteractiveSliderTile({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.labelBuilder,
    this.onChanged,
    required this.onChangeEnd,
  });

  @override
  State<InteractiveSliderTile> createState() => _InteractiveSliderTileState();
}

class _InteractiveSliderTileState extends State<InteractiveSliderTile> {
  late double _localValue;

  @override
  void initState() {
    super.initState();
    _localValue = widget.value;
  }

  @override
  void didUpdateWidget(covariant InteractiveSliderTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the service updates the value externally (e.g. reset to default),
    if (oldWidget.value != widget.value) {
      _localValue = widget.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(
              widget.label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Slider(
              value: _localValue,
              min: widget.min,
              max: widget.max,
              divisions: 20,
              label: widget.labelBuilder(_localValue),
              onChanged: (val) {
                // Update LOCAL UI instantly (60fps)
                setState(() => _localValue = val);
                // Notify parent if they want "live" updates (optional)
                widget.onChanged?.call(val);
              },
              onChangeEnd: (val) {
                // Commit the heavy save operation only when user lets go
                widget.onChangeEnd(val);
              },
            ),
          ),
          SizedBox(
            width: 50,
            child: Text(
              widget.labelBuilder(_localValue),
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
