import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nordplayer/services/config_service.dart';
import 'package:nordplayer/widgets/frosted_glass.dart';

void showShortcutsPanel(BuildContext context, GlobalKey buttonKey) {
  // Get the exact position and size of the button
  final renderBox = buttonKey.currentContext!.findRenderObject() as RenderBox;
  final offset = renderBox.localToGlobal(Offset.zero);

  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss',
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 150),
    pageBuilder: (context, animation, secondaryAnimation) {
      return Stack(
        children: [
          Positioned(
            // Position 8 pixels below the bottom edge of the button
            top: offset.dy + renderBox.size.height + 8,
            // Align the right edge of the panel with the right edge of the button
            // 320 is the fixed width of the panel
            left: offset.dx - 320 + renderBox.size.width,
            child: FadeTransition(opacity: animation, child: const KeyboardShortcutsPanel()),
          ),
        ],
      );
    },
  );
}

class KeyboardShortcutsPanel extends ConsumerWidget {
  const KeyboardShortcutsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final appConfig = ref.watch(configServiceProvider).requireValue;

    final categories = [
      _Category('Playback', [
        _Item('Play/Pause', ['Space']),
        _Item('Skip to Next', ['Ctrl', '→']),
        _Item('Skip to Previous', ['Ctrl', '←']),
        _Item('Shuffle', ['Ctrl', 'S']),
        _Item('Loop Mode', ['Ctrl', 'L']),
      ]),
      _Category('Audio', [
        _Item('Volume Up', ['Ctrl', '↑']),
        _Item('Volume Down', ['Ctrl', '↓']),
        _Item('Mute', ['M']),
      ]),
      _Category('Application', [
        _Item('Global Search', ['Ctrl', 'K']),
        _Item('Close Search', ['Esc']),
      ]),
    ];

    return Material(
      type: MaterialType.transparency, // Required for text rendering inside a Stack
      child: FrostedGlass(
        backgroundColor: appConfig.adaptiveBg
            ? theme.colorScheme.surfaceContainerHigh.withValues(alpha: appConfig.adaptiveBgThemeOverlay)
            : theme.colorScheme.surfaceContainerHigh,
        blurSigma: appConfig.adaptiveBgPanelBlur,
        borderRadius: 12.0,
        child: Container(
          width: 320, // Fixed width for the popover
          constraints: const BoxConstraints(maxHeight: 450), // Won't grow taller than this
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.outlineVariant, width: appConfig.adaptiveBg ? 0 : 2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListView.separated(
            padding: const .symmetric(vertical: 16, horizontal: 20),
            shrinkWrap: true,
            itemCount: categories.length,
            separatorBuilder: (_, _) => const SizedBox(height: 20),
            itemBuilder: (context, index) {
              final cat = categories[index];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cat.title.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      letterSpacing: 1.0,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...cat.items.map(
                    (item) => Padding(
                      padding: const .symmetric(vertical: 4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(item.label, style: theme.textTheme.bodyMedium),
                          Row(
                            children: [
                              for (int i = 0; i < item.keys.length; i++) ...[
                                _KeyBadge(label: item.keys[i]),
                                if (i < item.keys.length - 1)
                                  Padding(
                                    padding: const .symmetric(horizontal: 4),
                                    child: Text('+', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                                  ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Category {
  final String title;
  final List<_Item> items;
  _Category(this.title, this.items);
}

class _Item {
  final String label;
  final List<String> keys;
  _Item(this.label, this.keys);
}

class _KeyBadge extends StatelessWidget {
  final String label;
  const _KeyBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const .symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    );
  }
}
