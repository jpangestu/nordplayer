import 'dart:async';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nordplayer/ui/settings/library_indexer/library_indexer_viewmodel.dart';
import 'package:nordplayer/routing/router.dart';
import 'package:nordplayer/ui/shared/ui/app_icon.dart';
import 'package:nordplayer/ui/shared/ui/nord_snack_bar.dart';
import 'package:nordplayer/ui/shared/ui/sections/section_container.dart';
import 'package:nordplayer/ui/shared/ui/sections/section_divider.dart';
import 'package:nordplayer/ui/shared/ui/sections/section_header.dart';
import 'package:nordplayer/ui/settings/widgets/section_navigation.dart';
import 'package:nordplayer/ui/settings/widgets/settings_chip.dart';

class LibraryIndexerView extends ConsumerStatefulWidget {
  const LibraryIndexerView({super.key});

  @override
  ConsumerState<LibraryIndexerView> createState() => _LibraryIndexerViewState();
}

class _LibraryIndexerViewState extends ConsumerState<LibraryIndexerView> {
  final TextEditingController _addDelimiterController = TextEditingController();
  final FocusNode _addDelimiterFocusNode = FocusNode();
  final TextEditingController _addExclusionController = TextEditingController();
  final FocusNode _addExclusionFocusNode = FocusNode();
  late final TapGestureRecognizer _delimitersTapRecognizer;
  late final TapGestureRecognizer _exclusionsTapRecognizer;

  bool _showDefaultExclusions = false;

  @override
  void initState() {
    super.initState();
    _delimitersTapRecognizer = TapGestureRecognizer()..onTap = _handleLinkReindex;
    _exclusionsTapRecognizer = TapGestureRecognizer()..onTap = _handleLinkReindex;
  }

  @override
  void dispose() {
    _addDelimiterController.dispose();
    _addDelimiterFocusNode.dispose();
    _addExclusionController.dispose();
    _addExclusionFocusNode.dispose();
    _delimitersTapRecognizer.dispose();
    _exclusionsTapRecognizer.dispose();
    super.dispose();
  }

  void _handleLinkReindex() {
    ref.read(libraryIndexerViewModelProvider.notifier).triggerReindex();
  }

  void _triggerScan() {
    ref.read(libraryIndexerViewModelProvider.notifier).triggerScan();
  }

  void _triggerReindex() {
    ref.read(libraryIndexerViewModelProvider.notifier).triggerReindex();
  }

  void _triggerFingerprint() {
    ref.read(libraryIndexerViewModelProvider.notifier).triggerFingerprint();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final uiState = ref.watch(libraryIndexerViewModelProvider);
    final trackDirectories = uiState.trackDirectories;
    final currentDelimiters = uiState.artistDelimiters;
    final customExclusions = uiState.customExclusions;
    final activeDefaultExclusions = uiState.activeDefaultExclusions;
    final isScanning = uiState.isScanning;
    final isReindexing = uiState.isReindexing;
    final isFingerprinting = uiState.isFingerprinting;
    final isAnyRunning = uiState.isAnyTaskRunning;

    return Scaffold(
      backgroundColor: uiState.adaptiveBg ? Colors.transparent : theme.colorScheme.surface,
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SectionHeader(label: 'Library', labelType: LabelType.h1, padding: EdgeInsets.only(bottom: 8)),
          SectionContainer(
            child: Column(
              children: [
                ListTile(
                  title: const Text('Music locations'),
                  subtitle: const Text("Manage folders to scan for music"),
                  trailing: OutlinedButton.icon(
                    onPressed: () => _addFolder(),
                    icon: const AppIcon(Icons.add),
                    label: const Text("Add Folders"),
                  ),
                ),
                if (trackDirectories.isEmpty) ...[
                  const SectionDivider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                    child: Text("No folders added yet", style: TextStyle(color: theme.disabledColor)),
                  ),
                ] else ...[
                  const SectionDivider(),
                  ...trackDirectories.map(
                    (path) => ListTile(
                      leading: const AppIcon(Icons.folder_outlined),
                      title: Text(path),
                      trailing: IconButton(
                        onPressed: () => _removeFolder(path),
                        icon: const AppIcon(Icons.delete_outline),
                        tooltip: "Remove folder",
                      ),
                      dense: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                const SectionDivider(),
                SwitchListTile(
                  title: Text('Watch folders for changes', style: theme.textTheme.bodyLarge),
                  subtitle: const Text('Automatically detect new, moved, or deleted music files in your locations.'),
                  value: uiState.watchTrackDirectories,
                  onChanged: (val) {
                    ref.read(libraryIndexerViewModelProvider.notifier).toggleWatchFolders(val);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          const SectionHeader(label: 'Multi-artist parsing', labelType: LabelType.h1),
          SectionContainer(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Artist Delimiters', style: theme.textTheme.titleMedium),
                                const SizedBox(height: 4),
                                Text(
                                  'Delimiters are used to split collaborative artist names and identify collaborative release albums.',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: _resetDelimitersToDefault,
                            icon: const AppIcon(Icons.restore),
                            label: const Text('Reset to Defaults'),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: currentDelimiters.map((delimiter) {
                          return SettingsChip(
                            label: delimiter,
                            isAdaptive: uiState.adaptiveBg,
                            onDelete: (currentDelimiters.length > 1) ? () => _removeDelimiter(delimiter) : null,
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),

                const SectionDivider(),
                const SizedBox(height: 8),

                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Add New Delimiter', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _addDelimiterController,
                              focusNode: _addDelimiterFocusNode,
                              decoration: const InputDecoration(
                                hintText: 'Example: / or ; (case insensitive)',
                                border: OutlineInputBorder(),
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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
                            child: const AppIcon(Icons.add),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          AppIcon(Icons.info_outline, size: 16, color: theme.colorScheme.onSurfaceVariant),
                          const SizedBox(width: 8),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                                children: [
                                  const TextSpan(text: 'To apply changes to already indexed tracks, run '),
                                  TextSpan(
                                    text: 'Re-index Metadata',
                                    style: TextStyle(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                      decoration: TextDecoration.underline,
                                    ),
                                    recognizer: _delimitersTapRecognizer,
                                    mouseCursor: SystemMouseCursors.click,
                                  ),
                                  const TextSpan(text: '.'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          SectionContainer(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Artist Exclusions', style: theme.textTheme.titleMedium),
                                const SizedBox(height: 4),
                                Text(
                                  'Exclusions prevent splitting collaborative artist names containing active delimiters.',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: _resetExclusionsToDefault,
                            icon: const AppIcon(Icons.restore),
                            label: const Text('Reset to Defaults'),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      if (customExclusions.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text('No custom exclusions configured.', style: TextStyle(color: theme.disabledColor)),
                        )
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: customExclusions.map((exclusion) {
                            return SettingsChip(
                              label: exclusion,
                              isAdaptive: uiState.adaptiveBg,
                              onDelete: () => _removeExclusion(exclusion),
                            );
                          }).toList(),
                        ),

                      const SizedBox(height: 16),

                      Row(
                        children: [
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _showDefaultExclusions = !_showDefaultExclusions;
                              });
                            },
                            icon: Icon(_showDefaultExclusions ? Icons.expand_less : Icons.expand_more),
                            label: Text(
                              _showDefaultExclusions
                                  ? 'Hide Default Exclusions'
                                  : 'Show Default Exclusions (${activeDefaultExclusions.length} active)',
                            ),
                          ),
                        ],
                      ),
                      if (_showDefaultExclusions) ...[
                        const SizedBox(height: 8),
                        if (activeDefaultExclusions.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              'All default exclusions have been removed.',
                              style: TextStyle(color: theme.disabledColor),
                            ),
                          )
                        else
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: activeDefaultExclusions.map((exclusion) {
                              return SettingsChip(
                                label: exclusion,
                                isAdaptive: uiState.adaptiveBg,
                                onDelete: () => _removeExclusion(exclusion),
                              );
                            }).toList(),
                          ),
                      ],
                    ],
                  ),
                ),

                const SectionDivider(),
                const SizedBox(height: 8),

                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Add New Exclusion', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _addExclusionController,
                              focusNode: _addExclusionFocusNode,
                              decoration: const InputDecoration(
                                hintText: 'Example: Earth, Wind & Fire (case insensitive)',
                                border: OutlineInputBorder(),
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                              ),
                              onSubmitted: (_) => _addNewExclusion(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton(
                            onPressed: _addNewExclusion,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.all(14),
                              shape: const CircleBorder(),
                            ),
                            child: const AppIcon(Icons.add),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          AppIcon(Icons.info_outline, size: 16, color: theme.colorScheme.onSurfaceVariant),
                          const SizedBox(width: 8),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                                children: [
                                  const TextSpan(text: 'To apply changes to already indexed tracks, run '),
                                  TextSpan(
                                    text: 'Re-index Metadata',
                                    style: TextStyle(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                      decoration: TextDecoration.underline,
                                    ),
                                    recognizer: _exclusionsTapRecognizer,
                                    mouseCursor: SystemMouseCursors.click,
                                  ),
                                  const TextSpan(text: '.'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          const SectionHeader(label: 'Library maintenance', labelType: LabelType.h1),
          SectionContainer(
            child: Column(
              children: [
                ListTile(
                  title: const Text('Scan for new files'),
                  subtitle: const Text("Scan your music locations for new, moved, or deleted audio files."),
                  trailing: OutlinedButton.icon(
                    onPressed: isAnyRunning ? null : _triggerScan,
                    icon: isScanning
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2.0))
                        : const AppIcon(Icons.search),
                    label: Text(isScanning ? "Scanning..." : "Scan"),
                  ),
                ),
                const SectionDivider(),
                ListTile(
                  title: const Text('Re-index Metadata'),
                  subtitle: const Text(
                    "Re-scan files to apply new delimiters, refresh tag edits, and reload missing album art.",
                  ),
                  trailing: OutlinedButton.icon(
                    onPressed: isAnyRunning ? null : _triggerReindex,
                    icon: isReindexing
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2.0))
                        : const AppIcon(Icons.sync),
                    label: Text(isReindexing ? "Re-indexing..." : "Re-index"),
                  ),
                ),
                const SectionDivider(),
                ListTile(
                  title: const Text('Generate Audio Fingerprints'),
                  subtitle: const Text(
                    "Analyze audio content to generate missing AcoustID Chromaprints for track matching.",
                  ),
                  trailing: OutlinedButton.icon(
                    onPressed: isAnyRunning ? null : _triggerFingerprint,
                    icon: isFingerprinting
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2.0))
                        : const AppIcon(Icons.fingerprint),
                    label: Text(isFingerprinting ? "Generating..." : "Generate"),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          SectionContainer(
            child: SectionNavigation(
              title: 'Manage Duplicates',
              onClick: () {
                context.go('${Routes.libraryIndexerPage}/${Routes.duplicatesPage}');
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addFolder() async {
    final selectedPaths = await getDirectoryPaths();
    if (selectedPaths.isNotEmpty) {
      final validPaths = selectedPaths.whereType<String>().where((p) => p.isNotEmpty).toList();
      await ref.read(libraryIndexerViewModelProvider.notifier).addFolders(validPaths);
    }
  }

  Future<void> _removeFolder(String path) async {
    await ref.read(libraryIndexerViewModelProvider.notifier).removeFolder(path);
  }

  void _addNewDelimiter() {
    final newDelimiter = _addDelimiterController.text.trim().toLowerCase();
    if (newDelimiter.isNotEmpty) {
      final added = ref.read(libraryIndexerViewModelProvider.notifier).addDelimiter(newDelimiter);
      if (added) {
        _addDelimiterController.clear();
        _addDelimiterFocusNode.requestFocus();
      } else {
        showNordSnackBar(message: 'Delimiter "$newDelimiter" already exists.', type: .warning);
      }
    }
  }

  void _removeDelimiter(String delimiter) {
    ref.read(libraryIndexerViewModelProvider.notifier).removeDelimiter(delimiter);
  }

  void _resetDelimitersToDefault() {
    ref.read(libraryIndexerViewModelProvider.notifier).resetDelimitersToDefault();
  }

  void _addNewExclusion() {
    final newExclusion = _addExclusionController.text.trim();
    if (newExclusion.isNotEmpty) {
      final added = ref.read(libraryIndexerViewModelProvider.notifier).addExclusion(newExclusion);
      if (added) {
        _addExclusionController.clear();
        _addExclusionFocusNode.requestFocus();
      } else {
        showNordSnackBar(message: 'Exclusion "$newExclusion" already exists.', type: .warning);
      }
    }
  }

  void _removeExclusion(String exclusion) {
    ref.read(libraryIndexerViewModelProvider.notifier).removeExclusion(exclusion);
  }

  void _resetExclusionsToDefault() {
    ref.read(libraryIndexerViewModelProvider.notifier).resetExclusionsToDefault();
  }
}
