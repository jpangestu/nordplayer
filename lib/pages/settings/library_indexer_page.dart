import 'dart:async';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nordplayer/models/app_config.dart';
import 'package:nordplayer/services/config_service.dart';
import 'package:nordplayer/services/library_indexer.dart';
import 'package:nordplayer/widgets/app_icon.dart';
import 'package:nordplayer/widgets/frosted_glass.dart';
import 'package:nordplayer/widgets/nord_snack_bar.dart';
import 'package:nordplayer/widgets/settings/section_card.dart';
import 'package:nordplayer/widgets/settings/section_divider.dart';
import 'package:nordplayer/widgets/settings/section_header.dart';

class LibraryIndexerPage extends ConsumerStatefulWidget {
  const LibraryIndexerPage({super.key});

  @override
  ConsumerState<LibraryIndexerPage> createState() => _LibraryIndexerPageState();
}

class _LibraryIndexerPageState extends ConsumerState<LibraryIndexerPage> {
  final TextEditingController _addDelimiterController = TextEditingController();
  final FocusNode _addDelimiterFocusNode = FocusNode();

  bool _isScanning = false;
  bool _isReindexing = false;
  int _scanProcessed = 0;
  int _scanTotal = 0;
  int _reindexProcessed = 0;
  int _reindexTotal = 0;

  bool get _isBusy => _isScanning || _isReindexing;

  @override
  void dispose() {
    _addDelimiterController.dispose();
    _addDelimiterFocusNode.dispose();
    super.dispose();
  }

  Future<void> _triggerScan() async {
    setState(() {
      _isScanning = true;
      _scanProcessed = 0;
      _scanTotal = 0;
    });

    try {
      await ref
          .read(libraryIndexerProvider)
          .scanLibrary(
            onProgress: (processed, total) {
              if (mounted) {
                setState(() {
                  _scanProcessed = processed;
                  _scanTotal = total;
                });
              }
            },
          );

      if (mounted) {
        showNordSnackBar(message: 'Library scan complete', type: .success);
      }
    } catch (e) {
      if (mounted) {
        showNordSnackBar(message: 'Unable to scan library: $e', type: .error);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
      }
    }
  }

  Future<void> _triggerReindex() async {
    setState(() {
      _isReindexing = true;
      _reindexProcessed = 0;
      _reindexTotal = 0;
    });

    try {
      await ref
          .read(libraryIndexerProvider)
          .reindexMetadata(
            onProgress: (processed, total) {
              if (mounted) {
                setState(() {
                  _reindexProcessed = processed;
                  _reindexTotal = total;
                });
              }
            },
          );

      if (mounted) {
        showNordSnackBar(message: 'Library re-indexed successfully', type: .success);
      }
    } catch (e) {
      if (mounted) {
        showNordSnackBar(message: 'Unable to re-index metadata: $e', type: .error);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isReindexing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appConfig = ref.watch(configServiceProvider).requireValue;
    List<String> trackDirectories = appConfig.trackDirectories;
    List<String> currentDelimiters = appConfig.artistDelimiters;

    return Scaffold(
      backgroundColor: appConfig.adaptiveBg ? Colors.transparent : theme.colorScheme.surface,
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SectionHeader(label: 'Library', labelType: .h1, padding: .only(bottom: 8)),
          SectionCard(
            child: Column(
              children: [
                ListTile(
                  title: const Text('Music locations'),
                  subtitle: const Text("Manage folders to scan for music"),
                  trailing: OutlinedButton.icon(
                    onPressed: _isBusy ? null : () => _addFolder(),
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
                        onPressed: _isBusy ? null : () => _removeFolder(path),
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
                  onChanged: _isBusy
                      ? null
                      : (val) {
                          ref.read(configServiceProvider.notifier).updateConfig(watchTrackDirectories: val);
                        },
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          const SectionHeader(label: 'Multi-artist parsing', labelType: .h1),
          SectionCard(
            child: Column(
              children: [
                Padding(
                  padding: const .only(left: 16, right: 16, top: 8, bottom: 16),
                  child: Column(
                    crossAxisAlignment: .start,
                    children: [
                      Text('Current Delimiters', style: theme.textTheme.titleMedium),
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
                                      ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
                                      : theme.colorScheme.surfaceContainerHighest,
                                  blurSigma: isAdaptive ? 8.0 : 0.0,
                                  child: Container(
                                    height: 32, // Matches VisualDensity.compact
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8.0),
                                      border: Border.all(
                                        color: theme.colorScheme.outline.withValues(alpha: isAdaptive ? 0.3 : 0.8),
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
                                          Text('"$delimiter"', style: theme.textTheme.labelLarge),

                                          // Only show the delete button if there's more than 1 delimiter
                                          if (currentDelimiters.length > 1) ...[
                                            const SizedBox(width: 4),
                                            InkWell(
                                              borderRadius: BorderRadius.circular(50),
                                              onTap: _isBusy ? null : () => _removeDelimiter(delimiter),
                                              child: Padding(
                                                padding: const EdgeInsets.all(4.0),
                                                child: AppIcon(
                                                  Icons.close,
                                                  size: 16,
                                                  color: theme.colorScheme.onSurfaceVariant,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                          ] else ...[
                                            const SizedBox(width: 10), // Padding when no icon is present
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          const Spacer(flex: 1),
                          SizedBox(
                            child: OutlinedButton.icon(
                              onPressed: _isBusy ? null : _resetDelimitersToDefault,
                              icon: const AppIcon(Icons.restore),
                              label: const Text('Reset to Defaults'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SectionDivider(),
                const SizedBox(height: 8),

                Padding(
                  padding: const .only(left: 16, right: 16, top: 8, bottom: 16),
                  child: Column(
                    crossAxisAlignment: .start,
                    children: [
                      Text('Add New Delimiter', style: theme.textTheme.titleMedium),
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
                              enabled: !_isBusy,
                              decoration: const InputDecoration(
                                hintText: 'e.g., / or ;',
                                border: OutlineInputBorder(),
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                              ),
                              onSubmitted: _isBusy ? null : (_) => _addNewDelimiter(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton(
                            onPressed: _isBusy ? null : _addNewDelimiter,
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
                            child: Text(
                              'To apply delimiter changes to existing tracks, run Re-index Metadata below.',
                              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
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

          const SectionHeader(label: 'Library maintenance', labelType: .h1),
          SectionCard(
            child: Column(
              children: [
                ListTile(
                  title: const Text('Scan for new files'),
                  subtitle: const Text("Scan your music locations for new, moved, or deleted audio files."),
                  trailing: _isScanning
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5))
                      : OutlinedButton.icon(
                          onPressed: _isBusy ? null : _triggerScan,
                          icon: const AppIcon(Icons.search),
                          label: const Text("Scan"),
                        ),
                ),
                if (_isScanning) ...[
                  const SectionDivider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LinearProgressIndicator(value: _scanTotal > 0 ? _scanProcessed / _scanTotal : null),
                        const SizedBox(height: 8),
                        Text(
                          _scanTotal > 0
                              ? 'Processing track $_scanProcessed of $_scanTotal...'
                              : 'Scanning folders for audio files...',
                          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
                const SectionDivider(),
                ListTile(
                  title: const Text('Re-index Metadata'),
                  subtitle: const Text(
                    "Re-scan files to apply new delimiters, refresh tag edits, and reload missing album art.",
                  ),
                  trailing: _isReindexing
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5))
                      : OutlinedButton.icon(
                          onPressed: _isBusy ? null : _triggerReindex,
                          icon: const AppIcon(Icons.sync),
                          label: const Text("Re-index"),
                        ),
                ),
                if (_isReindexing) ...[
                  const SectionDivider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LinearProgressIndicator(value: _reindexTotal > 0 ? _reindexProcessed / _reindexTotal : 0.0),
                        const SizedBox(height: 8),
                        Text(
                          'Re-indexing track $_reindexProcessed of $_reindexTotal...',
                          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
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

        if (mounted) {
          setState(() {
            _isScanning = true;
            _scanProcessed = 0;
            _scanTotal = 0;
          });
        }

        try {
          await ref
              .read(libraryIndexerProvider)
              .scanLibrary(
                onProgress: (processed, total) {
                  if (mounted) {
                    setState(() {
                      _scanProcessed = processed;
                      _scanTotal = total;
                    });
                  }
                },
              );
        } catch (e) {
          if (mounted) {
            showNordSnackBar(message: 'Unable to scan library: $e', type: .error);
          }
        } finally {
          if (mounted) {
            setState(() {
              _isScanning = false;
            });
          }
        }
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Delimiter "$newDelimiter" already exists.')));
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
}
