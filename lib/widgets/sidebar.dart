import 'package:flutter/material.dart';

class Sidebar extends StatefulWidget {
  final Widget? leading;
  final int? selectedIndex;
  final List<SidebarDestination> destinations;
  final void Function(int)? onDestinationSelected;
  final bool showExtendedToggle;
  final bool? isExpanded;
  final VoidCallback? onExtendedToggle;
  final Widget? trailing;
  final Widget? bottom;

  const Sidebar({
    super.key,
    this.leading,
    required this.selectedIndex,
    required this.destinations,
    this.onDestinationSelected,
    this.showExtendedToggle = true,
    this.isExpanded,
    this.onExtendedToggle,
    this.trailing,
    this.bottom,
  }) : assert(
         selectedIndex == null ||
             (0 <= selectedIndex && selectedIndex < destinations.length),
       );

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  final double collapsedWidth = 64.0;
  final double expandedWidth = 180.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final navTheme = theme.navigationRailTheme;

    return AnimatedContainer(
      duration: Duration.zero,
      width: widget.isExpanded ?? true ? expandedWidth : collapsedWidth,
      color: navTheme.backgroundColor ?? theme.colorScheme.surfaceContainer,

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.showExtendedToggle)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: IconButton(
                icon: const Icon(Icons.menu),
                onPressed: widget.onExtendedToggle,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                style: IconButton.styleFrom(
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  foregroundColor: navTheme.unselectedIconTheme?.color,
                ),
              ),
            ),

          if (widget.leading != null) widget.leading!,

          Expanded(
            child: ListView(
              children: [
                for (final (index, destination) in widget.destinations.indexed)
                  if (index != widget.destinations.length) ...[
                    _buildItem(
                      context,
                      index,
                      destination.icon,
                      destination.selectedIcon,
                      destination.label,
                    ),
                  ] else ...[
                    Align(
                      alignment: .bottomLeft,
                      child: _buildItem(
                        context,
                        index,
                        destination.icon,
                        destination.selectedIcon,
                        destination.label,
                      ),
                    ),
                  ],
              ],
            ),
          ),

          if (widget.trailing != null) widget.trailing!,
          if (widget.bottom != null)
            Align(alignment: .bottomLeft, child: widget.bottom!),
        ],
      ),
    );
  }

  Widget _buildItem(
    BuildContext context,
    int index,
    Widget icon,
    Widget? selectedIcon,
    Widget label,
  ) {
    final bool isSelected = widget.selectedIndex == index;
    final theme = Theme.of(context);

    final backgroundColor = isSelected
        ? theme.navigationRailTheme.indicatorColor ??
              theme.colorScheme.secondaryContainer
        : Colors.transparent;

    final foregroundColor = isSelected
        ? theme.navigationRailTheme.selectedIconTheme?.color ??
              theme.colorScheme.onSecondaryContainer
        : theme.navigationRailTheme.unselectedIconTheme?.color ??
              theme.colorScheme.onSurfaceVariant;

    final iconWidget = IconTheme(
      data: IconThemeData(color: foregroundColor, size: 24),
      child: isSelected ? selectedIcon ?? icon : icon,
    );

    final labelWidget = DefaultTextStyle(
      style: TextStyle(
        color: foregroundColor,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        overflow: TextOverflow.ellipsis,
      ),
      child: label,
    );

    return Container(
      height: 48.0,
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: InkWell(
        onTap: () {
          if (widget.onDestinationSelected != null) {
            widget.onDestinationSelected!(index);
          }
        },
        borderRadius: BorderRadius.circular(10.0),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Row(
            children: [
              iconWidget,
              if (widget.isExpanded != null && widget.isExpanded == true) ...[
                const SizedBox(width: 16),
                Expanded(child: labelWidget),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class SidebarDestination {
  const SidebarDestination({
    required this.icon,
    Widget? selectedIcon,
    required this.label,
  }) : selectedIcon = selectedIcon ?? icon;

  final Widget icon;
  final Widget selectedIcon;
  final Widget label;
}
