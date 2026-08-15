import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nordplayer/models/library_section_config.dart';
import 'package:nordplayer/services/config_service.dart';
import 'package:nordplayer/theming/icon-sets/app_icon_set.dart';
import 'package:nordplayer/widgets/app_icon.dart';
import 'package:nordplayer/widgets/frosted_glass.dart';

void showLibrarySectionsPanel(BuildContext context, GlobalKey buttonKey) {
  if (buttonKey.currentContext == null) return;
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
            // 280 is the fixed width of the panel
            left: offset.dx - 280 + renderBox.size.width,
            child: FadeTransition(opacity: animation, child: const LibrarySectionsPanel()),
          ),
        ],
      );
    },
  );
}

class LibrarySectionsPanel extends ConsumerStatefulWidget {
  const LibrarySectionsPanel({super.key});

  @override
  ConsumerState<LibrarySectionsPanel> createState() => _LibrarySectionsPanelState();
}

class _LibrarySectionsPanelState extends ConsumerState<LibrarySectionsPanel> {
  late List<LibrarySectionConfig> _localSections;

  @override
  void initState() {
    super.initState();
    // Read current config state locally to initialize drag state
    final currentConfig = ref.read(configServiceProvider).requireValue;
    _localSections = List<LibrarySectionConfig>.from(currentConfig.librarySections);
  }

  String _getSectionName(String id) {
    switch (id) {
      case 'recently_added':
        return 'Recently Added';
      case 'albums':
        return 'Albums';
      case 'tracks':
        return 'Tracks';
      default:
        return id;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final adaptiveBg = ref.watch(configServiceProvider.select((config) => config.requireValue.adaptiveBg));
    final adaptiveBgThemeOverlay = ref.watch(
      configServiceProvider.select((config) => config.requireValue.adaptiveBgThemeOverlay),
    );
    final adaptiveBgPanelBlur = ref.watch(
      configServiceProvider.select((config) => config.requireValue.adaptiveBgPanelBlur),
    );
    final appIconSet = ref.watch(appIconProvider);

    return Material(
      type: MaterialType.transparency, // Required for text rendering inside a Stack
      child: FrostedGlass(
        backgroundColor: adaptiveBg
            ? theme.colorScheme.surfaceContainerHigh.withValues(alpha: adaptiveBgThemeOverlay)
            : theme.colorScheme.surfaceContainerHigh,
        blurSigma: adaptiveBgPanelBlur,
        borderRadius: 12.0,
        child: Container(
          width: 280,
          constraints: const BoxConstraints(maxHeight: 350),
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.outlineVariant, width: adaptiveBg ? 0 : 2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 16.0, bottom: 8.0),
                child: Text(
                  'CUSTOMIZE SECTIONS',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    letterSpacing: 1.0,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Flexible(
                child: ReorderableListView.builder(
                  buildDefaultDragHandles: false,
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  itemCount: _localSections.length,
                  onReorderItem: (oldIndex, newIndex) {
                    setState(() {
                      final item = _localSections.removeAt(oldIndex);
                      _localSections.insert(newIndex, item);
                    });
                    ref.read(configServiceProvider.notifier).updateConfig(librarySections: _localSections);
                  },
                  itemBuilder: (context, index) {
                    final section = _localSections[index];
                    return ListTile(
                      key: ValueKey(section.id),
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12.0),
                      title: Text(_getSectionName(section.id), style: theme.textTheme.bodyMedium),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ReorderableDragStartListener(
                            index: index,
                            child: AppIcon(
                              appIconSet.dragVertical,
                              color: theme.colorScheme.onSurfaceVariant,
                              size: 20,
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _localSections[index] = section.copyWith(isVisible: !section.isVisible);
                              });
                              ref.read(configServiceProvider.notifier).updateConfig(librarySections: _localSections);
                            },
                            icon: AppIcon(
                              section.isVisible ? appIconSet.visible : appIconSet.invisible,
                              color: theme.colorScheme.onSurfaceVariant,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
