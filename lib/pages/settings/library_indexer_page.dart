import 'dart:async';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nordplayer/database/app_database.dart';
import 'package:nordplayer/models/app_config.dart';
import 'package:nordplayer/routes/router.dart';
import 'package:nordplayer/services/background_task_service.dart';
import 'package:nordplayer/services/config_service.dart';
import 'package:nordplayer/services/duplicate_detector.dart';
import 'package:nordplayer/services/library_indexer.dart';
import 'package:nordplayer/widgets/app_icon.dart';
import 'package:nordplayer/widgets/nord_alert_dialog.dart';
import 'package:nordplayer/widgets/nord_snack_bar.dart';
import 'package:nordplayer/widgets/settings/section_card.dart';
import 'package:nordplayer/widgets/settings/section_divider.dart';
import 'package:nordplayer/widgets/settings/section_header.dart';
import 'package:nordplayer/widgets/settings/settings_chip.dart';

class LibraryIndexerPage extends ConsumerStatefulWidget {
  const LibraryIndexerPage({super.key});

  @override
  ConsumerState<LibraryIndexerPage> createState() => _LibraryIndexerPageState();
}

class _LibraryIndexerPageState extends ConsumerState<LibraryIndexerPage> {
  final TextEditingController _addDelimiterController = TextEditingController();
  final FocusNode _addDelimiterFocusNode = FocusNode();
  final TextEditingController _addExclusionController = TextEditingController();
  final FocusNode _addExclusionFocusNode = FocusNode();
  late final TapGestureRecognizer _delimitersTapRecognizer;
  late final TapGestureRecognizer _exclusionsTapRecognizer;

  bool _showDefaultExclusions = false;
  bool _isScanningDuplicates = false;
  List<DuplicateGroup>? _duplicateGroups;

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
    final tasks = ref.read(backgroundTaskServiceProvider);
    final isAnyRunning = tasks.any((t) => t.status == BackgroundTaskStatus.running);
    if (!isAnyRunning) {
      _triggerReindex();
    }
  }

  Future<void> _triggerScan() async {
    try {
      await ref.read(libraryIndexerProvider).scanLibrary();
    } catch (_) {}
  }

  Future<void> _triggerReindex() async {
    try {
      await ref.read(libraryIndexerProvider).reindexMetadata();
    } catch (_) {}
  }

  Future<void> _triggerFingerprint() async {
    try {
      await ref.read(libraryIndexerProvider).generateMissingFingerprints();
    } catch (_) {}
  }

  Future<void> _scanDuplicates() async {
    setState(() {
      _isScanningDuplicates = true;
    });
    try {
      final detector = ref.read(duplicateDetectorProvider);
      final groups = await detector.findDuplicates();
      setState(() {
        _duplicateGroups = groups;
      });
    } catch (e) {
      showNordSnackBar(message: 'Duplicate scan failed: $e', type: NordSnackBarType.error);
    } finally {
      setState(() {
        _isScanningDuplicates = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appConfig = ref.watch(configServiceProvider).requireValue;
    List<String> trackDirectories = appConfig.trackDirectories;
    List<String> currentDelimiters = appConfig.artistDelimiters;
    List<String> currentExclusions = appConfig.artistExclusions;

    final defaultSet = AppConfig.defaultArtistExclusions.map((e) => e.toLowerCase().trim()).toSet();
    final customExclusions = currentExclusions.where((e) => !defaultSet.contains(e.toLowerCase().trim())).toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    final activeDefaultExclusions = currentExclusions.where((e) => defaultSet.contains(e.toLowerCase().trim())).toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    final tasks = ref.watch(backgroundTaskServiceProvider);
    final isScanning = tasks.any((t) => t.id == 'library-scan' && t.status == BackgroundTaskStatus.running);
    final isReindexing = tasks.any((t) => t.id == 'metadata-reindex' && t.status == BackgroundTaskStatus.running);
    final isFingerprinting = tasks.any(
      (t) => t.id == 'fingerprint-generation' && t.status == BackgroundTaskStatus.running,
    );
    final isAnyRunning = isScanning || isReindexing || isFingerprinting || _isScanningDuplicates;

    return Scaffold(
      backgroundColor: appConfig.adaptiveBg ? Colors.transparent : theme.colorScheme.surface,
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SectionHeader(label: 'Library', labelType: LabelType.h1, padding: EdgeInsets.only(bottom: 8)),
          SectionCard(
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
                  value: appConfig.watchTrackDirectories,
                  onChanged: (val) {
                    ref.read(configServiceProvider.notifier).updateConfig(watchTrackDirectories: val);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          const SectionHeader(label: 'Multi-artist parsing', labelType: LabelType.h1),
          SectionCard(
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

          SectionCard(
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
                            return SettingsChip(label: exclusion, onDelete: () => _removeExclusion(exclusion));
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
                              return SettingsChip(label: exclusion, onDelete: () => _removeExclusion(exclusion));
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
          SectionCard(
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
                const SectionDivider(),
                ListTile(
                  title: const Text('Find Duplicate Tracks'),
                  subtitle: const Text("Scan your library using acoustic fingerprinting to find duplicate tracks."),
                  trailing: OutlinedButton.icon(
                    onPressed: isAnyRunning ? null : _scanDuplicates,
                    icon: _isScanningDuplicates
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2.0))
                        : const AppIcon(Icons.search),
                    label: Text(_isScanningDuplicates ? "Scanning..." : "Scan"),
                  ),
                ),
                if (_duplicateGroups != null) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _duplicateGroups!.isNotEmpty
                              ? '${_duplicateGroups!.length} duplicate group${_duplicateGroups!.length == 1 ? "" : "s"} found'
                              : 'No duplicates found',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: _duplicateGroups!.isNotEmpty ? FontWeight.w600 : FontWeight.normal,
                            color: _duplicateGroups!.isNotEmpty
                                ? theme.colorScheme.error
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (_duplicateGroups!.isNotEmpty)
                          TextButton(
                            onPressed: () {
                              context
                                  .push(
                                    '${Routes.libraryIndexerPage}/${Routes.duplicatesPage}',
                                    extra: _duplicateGroups!,
                                  )
                                  .then((_) {
                                    _scanDuplicates();
                                  });
                            },
                            style: TextButton.styleFrom(foregroundColor: theme.colorScheme.primary),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('Manage duplicates'),
                                SizedBox(width: 4),
                                AppIcon(Icons.chevron_right, size: 20),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
                const SectionDivider(),
                ListTile(
                  title: const Text('Reset Ignored Tracks'),
                  subtitle: const Text(
                    "Clear the list of duplicate files kept on disk but hidden from the library, allowing them to be scanned again.",
                  ),
                  trailing: OutlinedButton.icon(
                    onPressed: isAnyRunning ? null : _resetIgnoredTracks,
                    icon: const AppIcon(Icons.restore),
                    label: const Text("Reset"),
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
      final currentPaths = ref.read(configServiceProvider).requireValue.trackDirectories;
      final List<String> updatedPaths = List<String>.from(currentPaths);

      bool hasChanges = false;

      for (String? path in selectedPaths) {
        if (path != null && path.isNotEmpty && !updatedPaths.contains(path)) {
          updatedPaths.add(path);
          hasChanges = true;
        }
      }

      if (hasChanges) {
        ref.read(configServiceProvider.notifier).updateConfig(trackDirectories: updatedPaths);
        _triggerScan();
      }
    }
  }

  Future<void> _removeFolder(String path) async {
    List<String> updatedPaths = List<String>.from(ref.read(configServiceProvider).requireValue.trackDirectories);
    updatedPaths.remove(path);
    ref.read(configServiceProvider.notifier).updateConfig(trackDirectories: updatedPaths);

    await ref.read(libraryIndexerProvider).markTracksInDirectoryAsMissing(path);
  }

  void _addNewDelimiter() {
    final newDelimiter = _addDelimiterController.text.trim().toLowerCase();
    if (newDelimiter.isNotEmpty) {
      final currentDelimiters = ref.read(configServiceProvider).requireValue.artistDelimiters;
      if (!currentDelimiters.contains(newDelimiter)) {
        final updatedDelimiters = List<String>.from(currentDelimiters)..add(newDelimiter);
        ref.read(configServiceProvider.notifier).updateConfig(artistDelimiters: updatedDelimiters);
        _addDelimiterController.clear();
        _addDelimiterFocusNode.requestFocus();
      } else {
        showNordSnackBar(message: 'Delimiter "$newDelimiter" already exists.', type: .warning);
      }
    }
  }

  void _removeDelimiter(String delimiter) {
    final updatedDelimiters = List<String>.from(ref.read(configServiceProvider).requireValue.artistDelimiters);
    updatedDelimiters.remove(delimiter);
    ref.read(configServiceProvider.notifier).updateConfig(artistDelimiters: updatedDelimiters);
  }

  void _resetDelimitersToDefault() {
    ref.read(configServiceProvider.notifier).updateConfig(artistDelimiters: AppConfig.defaultArtistDelimiters);
  }

  void _addNewExclusion() {
    final newExclusion = _addExclusionController.text.trim();
    if (newExclusion.isNotEmpty) {
      final currentExclusions = ref.read(configServiceProvider).requireValue.artistExclusions;
      final alreadyExists = currentExclusions.any((e) => e.toLowerCase() == newExclusion.toLowerCase());
      if (!alreadyExists) {
        final updatedExclusions = List<String>.from(currentExclusions)..add(newExclusion);
        ref.read(configServiceProvider.notifier).updateConfig(artistExclusions: updatedExclusions);
        _addExclusionController.clear();
        _addExclusionFocusNode.requestFocus();
      } else {
        showNordSnackBar(message: 'Exclusion "$newExclusion" already exists.', type: .warning);
      }
    }
  }

  void _removeExclusion(String exclusion) {
    final updatedExclusions = List<String>.from(ref.read(configServiceProvider).requireValue.artistExclusions);
    updatedExclusions.remove(exclusion);
    ref.read(configServiceProvider.notifier).updateConfig(artistExclusions: updatedExclusions);
  }

  void _resetExclusionsToDefault() {
    ref.read(configServiceProvider.notifier).updateConfig(artistExclusions: AppConfig.defaultArtistExclusions);
  }

  Future<void> _resetIgnoredTracks() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return NordAlertDialog(
          title: 'Reset Ignored Tracks?',
          content: const Text(
            'This will clear the list of duplicate files that were kept on disk but hidden from the library, allowing them to be scanned and indexed again.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Reset')),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        final db = ref.read(appDatabaseProvider);
        await db.delete(db.ignoredPaths).go();
        showNordSnackBar(
          message: 'Ignored tracks reset successfully. Run scan to re-index them.',
          type: NordSnackBarType.success,
        );
      } catch (e) {
        showNordSnackBar(message: 'Failed to reset: $e', type: NordSnackBarType.error);
      }
    }
  }
}
