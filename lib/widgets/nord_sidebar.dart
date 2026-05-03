import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:nordplayer/theming/theme-extension/nord_sidebar_theme.dart';

class Sidebar extends StatelessWidget {
  const Sidebar({
    super.key,
    this.isExtended = true,
    required this.destinations,
    this.onDestinationSelected,
    required this.selectedIndex,
    this.leading,
    this.backgroundColor,
    this.itemBackgroundColor,
    this.itemForegroundColor,
    this.collapseWidth = 64.0,
    this.extendedWidth = 180.0,
    this.sidebarBorderRadius = BorderRadius.zero,
    this.isAdaptiveBgOn = false,
    this.adaptiveBgPanelBlur = 10.0,
    this.adaptiveBgThemeOverlay = 0.6,
  });
  // : assert(selectedIndex == null || (0 <= selectedIndex && selectedIndex < destinations.length));

  final bool isExtended;
  final List<SidebarDestination> destinations;
  final void Function(int)? onDestinationSelected;
  final int? selectedIndex;
  final Widget? leading;
  final Color? backgroundColor;
  final WidgetStateProperty<Color?>? itemBackgroundColor;
  final WidgetStateProperty<Color?>? itemForegroundColor;
  final double collapseWidth;
  final double extendedWidth;
  final BorderRadius sidebarBorderRadius;
  final bool isAdaptiveBgOn;
  final double adaptiveBgPanelBlur;
  final double adaptiveBgThemeOverlay;

  @override
  Widget build(BuildContext context) {
    final sidebarTheme = Theme.of(context).extension<NordSidebarTheme>();

    // Widget Prop -> Theme Extension -> Fallback color
    final resolvedBgColor =
        backgroundColor ?? sidebarTheme?.backgroundColor ?? Theme.of(context).colorScheme.surfaceContainer;
    final finalBgColor = isAdaptiveBgOn ? resolvedBgColor.withValues(alpha: adaptiveBgThemeOverlay) : resolvedBgColor;

    // Separate destinations while keeping original indices
    final topIndices = <int>[];
    final bottomIndices = <int>[];

    for (int i = 0; i < destinations.length; i++) {
      if (destinations[i].alignToBottom) {
        bottomIndices.add(i);
      } else {
        topIndices.add(i);
      }
    }

    Widget sidebarContent = Container(
      width: isExtended ? extendedWidth : collapseWidth,
      decoration: BoxDecoration(color: finalBgColor, borderRadius: sidebarBorderRadius),
      child: Column(
        crossAxisAlignment: .start,
        children: [
          leading ?? const SizedBox.shrink(),
          Expanded(
            child: CustomScrollView(
              slivers: [
                // Top items
                SliverList(
                  delegate: SliverChildListDelegate([
                    for (var i in topIndices) _buildItem(context, i, destinations[i]),
                  ]),
                ),
                // Bottom items pushed to the end
                SliverFillRemaining(
                  hasScrollBody: false, // Essential for pushing content to the bottom
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      for (var i in bottomIndices) _buildItem(context, i, destinations[i]),
                      const SizedBox(height: 8.0),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (isAdaptiveBgOn && adaptiveBgPanelBlur > 0) {
      return ClipRRect(
        borderRadius: sidebarBorderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: adaptiveBgPanelBlur, sigmaY: adaptiveBgPanelBlur, tileMode: TileMode.mirror),
          child: sidebarContent,
        ),
      );
    }

    if (sidebarBorderRadius != BorderRadius.zero) {
      return ClipRRect(borderRadius: sidebarBorderRadius, child: sidebarContent);
    }

    return sidebarContent;
  }

  Widget _buildItem(BuildContext context, int index, SidebarDestination destination) {
    final theme = Theme.of(context);
    final sidebarTheme = theme.extension<NordSidebarTheme>();

    final bool isSelected = selectedIndex == index;

    final states = <WidgetState>{if (isSelected) WidgetState.selected};

    // Widget Prop -> Theme Extension -> Fallback color
    final resolvedBgColor =
        itemBackgroundColor?.resolve(states) ??
        sidebarTheme?.itemBackgroundColor?.resolve(states) ??
        (isSelected ? theme.colorScheme.secondaryContainer : Colors.transparent);

    final resolvedFgColor =
        itemForegroundColor?.resolve(states) ??
        sidebarTheme?.itemForegroundColor?.resolve(states) ??
        (isSelected ? theme.colorScheme.onSecondaryContainer : theme.colorScheme.onSurfaceVariant);

    final resolvedHoverColor = isAdaptiveBgOn
        ? theme.colorScheme.onSurface.withValues(alpha: 0.08)
        : itemBackgroundColor?.resolve({WidgetState.hovered}) ??
              sidebarTheme?.itemBackgroundColor?.resolve({WidgetState.hovered});

    final resolvedFocusColor = isAdaptiveBgOn
        ? theme.colorScheme.onSurface.withValues(alpha: 0.12)
        : itemBackgroundColor?.resolve({WidgetState.focused}) ??
              sidebarTheme?.itemBackgroundColor?.resolve({WidgetState.focused});

    final resolvedPressedColor = isAdaptiveBgOn
        ? theme.colorScheme.onSurface.withValues(alpha: 0.16)
        : itemBackgroundColor?.resolve({WidgetState.pressed}) ??
              sidebarTheme?.itemBackgroundColor?.resolve({WidgetState.pressed});

    final finalBgColor = isSelected
        ? (isAdaptiveBgOn ? theme.colorScheme.primary.withValues(alpha: 0.15) : resolvedBgColor)
        : resolvedBgColor;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(color: finalBgColor, borderRadius: BorderRadius.circular(8.0)),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          hoverColor: resolvedHoverColor,
          focusColor: resolvedFocusColor,
          highlightColor: resolvedPressedColor,
          // Disable splash color
          splashColor: Colors.transparent,
          borderRadius: BorderRadius.circular(8.0),
          onTap: () => onDestinationSelected?.call(index),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
            child: Row(
              children: [
                IconTheme(
                  data: IconThemeData(color: resolvedFgColor, size: 24),
                  child: isSelected ? destination.selectedIcon : destination.icon,
                ),
                if (isExtended) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    child: DefaultTextStyle(
                      style: theme.textTheme.bodyLarge!.copyWith(
                        color: resolvedFgColor,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        overflow: TextOverflow.ellipsis,
                      ),
                      child: destination.label,
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
  const SidebarDestination({required this.icon, Widget? selectedIcon, required this.label, this.alignToBottom = false})
    : selectedIcon = selectedIcon ?? icon;

  final Widget icon;
  final Widget selectedIcon;
  final Widget label;
  final bool alignToBottom;
}
