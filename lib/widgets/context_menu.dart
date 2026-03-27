import 'package:flutter/material.dart';
import 'package:nordplayer/widgets/frosted_glass.dart';

class ContextMenu {
  static final List<OverlayEntry> _entries = [];

  static void closeAll() {
    for (var entry in _entries) {
      entry.remove();
    }
    _entries.clear();
  }

  static void closeMenusBeyond(int depth) {
    while (_entries.length > depth + 1) {
      _entries.removeLast().remove();
    }
  }

  static void show({
    bool isAdaptive = false,
    required BuildContext context,
    required Offset globalPosition,
    required List<ContextMenuEntry> actionMenus,
    int depth = 0,
  }) {
    if (depth == 0) {
      closeAll();
    } else {
      closeMenusBeyond(depth - 1);
    }

    final OverlayState overlayState = Overlay.of(context, rootOverlay: true);
    final RenderBox overlayBox =
        overlayState.context.findRenderObject() as RenderBox;

    const double menuWidth = 240;
    final double menuHeight = (actionMenus.length * 36.0) + 8.0;

    double dx = globalPosition.dx;
    double dy = globalPosition.dy;

    if (dx + menuWidth > overlayBox.size.width) {
      if (depth == 0) {
        dx = globalPosition.dx - menuWidth;
      } else {
        dx = globalPosition.dx - menuWidth;
      }
    }

    if (dy + menuHeight > overlayBox.size.height) {
      dy = overlayBox.size.height - menuHeight - 8;
    }

    if (dx < 0) dx = 0;
    if (dy < 0) dy = 0;

    late OverlayEntry currentEntry;

    currentEntry = OverlayEntry(
      builder: (context) {
        final maxHeight = overlayBox.size.height - dy - 16;

        return Positioned(
          left: dx,
          top: dy,
          child: TapRegion(
            groupId: 'context_menu',
            onTapOutside: (_) {
              if (_entries.contains(currentEntry)) {
                closeAll();
              }
            },
            child: FrostedGlass(
              blurSigma: isAdaptive ? 10 : 0,
              child: Material(
                color: isAdaptive
                    ? Theme.of(
                        context,
                      ).colorScheme.surfaceContainer.withValues(alpha: 0.6)
                    : Theme.of(context).colorScheme.surfaceContainer,
                elevation: 8.0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: menuWidth,
                    maxHeight: maxHeight < 200 ? 200 : maxHeight,
                  ),
                  child: SingleChildScrollView(
                    child: _ContextMenuUI(
                      isAdaptive: isAdaptive,
                      entries: actionMenus,
                      onClose: closeAll,
                      depth: depth,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    _entries.add(currentEntry);
    overlayState.insert(currentEntry);
  }
}

sealed class ContextMenuEntry {}

class ContextMenuActions extends ContextMenuEntry {
  final IconData icon;
  final String label;
  final String? shortcut;
  final VoidCallback onTap;
  final bool isDestructive;

  ContextMenuActions({
    required this.icon,
    required this.label,
    this.shortcut,
    required this.onTap,
    this.isDestructive = false,
  });
}

class ContextMenuDivider extends ContextMenuEntry {}

class ContextSubMenuAction extends ContextMenuEntry {
  final IconData icon;
  final String label;
  final List<ContextMenuEntry> children;

  ContextSubMenuAction({
    required this.icon,
    required this.label,
    required this.children,
  });
}

// Add this right below ContextSubMenuAction
class ContextMenuCustomWidget extends ContextMenuEntry {
  final Widget child;
  ContextMenuCustomWidget({required this.child});
}

class _ContextMenuUI extends StatelessWidget {
  final List<ContextMenuEntry> entries;
  final VoidCallback onClose;
  final int depth;
  final bool isAdaptive;

  const _ContextMenuUI({
    required this.entries,
    required this.onClose,
    required this.depth,
    required this.isAdaptive,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: entries.map((entry) => _buildEntry(context, entry)).toList(),
      ),
    );
  }

  Widget _buildCustomMenuItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    String? shortcut,
    bool isSubMenu = false,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 1.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: color),
                ),
              ),
              if (shortcut != null)
                Text(
                  shortcut,
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.5),
                    fontSize: 12,
                    letterSpacing: 1,
                  ),
                ),
              if (isSubMenu) Icon(Icons.chevron_right, size: 16, color: color),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEntry(BuildContext context, ContextMenuEntry entry) {
    final theme = Theme.of(context);

    return switch (entry) {
      ContextMenuActions() => MouseRegion(
        onEnter: (_) => ContextMenu.closeMenusBeyond(depth),
        child: _buildCustomMenuItem(
          context: context,
          icon: entry.icon,
          label: entry.label,
          shortcut: entry.shortcut,
          color: entry.isDestructive
              ? theme.colorScheme.error
              : theme.colorScheme.onSurface,
          onTap: () {
            entry.onTap();
            onClose();
          },
        ),
      ),

      ContextMenuDivider() => MouseRegion(
        onEnter: (_) => ContextMenu.closeMenusBeyond(depth),
        child: Divider(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
          height: 9,
          thickness: 1,
        ),
      ),

      ContextSubMenuAction() => Builder(
        builder: (itemContext) {
          return MouseRegion(
            onEnter: (_) => _handleSubMenu(itemContext, entry, depth),
            child: _buildCustomMenuItem(
              context: context,
              icon: entry.icon,
              label: entry.label,
              isSubMenu: true,
              color: theme.colorScheme.onSurface,
              onTap: () {},
            ),
          );
        },
      ),

      ContextMenuCustomWidget() => entry.child,
    };
  }

  void _handleSubMenu(
    BuildContext itemContext,
    ContextSubMenuAction subMenu,
    int currentDepth,
  ) {
    final RenderBox box = itemContext.findRenderObject() as RenderBox;
    final Offset position = box.localToGlobal(Offset.zero);
    final Size size = box.size;

    final OverlayState overlayState = Overlay.of(
      itemContext,
      rootOverlay: true,
    );
    final RenderBox overlayBox =
        overlayState.context.findRenderObject() as RenderBox;

    const double subMenuWidth = 240; // Must match the constant above

    double dx = position.dx + size.width;

    // Flip to left if it overflows right screen edge
    if (dx + subMenuWidth > overlayBox.size.width) {
      dx = position.dx - subMenuWidth;
    }

    ContextMenu.show(
      isAdaptive: isAdaptive,
      context: itemContext,
      globalPosition: Offset(dx, position.dy - 4),
      actionMenus: subMenu.children,
      depth: currentDepth + 1,
    );
  }
}
