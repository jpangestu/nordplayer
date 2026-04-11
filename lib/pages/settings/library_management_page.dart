import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nordplayer/models/app_config.dart';
import 'package:nordplayer/services/config_service.dart';
import 'package:file_selector/file_selector.dart';
import 'package:nordplayer/services/library_scanner.dart';
import 'package:nordplayer/services/library_watcher.dart';
import 'package:nordplayer/widgets/frosted_glass.dart';

import 'package:nordplayer/widgets/settings/section_header.dart';
import 'package:nordplayer/widgets/settings/section_divider.dart';
import 'package:nordplayer/widgets/settings/section_card.dart';

class LibraryManagementPage extends ConsumerStatefulWidget {
  const LibraryManagementPage({super.key});

  @override
  ConsumerState<LibraryManagementPage> createState() =>
      _LibraryManagementPageState();
}

class _LibraryManagementPageState extends ConsumerState<LibraryManagementPage> {
  final TextEditingController _addDelimiterController = TextEditingController();
  final FocusNode _addDelimiterFocusNode = FocusNode();

  @override
  void dispose() {
    _addDelimiterController.dispose();
    _addDelimiterFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appConfig = ref.watch(configServiceProvider).requireValue;
    List<String> musicPaths = appConfig.musicPaths;
    List<String> currentDelimiters = appConfig.artistDelimiters;

    return Scaffold(
      backgroundColor: appConfig.adaptiveBg
          ? Colors.transparent
          : theme.colorScheme.surface,
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SectionHeader(
            label: 'Library',
            labelType: .h1,
            padding: .only(bottom: 8),
          ),
          SectionCard(
            child: Column(
              children: [
                ListTile(
                  title: const Text('Music locations'),
                  subtitle: const Text("Manage folders to scan for music"),
                  trailing: OutlinedButton.icon(
                    onPressed: () => _addFolder(),
                    icon: const Icon(Icons.add),
                    label: const Text("Add Folders"),
                  ),
                ),
                if (musicPaths.isEmpty) ...[
                  SectionDivider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8,
                    ),
                    child: Text(
                      "No folders added yet",
                      style: TextStyle(color: theme.disabledColor),
                    ),
                  ),
                ] else ...[
                  SectionDivider(),
                  ...musicPaths.map(
                    (path) => ListTile(
                      leading: const Icon(Icons.folder_outlined),
                      title: Text(path),
                      trailing: IconButton(
                        onPressed: () => _removeFolder(path),
                        icon: const Icon(Icons.delete_outline),
                        tooltip: "Remove folder",
                      ),
                      dense: true,
                    ),
                  ),
                  SizedBox(height: 8),
                ],
              ],
            ),
          ),

          const SizedBox(height: 8),

          const SectionHeader(label: 'Multi-artist parsing', labelType: .h1),
          SectionCard(
            child: Column(
              children: [
                Padding(
                  padding: .only(left: 16, right: 16, top: 8, bottom: 16),
                  child: Column(
                    crossAxisAlignment: .start,
                    children: [
                      Text(
                        'Current Delimiters',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            flex: 9,
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: currentDelimiters.map((delimiter) {
                                final isAdaptive = appConfig.adaptiveBg;

                                // Not use flutter input chip because for some reason
                                // it can't set to be translucent
                                return FrostedGlass(
                                  borderRadius: 8.0,
                                  backgroundColor: isAdaptive
                                      ? theme
                                            .colorScheme
                                            .surfaceContainerHighest
                                            .withValues(alpha: 0.3)
                                      : theme
                                            .colorScheme
                                            .surfaceContainerHighest,
                                  blurSigma: isAdaptive ? 8.0 : 0.0,
                                  child: Container(
                                    height: 32, // Matches VisualDensity.compact
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8.0),
                                      border: Border.all(
                                        color: theme.colorScheme.outline
                                            .withValues(
                                              alpha: isAdaptive ? 0.3 : 0.8,
                                            ),
                                        width: 1,
                                      ),
                                    ),
                                    // MaterialType.transparency keeps the background invisible
                                    // but allows the InkWell splash effect to still work!
                                    child: Material(
                                      type: MaterialType.transparency,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const SizedBox(width: 10),
                                          Text(
                                            '"$delimiter"',
                                            style: theme.textTheme.labelLarge,
                                          ),

                                          // Only show the delete button if there's more than 1 delimiter
                                          if (currentDelimiters.length > 1) ...[
                                            const SizedBox(width: 4),
                                            InkWell(
                                              borderRadius:
                                                  BorderRadius.circular(50),
                                              onTap: () =>
                                                  _removeDelimiter(delimiter),
                                              child: Padding(
                                                padding: const EdgeInsets.all(
                                                  4.0,
                                                ),
                                                child: Icon(
                                                  Icons.close,
                                                  size: 16,
                                                  color: theme
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                          ] else ...[
                                            const SizedBox(
                                              width: 10,
                                            ), // Padding when no icon is present
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          Spacer(flex: 1),
                          SizedBox(
                            child: OutlinedButton.icon(
                              onPressed: _resetDelimitersToDefault,
                              icon: const Icon(Icons.restore),
                              label: const Text('Reset to Defaults'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                SectionDivider(),
                SizedBox(height: 8),

                Padding(
                  padding: .only(left: 16, right: 16, top: 8, bottom: 16),
                  child: Column(
                    crossAxisAlignment: .start,
                    children: [
                      Text(
                        'Add New Delimiter',
                        style: theme.textTheme.titleMedium,
                      ),
                      Text(
                        'Case insensitive ("Feat." and "feat." are considered the same)',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _addDelimiterController,
                              focusNode: _addDelimiterFocusNode,
                              decoration: const InputDecoration(
                                hintText: 'e.g., / or ;',
                                border: OutlineInputBorder(),
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 14,
                                ),
                              ),
                              onSubmitted: (_) => _addNewDelimiter(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton(
                            onPressed: _addNewDelimiter,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.all(14),
                              shape: const CircleBorder(),
                            ),
                            child: const Icon(Icons.add),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addFolder() async {
    final selectedPaths = await getDirectoryPaths();

    if (selectedPaths.isNotEmpty) {
      final currentPaths = ref
          .read(configServiceProvider)
          .requireValue
          .musicPaths;
      final List<String> updatedPaths = List<String>.from(currentPaths);

      bool hasChanges = false;

      for (String? path in selectedPaths) {
        if (path != null && path.isNotEmpty && !updatedPaths.contains(path)) {
          updatedPaths.add(path);
          hasChanges = true;
        }
      }

      if (hasChanges) {
        ref
            .read(configServiceProvider.notifier)
            .updateConfig(musicPaths: updatedPaths);

        for (var path in updatedPaths) {
          ref.read(libraryWatcherProvider).watchFolder(path);
        }

        await ref.read(libraryScannerProvider).scanLibrary();
      }
    }
  }

  Future<void> _removeFolder(String path) async {
    List<String> updatedPaths = List<String>.from(
      ref.read(configServiceProvider).requireValue.musicPaths,
    );
    updatedPaths.remove(path);
    ref
        .read(configServiceProvider.notifier)
        .updateConfig(musicPaths: updatedPaths);

    ref.read(libraryWatcherProvider).stopWatchingFolder(path);

    await ref.read(libraryScannerProvider).removeTracksInDirectory(path);
  }

  void _addNewDelimiter() {
    final newDelimiter = _addDelimiterController.text.trim().toLowerCase();
    if (newDelimiter.isNotEmpty) {
      final currentDelimiters = ref
          .read(configServiceProvider)
          .requireValue
          .artistDelimiters;
      if (!currentDelimiters.contains(newDelimiter)) {
        final updatedDelimiters = List<String>.from(currentDelimiters)
          ..add(newDelimiter);
        ref
            .read(configServiceProvider.notifier)
            .updateConfig(artistDelimiters: updatedDelimiters);
        _addDelimiterController.clear();
        _addDelimiterFocusNode.requestFocus();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delimiter "$newDelimiter" already exists.')),
        );
      }
    }
  }

  void _removeDelimiter(String delimiter) {
    final updatedDelimiters = List<String>.from(
      ref.read(configServiceProvider).requireValue.artistDelimiters,
    );
    updatedDelimiters.remove(delimiter);
    ref
        .read(configServiceProvider.notifier)
        .updateConfig(artistDelimiters: updatedDelimiters);
  }

  void _resetDelimitersToDefault() {
    ref
        .read(configServiceProvider.notifier)
        .updateConfig(artistDelimiters: AppConfig.defaultArtistDelimiters);
  }
}
