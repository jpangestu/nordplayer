import 'package:flutter/material.dart';
import 'package:suara/services/theme_service.dart';

class Styling extends StatefulWidget {
  const Styling({super.key});

  @override
  State<Styling> createState() => _StylingState();
}

class _StylingState extends State<Styling> {
  double? _tempBlur;
  double? _tempOpactiy;

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
            // Grab current values from Service
            final currentTheme = ThemeService().currentTheme;
            final adaptiveBackground = ThemeService().adaptiveBackground;
            // Fallback to defaults if service doesn't have these getters yet
            final double currentBlur = _tempBlur ?? adaptiveBackground.blur;
            final double currentOpacity =
                _tempOpactiy ?? adaptiveBackground.opacity;

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
                      DropdownMenuEntry(value: ThemeMode.dark, label: 'Dark'),
                      DropdownMenuEntry(value: ThemeMode.light, label: 'Light'),
                    ],
                    onSelected: (value) {
                      setState(() {
                        if (value != null) {
                          ThemeService().setTheme(value);
                        }
                      });
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
                          ThemeService().setAdaptiveBackgroundFit(value);
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

                  _buildSliderRow(
                    label: 'Opacity',
                    value: currentOpacity,
                    min: 0,
                    max: 1,
                    valueText: '${(currentOpacity * 100).round()}%',
                    onChanged: (val) => setState(() => _tempOpactiy = val),
                    onChangeEnd: (val) =>
                        ThemeService().setAdaptiveBackgroundOpacity(val),
                  ),

                  // FIT DROPDOWN (New!)
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        // Reuse the same width logic for alignment
                        const SizedBox(
                          width: 70,
                          child: Text(
                            'Fit',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        Expanded(
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<BoxFit>(
                              value: adaptiveBackground.fit,
                              isExpanded: true,
                              icon: const Icon(Icons.arrow_drop_down),
                              items: const [
                                DropdownMenuItem(
                                  value: BoxFit.cover,
                                  child: Text('Cover (Crop to fill)'),
                                ),
                                DropdownMenuItem(
                                  value: BoxFit.fill,
                                  child: Text('Fill (Stretch)'),
                                ),
                                DropdownMenuItem(
                                  value: BoxFit.contain,
                                  child: Text('Contain (Fit inside)'),
                                ),
                                DropdownMenuItem(
                                  value: BoxFit.fitHeight,
                                  child: Text('Fit Height'),
                                ),
                                DropdownMenuItem(
                                  value: BoxFit.fitWidth,
                                  child: Text('Fit Width'),
                                ),
                              ],
                              onChanged: (BoxFit? newValue) {
                                if (newValue != null) {
                                  ThemeService().setAdaptiveBackgroundFit(
                                    newValue,
                                  );
                                }
                              },
                            ),
                          ),
                        ),
                        // Add dummy spacer to balance the "Value" column of sliders
                        // so the dropdown arrow aligns nicely with slider track end?
                        // Or just let it expand naturally.
                        const SizedBox(width: 50),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                  const Divider(),
                ],
              ],
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
