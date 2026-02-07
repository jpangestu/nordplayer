import 'package:flutter/material.dart';

Widget aboutPage(BuildContext context, bool? isExpanded) {
  final theme = Theme.of(context);

  return Container(
    height: 48.0,
    margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
    decoration: BoxDecoration(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8.0),
    ),
    child: InkWell(
      onTap: () {
        showAboutDialog(
          context: context,
          applicationName: 'Nordplayer',
          applicationVersion: '1.0.0',
          applicationIcon: const Icon(Icons.music_note, size: 50),
          applicationLegalese:
              '© 2026 Penguins Lab\n\n'
              'This application is licensed under the MIT License. '
              'Source code available on GitHub.',
        );
      },
      borderRadius: BorderRadius.circular(10.0),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              size: 24,
              color:
                  theme.navigationRailTheme.unselectedIconTheme?.color ??
                  theme.colorScheme.onSurfaceVariant,
            ),
            if (isExpanded != null && isExpanded == true) ...[
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'About',
                  style: TextStyle(
                    color:
                        theme.navigationRailTheme.unselectedIconTheme?.color ??
                        theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.normal,
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
