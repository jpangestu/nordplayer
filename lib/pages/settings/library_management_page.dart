import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nordplayer/models/app_config.dart';
import 'package:nordplayer/services/config_service.dart';
import 'package:file_selector/file_selector.dart';

import 'package:nordplayer/widgets/section_header.dart';

class LibraryManagementPage extends StatefulWidget {
  const LibraryManagementPage({super.key});

  @override
  State<LibraryManagementPage> createState() => _LibraryManagementPageState();
}

class _LibraryManagementPageState extends State<LibraryManagementPage> {
  // Controller for the "Add New Delimiter" input field
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

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: ListenableBuilder(
              listenable: ConfigService(),
              builder: (context, _) {
                AppConfig appConfig = ConfigService().appConfig;
                List<String> musicPaths = appConfig.musicPaths;
                List<String> currentDelimiters = appConfig.artistDelimiters;

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const SectionHeader(label: 'Music folders', labelType: .h1),
                    ListTile(
                      title: const Text('Music locations'),
                      subtitle: const Text("Manage folders to scan for music"),
                      trailing: FilledButton.icon(
                        onPressed: () => _addFolder(),
                        icon: const Icon(Icons.add),
                        label: const Text("Add Folders"),
                      ),
                    ),

                    if (musicPaths.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8,
                        ),
                        child: Text(
                          "No folders added yet",
                          style: TextStyle(color: theme.disabledColor),
                        ),
                      )
                    else
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

                    const SizedBox(height: 8),
                    const Divider(),

                    const SectionHeader(label: 'Metadata', labelType: .h1),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Current Delimiters Section
                          SectionHeader(
                            label: 'Multi-artist parsing',
                            labelType: .h2,
                          ),
                          Text(
                            'Current Delimiters',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: currentDelimiters.map((delimiter) {
                                    return InputChip(
                                      label: Text('"$delimiter"'),
                                      onDeleted: currentDelimiters.length > 1
                                          ? () => _removeDelimiter(delimiter)
                                          : null,
                                      deleteIcon: const Icon(
                                        Icons.close,
                                        size: 18,
                                      ),
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      visualDensity: VisualDensity.compact,
                                    );
                                  }).toList(),
                                ),
                              ),
                              Spacer(),
                              OutlinedButton.icon(
                                onPressed: _resetDelimitersToDefault,
                                icon: const Icon(Icons.restore),
                                label: const Text('Reset to Defaults'),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Add New Delimiter Section
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
                              FilledButton(
                                onPressed: _addNewDelimiter,
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.all(14),
                                  shape: const CircleBorder(),
                                ),
                                child: const Icon(Icons.add),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Divider(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addFolder() async {
    // getDirectoryPaths inherently supports selecting multiple folders
    final selectedPaths = await getDirectoryPaths();

    if (selectedPaths.isNotEmpty) {
      final currentPaths = ConfigService().appConfig.musicPaths;
      final List<String> updatedPaths = List<String>.from(currentPaths);

      bool hasChanges = false;

      for (String? path in selectedPaths) {
        if (path != null && path.isNotEmpty && !updatedPaths.contains(path)) {
          updatedPaths.add(path);
          hasChanges = true;
        }
      }

      if (hasChanges) {
        ConfigService().update(musicPaths: updatedPaths);
      }
    }
  }

  void _removeFolder(String path) {
    List<String> updatedPaths = List<String>.from(
      ConfigService().appConfig.musicPaths,
    );
    updatedPaths.remove(path);
    ConfigService().update(musicPaths: updatedPaths);
  }

  void _addNewDelimiter() {
    final newDelimiter = _addDelimiterController.text.trim().toLowerCase();
    if (newDelimiter.isNotEmpty) {
      final currentDelimiters = ConfigService().appConfig.artistDelimiters;
      if (!currentDelimiters.contains(newDelimiter)) {
        final updatedDelimiters = List<String>.from(currentDelimiters)
          ..add(newDelimiter);
        ConfigService().update(artistDelimiters: updatedDelimiters);
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
      ConfigService().appConfig.artistDelimiters,
    );
    updatedDelimiters.remove(delimiter);
    ConfigService().update(artistDelimiters: updatedDelimiters);
  }

  void _resetDelimitersToDefault() {
    ConfigService().update(artistDelimiters: AppConfig.defaultArtistDelimiters);
  }
}
