import 'package:material_ui/material_ui.dart';
import 'package:nordplayer/widgets/popover_panel.dart';

class KeyboardShortcutsPanel extends StatelessWidget {
  const KeyboardShortcutsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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

    return PopoverPanel(
      width: 280,
      constraints: const BoxConstraints(maxHeight: 450),
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
              // Section Header
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
                                child: Text(
                                  '+',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'jetbrains_mono',
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
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
