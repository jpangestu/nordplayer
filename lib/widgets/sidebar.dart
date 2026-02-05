import 'package:flutter/material.dart';

class Sidebar extends StatelessWidget {
  final bool isExpanded;
  final int selectedIndex;
  final Function(int) onIndexChanged;
  final VoidCallback onToggle;

  final double collapsedWidth = 64.0;
  final double expandedWidth = 180.0;

  const Sidebar({
    super.key,
    required this.isExpanded,
    required this.selectedIndex,
    required this.onIndexChanged,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final navTheme = theme.navigationRailTheme;

    return AnimatedContainer(
      duration: Duration.zero,
      width: isExpanded ? expandedWidth : collapsedWidth,
      color: navTheme.backgroundColor ?? theme.colorScheme.surfaceContainer,

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: IconButton(
              icon: const Icon(Icons.menu),
              onPressed: onToggle,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              style: IconButton.styleFrom(
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                foregroundColor: navTheme.unselectedIconTheme?.color,
              ),
            ),
          ),

          Expanded(
            child: ListView(
              children: [
                _buildItem(
                  context,
                  0,
                  Icons.library_music_outlined,
                  Icons.library_music,
                  "Library",
                ),
                _buildItem(
                  context,
                  1,
                  Icons.playlist_play_outlined,
                  Icons.playlist_play,
                  "Playlists",
                ),
                _buildItem(
                  context,
                  2,
                  Icons.album_outlined,
                  Icons.album,
                  "Albums",
                ),
                _buildItem(
                  context,
                  3,
                  Icons.person_outline,
                  Icons.person,
                  "Artists",
                ),
                _buildItem(
                  context,
                  4,
                  Icons.settings_outlined,
                  Icons.settings,
                  "Settings",
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(
    BuildContext context,
    int index,
    IconData icon,
    IconData? selectedIcon,
    String label,
  ) {
    final bool isSelected = selectedIndex == index;
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

    return Container(
      height: 48.0,
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: InkWell(
        onTap: () => onIndexChanged(index),
        borderRadius: BorderRadius.circular(10.0),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Row(
            children: [
              Icon(
                (isSelected && selectedIcon != null) ? selectedIcon : icon,
                color: foregroundColor,
                size: 24,
              ),
              if (isExpanded) ...[
                const SizedBox(width: 24),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: foregroundColor,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
