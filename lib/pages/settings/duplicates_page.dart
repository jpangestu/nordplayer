import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nordplayer/database/app_database.dart';
import 'package:nordplayer/services/config_service.dart';
import 'package:nordplayer/services/duplicate_detector.dart';
import 'package:nordplayer/theming/icon-sets/app_icon_set.dart';
import 'package:nordplayer/utils/int_extension.dart';
import 'package:nordplayer/widgets/app_icon.dart';
import 'package:nordplayer/widgets/nord_alert_dialog.dart';
import 'package:nordplayer/widgets/nord_snack_bar.dart';
import 'package:nordplayer/widgets/settings/section_card.dart';
import 'package:nordplayer/widgets/settings/section_divider.dart';
import 'package:path/path.dart' as p;

// TODO: make a proper duplicate page
class DuplicatesPage extends ConsumerStatefulWidget {
  final List<DuplicateGroup> initialGroups;
  const DuplicatesPage({super.key, required this.initialGroups});

  @override
  ConsumerState<DuplicatesPage> createState() => _DuplicatesPageState();
}

class _DuplicatesPageState extends ConsumerState<DuplicatesPage> {
  bool _isScanning = false;
  List<DuplicateGroup>? _groups;
  String? _errorMessage;
  final Set<String> _collapsedArtists = {};

  @override
  void initState() {
    super.initState();
    _groups = widget.initialGroups;
  }

  Future<void> _runScan() async {
    setState(() {
      _isScanning = true;
      _errorMessage = null;
      _collapsedArtists.clear();
    });

    try {
      final detector = ref.read(duplicateDetectorProvider);
      final groups = await detector.findDuplicates();
      setState(() {
        _groups = groups;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
      showNordSnackBar(message: 'Scan failed: $e', type: NordSnackBarType.error);
    } finally {
      setState(() {
        _isScanning = false;
      });
    }
  }

  void _toggleArtistExpanded(String artist) {
    setState(() {
      if (_collapsedArtists.contains(artist)) {
        _collapsedArtists.remove(artist);
      } else {
        _collapsedArtists.add(artist);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appConfig = ref.watch(configServiceProvider).requireValue;
    final detector = ref.watch(duplicateDetectorProvider);

    Widget content;

    if (_isScanning && _groups == null) {
      content = const Center(child: CircularProgressIndicator());
    } else if (_errorMessage != null) {
      content = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppIcon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text('Scan Error', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(onPressed: _runScan, icon: const AppIcon(Icons.refresh), label: const Text('Try Again')),
          ],
        ),
      );
    } else if (_groups == null || _groups!.isEmpty) {
      // Auto-pop if there are no duplicates to manage
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.canPop()) {
          context.pop();
        }
      });
      content = const Center(child: CircularProgressIndicator());
    } else {
      // Group duplicates by artist
      final Map<String, List<DuplicateGroup>> artistGroups = {};
      for (final group in _groups!) {
        final artist = group.artist.trim().isEmpty ? 'Unknown Artist' : group.artist;
        artistGroups.putIfAbsent(artist, () => []).add(group);
      }

      final sortedArtists = artistGroups.keys.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

      final appIconSet = ref.watch(appIconProvider);

      content = ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Row(
            children: [
              OutlinedButton.icon(onPressed: _runScan, icon: const AppIcon(Icons.refresh), label: const Text('Rescan')),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: () => _confirmCleanAll(context, _groups!, detector),
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                  foregroundColor: theme.colorScheme.onError,
                ),
                icon: const AppIcon(Icons.auto_delete),
                label: const Text('Clean Up All'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...sortedArtists.map((artist) {
            final artistGroupsList = artistGroups[artist]!;
            final isExpanded = !_collapsedArtists.contains(artist);
            final totalDupes = artistGroupsList.length;

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () => _toggleArtistExpanded(artist),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(artist, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '$totalDupes duplicate${totalDupes == 1 ? "" : "s"}',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => _toggleArtistExpanded(artist),
                        icon: AppIcon(
                          isExpanded ? appIconSet.navigationDown : appIconSet.navigationRight,
                          color: theme.colorScheme.onSurface,
                          size: 28,
                        ),
                        tooltip: isExpanded ? 'Shrink' : 'Expand',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (isExpanded)
                    ...artistGroupsList.map((group) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: SectionCard(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
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
                                          Text(
                                            group.title,
                                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            group.album,
                                            style: theme.textTheme.bodyMedium?.copyWith(
                                              color: theme.colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    OutlinedButton.icon(
                                      onPressed: () => _cleanSingleGroup(context, group, detector),
                                      icon: const AppIcon(Icons.check_circle_outline),
                                      label: const Text('Keep Best Copy'),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                const SectionDivider(),
                                const SizedBox(height: 8),
                                Column(
                                  children: group.tracks.map((track) {
                                    final isPreferred = track.id == group.preferredTrack.id;
                                    final ext = p.extension(track.filePath).toUpperCase().replaceAll('.', '');
                                    final details =
                                        '$ext • ${track.fileSize.toFileSizeString()} • ${track.durationMs.toDurationString()}';

                                    return Container(
                                      margin: const EdgeInsets.symmetric(vertical: 4),
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(6),
                                        color: isPreferred
                                            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.15)
                                            : Colors.transparent,
                                      ),
                                      child: Row(
                                        children: [
                                          AppIcon(
                                            Icons.audiotrack_outlined,
                                            color: isPreferred
                                                ? theme.colorScheme.primary
                                                : theme.colorScheme.onSurfaceVariant,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  track.filePath,
                                                  style: theme.textTheme.bodyMedium?.copyWith(
                                                    fontWeight: isPreferred ? FontWeight.bold : FontWeight.normal,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  details,
                                                  style: theme.textTheme.bodySmall?.copyWith(
                                                    color: theme.colorScheme.onSurfaceVariant,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          if (isPreferred) ...[
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: theme.colorScheme.primary,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                'Best Quality',
                                                style: theme.textTheme.labelSmall?.copyWith(
                                                  color: theme.colorScheme.onPrimary,
                                                  fontWeight: FontWeight.bold,
                                                  height: 1.0,
                                                ),
                                              ),
                                            ),
                                          ],
                                          const SizedBox(width: 4),
                                          IconButton(
                                            onPressed: () => _confirmDelete(context, track, detector),
                                            icon: AppIcon(Icons.delete_outline, color: theme.colorScheme.error),
                                            tooltip: 'Delete this copy',
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                ],
              ),
            );
          }),
        ],
      );
    }

    return Scaffold(
      backgroundColor: appConfig.adaptiveBg ? Colors.transparent : theme.colorScheme.surface,
      body: content,
    );
  }

  Future<void> _cleanSingleGroup(BuildContext context, DuplicateGroup group, DuplicateDetector detector) async {
    bool deleteFromDisk = false;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return NordAlertDialog(
              title: 'Keep Best Copy?',
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'This will delete all duplicate copies of "${group.title}", keeping only the preferred version:',
                  ),
                  const SizedBox(height: 8),
                  Text(
                    group.preferredTrack.filePath,
                    style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    title: const Text('Delete duplicate physical files from disk permanently'),
                    value: deleteFromDisk,
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() {
                          deleteFromDisk = val;
                        });
                      }
                    },
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary),
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Keep Best'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed == true) {
      setState(() {
        _isScanning = true;
      });
      try {
        for (final track in group.tracks) {
          if (track.id != group.preferredTrack.id) {
            await detector.deleteTrack(track, deleteFromDisk: deleteFromDisk);
          }
        }
        showNordSnackBar(message: 'Cleaned duplicates for "${group.title}"', type: NordSnackBarType.success);
      } catch (e) {
        showNordSnackBar(message: 'Error: $e', type: NordSnackBarType.error);
      } finally {
        _runScan();
      }
    }
  }

  Future<void> _confirmDelete(BuildContext context, Track track, DuplicateDetector detector) async {
    bool deleteFromDisk = false;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return NordAlertDialog(
              title: 'Delete Track Copy?',
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Are you sure you want to delete this duplicate copy?'),
                  const SizedBox(height: 12),
                  Text(
                    track.filePath,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.error),
                  ),
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    title: const Text('Delete physical file from disk permanently'),
                    value: deleteFromDisk,
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() {
                          deleteFromDisk = val;
                        });
                      }
                    },
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Theme.of(context).colorScheme.onError,
                  ),
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Delete'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed == true) {
      setState(() {
        _isScanning = true;
      });
      try {
        await detector.deleteTrack(track, deleteFromDisk: deleteFromDisk);
        showNordSnackBar(message: 'Deleted copy successfully!', type: NordSnackBarType.success);
      } catch (e) {
        showNordSnackBar(message: 'Error: $e', type: NordSnackBarType.error);
      } finally {
        _runScan();
      }
    }
  }

  Future<void> _confirmCleanAll(BuildContext context, List<DuplicateGroup> groups, DuplicateDetector detector) async {
    bool deleteFromDisk = false;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return NordAlertDialog(
              title: 'Clean Up All Duplicates?',
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'This will automatically delete all duplicates, keeping only the highest quality version for each of the ${groups.length} groups.',
                  ),
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    title: const Text('Delete physical files from disk permanently'),
                    value: deleteFromDisk,
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() {
                          deleteFromDisk = val;
                        });
                      }
                    },
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Theme.of(context).colorScheme.onError,
                  ),
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Clean Up'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed == true) {
      setState(() {
        _isScanning = true;
      });
      try {
        for (final group in groups) {
          for (final track in group.tracks) {
            if (track.id != group.preferredTrack.id) {
              await detector.deleteTrack(track, deleteFromDisk: deleteFromDisk);
            }
          }
        }
        showNordSnackBar(message: 'Cleaned up duplicates successfully!', type: NordSnackBarType.success);
      } catch (e) {
        showNordSnackBar(message: 'Error cleaning up: $e', type: NordSnackBarType.error);
      } finally {
        _runScan();
      }
    }
  }
}
