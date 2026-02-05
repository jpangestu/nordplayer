import 'dart:ui'; // Needed for FontFeature
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:suara/models/app_config.dart';
import 'package:suara/models/texture_profile.dart';
import 'package:suara/services/config_service.dart'; // Replaces ThemeService

class Styling extends StatelessWidget {
  const Styling({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ConfigService(),
      builder: (context, _) {
        final config = ConfigService().config;
        final adaptiveBg = config.adaptiveBackground;
        final texturedLayer = config.texturedLayer;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SectionHeader(title: 'Appearance'),

            ListTile(
              leading: const Icon(Icons.settings_display_outlined),
              title: const Text('App Theme'),
              trailing: DropdownMenu<ThemeMode>(
                initialSelection: config.themeMode,
                dropdownMenuEntries: const [
                  DropdownMenuEntry(
                    value: ThemeMode.system,
                    label: 'System Default',
                  ),
                  DropdownMenuEntry(value: ThemeMode.dark, label: 'Dark'),
                  DropdownMenuEntry(value: ThemeMode.light, label: 'Light'),
                ],
                onSelected: (val) {
                  if (val != null) ConfigService().update(themeMode: val);
                },
              ),
            ),

            const SizedBox(height: 16),
            const Divider(),

            const SectionHeader(title: 'Typography'),

            ListTile(
              leading: const Icon(Icons.font_download_outlined),
              title: const Text('Font Family'),
              trailing: DropdownMenu<String>(
                initialSelection: config.fontFamily,
                dropdownMenuEntries: AppConfig.availableFonts
                    .map<DropdownMenuEntry<String>>((String font) {
                      TextStyle? previewStyle;
                      if (font != 'Default') {
                        try {
                          previewStyle = GoogleFonts.getFont(font);
                        } catch (e) {
                          previewStyle = null;
                        }
                      }
                      return DropdownMenuEntry(
                        value: font,
                        label: font,
                        style: ButtonStyle(
                          textStyle: WidgetStatePropertyAll(
                            previewStyle,
                          ),
                        ),
                      );
                    })
                    .toList(),
                onSelected: (val) {
                  if (val != null) ConfigService().update(fontFamily: val);
                },
              ),
            ),

            const Divider(),

            const SectionHeader(title: 'Immersive Background'),

            SwitchListTile(
              value: adaptiveBg.isEnabled,
              title: const Text('Adaptive Background'),
              subtitle: const Text('Use album art as background'),
              onChanged: (val) {
                ConfigService().update(
                  adaptiveBackground: adaptiveBg.copyWith(isEnabled: val),
                );
              },
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
                      ConfigService().update(
                        adaptiveBackground: adaptiveBg.copyWith(fit: value),
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
                // We use onChanged for LIVE preview.
                // ConfigService handles the debouncing (saving) internally.
                onChanged: (val) {
                  ConfigService().update(
                    adaptiveBackground: adaptiveBg.copyWith(blur: val),
                  );
                },
                // We pass an empty function because the widget requires it,
                // but the service handles the saving automatically now.
                onChangeEnd: (_) {},
              ),
              const SizedBox(height: 16),
            ],

            const Divider(),

            SwitchListTile(
              value: texturedLayer.isEnabled,
              title: const Text('Textured Layer'),
              subtitle: const Text('Add texture layer on top of album art'),
              onChanged: (val) {
                ConfigService().update(
                  texturedLayer: texturedLayer.copyWith(isEnabled: val),
                );
              },
            ),

            if (texturedLayer.isEnabled) ...[
              const SizedBox(height: 8),

              ListTile(
                title: const Text('Select Texture'),
                trailing: DropdownMenu<TextureProfile>(
                  // Force redraw if ID changes
                  key: ValueKey(config.activeTexture.id),
                  initialSelection: config.activeTexture,
                  // Use the helper from AppConfig
                  dropdownMenuEntries: config.allTextures
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
                      ConfigService().update(activeTexture: value);
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
                      ConfigService().update(
                        texturedLayer: texturedLayer.copyWith(fit: value),
                      );
                    }
                  },
                ),
              ),

              InteractiveSliderTile(
                label: 'Opacity',
                value: texturedLayer.opacity,
                min: 0,
                max: 1,
                labelBuilder: (val) => '${(val * 100).round()}%',
                onChanged: (val) {
                  ConfigService().update(
                    texturedLayer: texturedLayer.copyWith(opacity: val),
                  );
                },
                onChangeEnd: (_) {},
              ),
              const SizedBox(height: 16),
            ],

            const Divider(),

            InteractiveSliderTile(
              label: 'Dimmer',
              value: config.globalDimmer,
              min: 0,
              max: 1,
              labelBuilder: (val) => '${(val * 100).round()}%',
              onChanged: (val) => ConfigService().update(globalDimmer: val),
              onChangeEnd: (_) {},
            ),
          ],
        );
      },
    );
  }
}

// ... Rest of your file (SectionHeader, InteractiveSliderTile) stays exactly the same ...
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
