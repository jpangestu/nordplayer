import 'package:flutter/material.dart';

class Sidebar extends StatefulWidget {
  final Widget? leading;
  final int? selectedIndex;
  final List<SidebarDestination> destinations;
  final void Function(int)? onDestinationSelected;
  final bool showExtendedToggle;
  final bool? isExtended;
  final VoidCallback? onExtendedToggle;

  /// Will be placed at the bottom
  final Widget? trailing;

  /// Width when expanded
  final double? width;
  final bool isAdaptive;

  const Sidebar({
    super.key,
    this.leading,
    required this.selectedIndex,
    required this.destinations,
    this.onDestinationSelected,
    this.showExtendedToggle = true,
    this.isExtended,
    this.onExtendedToggle,
    this.trailing,
    this.width,
    this.isAdaptive = false,
  }) : assert(
         selectedIndex == null ||
             (0 <= selectedIndex && selectedIndex < destinations.length),
       );

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  static const double collapsedWidth = 64.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final navTheme = theme.navigationRailTheme;
    final double expandedWidth = widget.width ?? 180;

    return AnimatedContainer(
      duration: Duration.zero,
      width: widget.isExtended ?? true ? expandedWidth : collapsedWidth,
      color: widget.isAdaptive
          ? (navTheme.backgroundColor ?? theme.colorScheme.surfaceContainer)
                .withValues(alpha: 0.6)
          : navTheme.backgroundColor ?? theme.colorScheme.surfaceContainer,

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
                      destination.subLabel,
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
                        destination.subLabel,
                      ),
                    ),
                  ],
              ],
            ),
          ),

          if (widget.trailing != null) widget.trailing!,
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
    Widget? subLabel,
  ) {
    final bool isSelected = widget.selectedIndex == index;
    final theme = Theme.of(context);

    final baseBackgroundColor =
        theme.navigationRailTheme.indicatorColor ??
        theme.colorScheme.secondaryContainer;

    final backgroundColor = isSelected
        ? widget.isAdaptive
              ? baseBackgroundColor.withValues(alpha: 0.4)
              : baseBackgroundColor
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

    final secondaryColor =
        theme.navigationRailTheme.unselectedIconTheme?.color ??
        theme.colorScheme.onSurfaceVariant;
    final subLabelColor =
        (theme.listTileTheme.subtitleTextStyle ?? theme.textTheme.bodyMedium)!
            .color;

    final textScale = MediaQuery.textScalerOf(context);
    final double minHeight = subLabel != null ? 56.0 : 48.0;

    return Container(
      constraints: BoxConstraints(minHeight: textScale.scale(minHeight)),
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Material(
        color: Colors.transparent,
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
                if (widget.isExtended != null && widget.isExtended == true) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: .center,
                      crossAxisAlignment: .start,
                      children: [
                        labelWidget,
                        if (subLabel != null) ...[
                          DefaultTextStyle(
                            style:
                                (theme.listTileTheme.subtitleTextStyle ??
                                        theme.textTheme.bodyMedium)!
                                    .copyWith(
                                      color: isSelected
                                          ? secondaryColor
                                          : subLabelColor,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                            child: subLabel,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
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
    this.subLabel,
  }) : selectedIcon = selectedIcon ?? icon;

  final Widget icon;
  final Widget selectedIcon;
  final Widget label;
  final Widget? subLabel;
}
