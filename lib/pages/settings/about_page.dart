import 'package:flutter/material.dart';
import 'package:nordplayer/utils/string_extensions.dart';
import 'package:package_info_plus/package_info_plus.dart';

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
      onTap: () async {
        PackageInfo packageInfo = await PackageInfo.fromPlatform();

        // If the user closed the page while we were waiting, abort!
        if (!context.mounted) return;

        showAboutDialog(
          context: context,
          applicationName: packageInfo.appName.pascalCase,
          applicationVersion: packageInfo.version,
          applicationIcon: const Icon(Icons.music_note, size: 50),
          applicationLegalese: 'Copyright (c) 2025 Nordplayer',
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
