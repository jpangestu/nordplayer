import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nordplayer/routes/router.dart';
import 'package:nordplayer/services/config_service.dart';

class LibraryPage extends ConsumerStatefulWidget {
  const LibraryPage({super.key});

  @override
  ConsumerState<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends ConsumerState<LibraryPage> {
  bool isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final appConfig = ref.watch(configServiceProvider).requireValue;

    return Scaffold(
      backgroundColor: appConfig.adaptiveBg ? Colors.transparent : Theme.of(context).colorScheme.surface,
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          CollapsibleSection(label: 'Pinned', content: Placeholder()),

          SizedBox(height: 16),

          CollapsibleSection(
            label: 'Playlists',
            onLableClick: () {
              context.go(Routes.playlistsPage);
            },
            content: Placeholder(),
          ),

          SizedBox(height: 16),

          CollapsibleSection(
            label: 'All Tracks',
            onLableClick: () {
              context.go(Routes.allTracksPage);
            },
            content: Placeholder(),
          ),

          SizedBox(height: 16),

          CollapsibleSection(label: 'Recently Added', content: Placeholder()),
        ],
      ),
    );
  }
}

class CollapsibleSection extends StatefulWidget {
  const CollapsibleSection({super.key, required this.label, this.onLableClick, required this.content});

  final String label;
  final void Function()? onLableClick;
  final Widget content;

  @override
  State<CollapsibleSection> createState() => _CollapsibleSectionState();
}

class _CollapsibleSectionState extends State<CollapsibleSection> {
  bool isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Row(
          children: [
            MouseRegion(
              cursor: widget.onLableClick != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
              child: GestureDetector(
                onTap: widget.onLableClick,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(widget.label, style: theme.textTheme.titleLarge),
                    if (widget.onLableClick != null)
                      Icon(Icons.chevron_right, color: theme.textTheme.titleLarge!.color, size: 28),
                  ],
                ),
              ),
            ),

            Spacer(),

            IconButton(
              onPressed: () {
                setState(() {
                  isExpanded = !isExpanded;
                });
              },
              icon: Icon(
                isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                size: 28,
                // color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        if (isExpanded) SizedBox(height: 180, width: double.infinity, child: widget.content),
      ],
    );
  }
}
