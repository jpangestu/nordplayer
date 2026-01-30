import 'package:flutter/material.dart';
import 'package:suara/services/theme_service.dart';

class Styling extends StatefulWidget {
  const Styling({super.key});

  @override
  State<Styling> createState() => _StylingState();
}

class _StylingState extends State<Styling> {
  // Use local state for sliders only to prevent "Stream Jitter"
  // (rebuilding the whole app 60 times a second while dragging).
  // Commit to the Service only when the user lets go.
  double? _tempOpacity;
  double? _tempBlur;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: ThemeService().themeStream,
      builder: (context, snapshot) {
        // Grab current values from Service
        final currentTheme = ThemeService().currentTheme;
        final isImmersive = ThemeService().isImmersive;
        // Fallback to defaults if service doesn't have these getters yet
        final currentOpacity = _tempOpacity ?? 0.5; // TODO: change default
        final currentBlur = _tempBlur ?? 40.0;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSectionHeader('Appearance'),
            ListTile(
              leading: const Icon(Icons.palette_outlined),
              title: const Text('App Theme'),
              // DropdownMenu is fine here as long as it fits
              trailing: DropdownMenu<ThemeMode>(
                initialSelection: currentTheme,
                width: 185, // Optional: Limit width to prevent layout issues
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
              value: isImmersive,
              title: const Text('Adaptive Blur'),
              subtitle: const Text('Use album art as background'),
              onChanged: (value) {
                setState(() {
                  ThemeService().setImmersiveMode(value);
                });
              },
            ),

            if (isImmersive) ...[
              const SizedBox(height: 8),

              // FIX: Changed EdgeInsetsGeometry to EdgeInsets
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Text('Dimming'),
                    const SizedBox(width: 16),
                    // Expanded is valid here because the parent is Row
                    Expanded(
                      child: Slider(
                        value: currentOpacity,
                        min: 0,
                        max: 1,
                        label: '${(currentOpacity * 100).round()}%',
                        divisions: 20,
                        onChanged: (value) {
                          setState(() {
                            _tempOpacity = value;
                          });
                        },
                        onChangeEnd: (value) {
                          // TODO: Call ThemeService().setOpacity(value);
                          _tempOpacity = null; // Reset temp
                        },
                      ),
                    ),
                    Text('${(currentOpacity * 100).round()}%'),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Text('Blur'),
                    const SizedBox(
                      width: 48,
                    ), // Aligns "Blur" text roughly with "Dimming"
                    // Expanded is valid here because the parent is Row
                    Expanded(
                      child: Slider(
                        value: currentBlur,
                        min: 0,
                        max: 100,
                        label: '${currentBlur.round()} px',
                        divisions: 20,
                        onChanged: (value) {
                          setState(() {
                            _tempBlur = value;
                          });
                        },
                      ),
                    ),
                    Text('${currentBlur.round()} px'),
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
}
