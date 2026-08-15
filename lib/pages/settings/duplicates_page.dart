import 'package:drift/drift.dart' show Value;
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nordplayer/database/app_database.dart';
import 'package:nordplayer/pages/settings/ignored_paths_page.dart';
import 'package:nordplayer/routes/router.dart';
import 'package:nordplayer/services/background_task_service.dart';
import 'package:nordplayer/services/config_service.dart';
import 'package:nordplayer/services/duplicate_detector.dart';
import 'package:nordplayer/services/library_indexer/library_indexer.dart';
import 'package:nordplayer/theming/icon-sets/app_icon_set.dart';
import 'package:nordplayer/utils/int_extension.dart';
import 'package:nordplayer/widgets/app_icon.dart';
import 'package:nordplayer/widgets/frosted_glass.dart';
import 'package:nordplayer/widgets/nord_alert_dialog.dart';
import 'package:nordplayer/widgets/nord_snack_bar.dart';
import 'package:path/path.dart' as p;

// AutoDispose ensures it fetches fresh data when user leave and re-enter the page
final duplicateGroupsProvider = FutureProvider.autoDispose<List<DuplicateGroup>>((ref) async {
  final detector = ref.read(duplicateDetectorProvider);
  return await detector.findDuplicates();
});

class DuplicatesPage extends ConsumerStatefulWidget {
  const DuplicatesPage({super.key});

  @override
  ConsumerState<DuplicatesPage> createState() => _DuplicatesPageState();
}

class _DuplicatesPageState extends ConsumerState<DuplicatesPage> {
  bool _isProcessing = false;
  bool _isScanningTriggered = false;
  final Set<int> _manuallyIgnoredTrackIds = {};

  Future<void> _restoreTracks(List<Track> tracks) async {
    try {
      final db = ref.read(appDatabaseProvider);
      await db.transaction(() async {
        final filePaths = tracks.map((t) => t.filePath).toList();
        await (db.delete(db.ignoredPaths)..where((t) => t.filePath.isIn(filePaths))).go();

        for (final track in tracks) {
          await db.into(db.tracks).insertOnConflictUpdate(track);
          await db
              .into(db.trackArtist)
              .insertOnConflictUpdate(TrackArtistCompanion(trackId: Value(track.id), artistId: Value(track.artistId)));
        }
      });
      ref.invalidate(duplicateGroupsProvider);
      ref.invalidate(ignoredPathsProvider);
    } catch (e) {
      debugPrint('Failed to undo ignore: $e');
    }
  }

  Future<void> _keepBestCopy(DuplicateGroup group) async {
    final tracksToIgnore = group.tracks.where((t) => t.id != group.preferredTrack.id).toList();
    if (tracksToIgnore.isEmpty) return;

    setState(() {
      _isProcessing = true;
      for (final t in tracksToIgnore) {
        _manuallyIgnoredTrackIds.add(t.id);
      }
    });

    try {
      final detector = ref.read(duplicateDetectorProvider);
      await detector.ignorePaths(tracksToIgnore);
      ref.invalidate(duplicateGroupsProvider);
      ref.invalidate(ignoredPathsProvider);

      if (mounted) {
        showNordSnackBar(
          message: 'Kept best copy of "${group.title}"',
          type: NordSnackBarType.general,
          actionLabel: 'Undo',
          duration: const Duration(seconds: 6),
          onAction: (context) async {
            setState(() {
              for (final t in tracksToIgnore) {
                _manuallyIgnoredTrackIds.remove(t.id);
              }
            });
            await _restoreTracks(tracksToIgnore);
          },
        );
      }
    } catch (_) {
      // Revert optimistic updates on error
      if (mounted) {
        setState(() {
          for (final t in tracksToIgnore) {
            _manuallyIgnoredTrackIds.remove(t.id);
          }
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _keepAllBestCopies(BuildContext context, List<DuplicateGroup> groups) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => NordAlertDialog(
        title: 'Keep all best copies?',
        content: const Text(
          'All duplicate tracks will be removed from your library, keeping only the best quality copy in each group. The files themselves will not be deleted.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirm')),
        ],
      ),
    );

    if (result != true) return;

    final tracksToIgnore = <Track>[];
    for (final group in groups) {
      for (final track in group.tracks) {
        if (track.id != group.preferredTrack.id) {
          tracksToIgnore.add(track);
        }
      }
    }

    if (tracksToIgnore.isEmpty) return;

    setState(() {
      _isProcessing = true;
      for (final t in tracksToIgnore) {
        _manuallyIgnoredTrackIds.add(t.id);
      }
    });

    try {
      final detector = ref.read(duplicateDetectorProvider);
      await detector.ignorePaths(tracksToIgnore);
      ref.invalidate(duplicateGroupsProvider);
      ref.invalidate(ignoredPathsProvider);
    } catch (_) {
      if (mounted) {
        setState(() {
          for (final t in tracksToIgnore) {
            _manuallyIgnoredTrackIds.remove(t.id);
          }
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _ignoreTrack(Track track) async {
    setState(() {
      _isProcessing = true;
      _manuallyIgnoredTrackIds.add(track.id);
    });
    try {
      final detector = ref.read(duplicateDetectorProvider);
      await detector.ignorePath(track);
      ref.invalidate(duplicateGroupsProvider);
      ref.invalidate(ignoredPathsProvider);

      if (mounted) {
        showNordSnackBar(
          message: 'Ignored "${p.basename(track.filePath)}"',
          type: NordSnackBarType.general,
          actionLabel: 'Undo',
          duration: const Duration(seconds: 6),
          onAction: (context) async {
            setState(() {
              _manuallyIgnoredTrackIds.remove(track.id);
            });
            await _restoreTracks([track]);
          },
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _manuallyIgnoredTrackIds.remove(track.id);
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();

    final tasks = ref.read(backgroundTaskServiceProvider);
    final isAnyTaskRunning = tasks.any((t) => t.status == BackgroundTaskStatus.running);
    if (!isAnyTaskRunning) {
      Future.microtask(() {
        ref.read(libraryIndexerProvider).generateMissingFingerprints();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appConfig = ref.watch(configServiceProvider).requireValue;
    final tasks = ref.watch(backgroundTaskServiceProvider);
    final theme = Theme.of(context);

    ref.listen<AsyncValue<List<DuplicateGroup>>>(duplicateGroupsProvider, (previous, next) {
      if (!next.isLoading && next.hasValue) {
        setState(() {
          _isScanningTriggered = false;
        });
      }
    });

    ref.listen<List<BackgroundTask>>(backgroundTaskServiceProvider, (previous, next) {
      final wasScanning =
          previous?.any(
            (t) =>
                (t.id == 'library-scan' || t.id == 'metadata-reindex' || t.id == 'fingerprint-generation') &&
                t.status == BackgroundTaskStatus.running,
          ) ??
          false;
      final isScanningNow = next.any(
        (t) =>
            (t.id == 'library-scan' || t.id == 'metadata-reindex' || t.id == 'fingerprint-generation') &&
            t.status == BackgroundTaskStatus.running,
      );

      if (wasScanning && !isScanningNow) {
        setState(() {
          _isScanningTriggered = true;
        });
        ref.invalidate(duplicateGroupsProvider);
      }
    });

    final libraryScanTask = tasks
        .where(
          (t) =>
              (t.id == 'library-scan' || t.id == 'metadata-reindex' || t.id == 'fingerprint-generation') &&
              t.status == BackgroundTaskStatus.running,
        )
        .firstOrNull;
    final isScanning = libraryScanTask != null;

    final duplicateGroupsAsync = ref.watch(duplicateGroupsProvider);
    final duplicateGroups = duplicateGroupsAsync.value ?? [];
    final appIconSet = ref.watch(appIconProvider);

    // Clean up _manuallyIgnoredTrackIds for IDs that are no longer in the duplicateGroups
    if (_manuallyIgnoredTrackIds.isNotEmpty) {
      final allTrackIds = duplicateGroups.expand((g) => g.tracks).map((t) => t.id).toSet();
      _manuallyIgnoredTrackIds.retainAll(allTrackIds);
    }

    // Apply optimistic updates (filter out manually ignored tracks)
    final filteredGroups = duplicateGroups
        .map((group) {
          final remainingTracks = group.tracks.where((t) => !_manuallyIgnoredTrackIds.contains(t.id)).toList();
          if (remainingTracks.length < 2) return null;

          final preferredTrack = remainingTracks.contains(group.preferredTrack)
              ? group.preferredTrack
              : remainingTracks.first;

          return DuplicateGroup(
            title: group.title,
            artist: group.artist,
            album: group.album,
            tracks: remainingTracks,
            preferredTrack: preferredTrack,
          );
        })
        .whereType<DuplicateGroup>()
        .toList();

    final sortedGroups = List<DuplicateGroup>.from(filteredGroups)
      ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));

    final isLoading = duplicateGroupsAsync.isLoading && !duplicateGroupsAsync.hasValue;
    final isScanLoading = isLoading || isScanning || _isScanningTriggered;
    final hasError = duplicateGroupsAsync.hasError;
    final showKeepAllBest = !isScanLoading && !hasError && sortedGroups.isNotEmpty;
    final showStats = !isScanLoading && !hasError && sortedGroups.isNotEmpty;

    return Scaffold(
      backgroundColor: appConfig.adaptiveBg ? Colors.transparent : theme.colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverMainAxisGroup(
              slivers: [
                // Summary Header Card
                SliverToBoxAdapter(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5), width: 1),
                    ),
                    child: FrostedGlass(
                      blurSigma: appConfig.adaptiveBgPanelBlur,
                      borderRadius: 16,
                      backgroundColor: appConfig.adaptiveBg
                          ? theme.colorScheme.surfaceContainerLow.withValues(alpha: appConfig.adaptiveBgThemeOverlay)
                          : theme.colorScheme.surfaceContainerLow,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Duplicate Scan Overview',
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        isScanLoading
                                            ? (libraryScanTask != null && libraryScanTask.message.isNotEmpty
                                                  ? libraryScanTask.message
                                                  : 'Scanning library for duplicate tracks...')
                                            : hasError
                                            ? 'An error occurred during duplicate scan.'
                                            : sortedGroups.isEmpty
                                            ? 'No duplicate tracks detected.'
                                            : 'Keep the highest quality file and clean the database index of others.',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: theme.colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (showKeepAllBest) ...[
                                      OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: theme.colorScheme.primary,
                                          side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.5)),
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                        onPressed: _isProcessing
                                            ? null
                                            : () => _keepAllBestCopies(context, sortedGroups),
                                        icon: const AppIcon(Icons.auto_awesome, size: 18),
                                        label: const Text(
                                          'Keep All Best',
                                          style: TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                    IconButton(
                                      onPressed: isScanLoading
                                          ? null
                                          : () {
                                              setState(() {
                                                _isScanningTriggered = true;
                                              });
                                              ref.read(libraryIndexerProvider).scanLibrary();
                                            },
                                      icon: isScanLoading
                                          ? const SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(strokeWidth: 2.0),
                                            )
                                          : const AppIcon(Icons.sync, size: 20),
                                      tooltip: 'Rescan library and find duplicate',
                                      color: theme.colorScheme.primary,
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            if (hasError)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 24),
                                child: Center(
                                  child: Column(
                                    children: [
                                      AppIcon(Icons.error_outline, size: 32, color: theme.colorScheme.error),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Error: ${duplicateGroupsAsync.error}',
                                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else ...[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildStatItem(
                                    context,
                                    label: 'Duplicate Groups',
                                    value: '${sortedGroups.length}',
                                    icon: appIconSet.copy,
                                  ),
                                  _buildStatItem(
                                    context,
                                    label: 'Redundant Tracks',
                                    value: '${sortedGroups.fold<int>(0, (sum, g) => sum + g.tracks.length - 1)}',
                                    icon: appIconSet.tracks,
                                  ),
                                  _buildStatItem(
                                    context,
                                    label: 'Indexed Space Redundancy',
                                    value: sortedGroups
                                        .fold<int>(
                                          0,
                                          (sum, g) =>
                                              sum +
                                              g.tracks
                                                  .where((t) => t.id != g.preferredTrack.id)
                                                  .fold<int>(0, (s, t) => s + t.fileSize),
                                        )
                                        .toFileSizeString(),
                                    icon: appIconSet.storage,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: appConfig.adaptiveBg
                                      ? theme.colorScheme.surfaceContainer.withValues(
                                          alpha: appConfig.adaptiveBgThemeOverlay,
                                        )
                                      : theme.colorScheme.surfaceContainer,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    AppIcon(appIconSet.info, color: theme.colorScheme.primary, size: 20),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Safe Clean Up: Ignoring/cleaning duplicates does not delete files from your storage. It only removes redundant index paths from your library database.',
                                        style: theme.textTheme.bodySmall?.copyWith(height: 1.3),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                            MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                onTap: () => context.go(
                                  '${Routes.libraryIndexerPage}/${Routes.duplicatesPage}/${Routes.ignoredPathsPage}',
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'See list of all ignored tracks',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    AppIcon(Icons.arrow_forward, color: theme.colorScheme.primary, size: 14),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                if (showStats) ...[
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),
                  // List of duplicate groups
                  SliverList.builder(
                    itemCount: sortedGroups.length,
                    itemBuilder: (context, idx) {
                      final group = sortedGroups[idx];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: _buildDuplicateGroupCard(context, group),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, {required String label, required String value, required IconData icon}) {
    final theme = Theme.of(context);
    final appConfig = ref.watch(configServiceProvider).requireValue;

    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: appConfig.adaptiveBg
              ? theme.colorScheme.surfaceContainerHigh.withValues(alpha: appConfig.adaptiveBgThemeOverlay)
              : theme.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3), width: 0.5),
        ),
        child: Row(
          children: [
            AppIcon(icon, color: theme.colorScheme.primary, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDuplicateGroupCard(BuildContext context, DuplicateGroup group) {
    final theme = Theme.of(context);

    final appConfig = ref.watch(configServiceProvider).requireValue;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3), width: 1),
      ),
      child: FrostedGlass(
        blurSigma: appConfig.adaptiveBgPanelBlur,
        borderRadius: 12,
        backgroundColor: appConfig.adaptiveBg
            ? theme.colorScheme.surfaceContainerLow.withValues(alpha: appConfig.adaptiveBgThemeOverlay)
            : theme.colorScheme.surfaceContainerLow,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header of the song duplicate group
            Container(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.03),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(group.title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                group.artist.trim().isEmpty ? 'Unknown Artist' : group.artist,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '•',
                              style: TextStyle(color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                group.album.trim().isEmpty ? 'Unknown Album' : group.album,
                                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    onPressed: _isProcessing ? null : () => _keepBestCopy(group),
                    icon: const AppIcon(Icons.auto_awesome, size: 16),
                    label: const Text('Keep Best', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),

            // Track rows
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                children: group.tracks.map((track) {
                  final isPreferred = track.id == group.preferredTrack.id;
                  return _buildTrackRow(context, track, isPreferred, group);
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackRow(BuildContext context, Track track, bool isPreferred, DuplicateGroup group) {
    final theme = Theme.of(context);
    final ext = p.extension(track.filePath).toUpperCase().replaceAll('.', '');

    // Split filename and parent directory for cleaner display
    final fileName = p.basename(track.filePath);
    final parentDir = p.dirname(track.filePath);

    // Format badge color
    final isLossless = const ['FLAC', 'WAV', 'ALAC', 'APE'].contains(ext);
    final badgeBgColor = isLossless
        ? const Color(0xFF10B981).withValues(alpha: 0.15)
        : theme.colorScheme.surfaceContainerHighest;
    final badgeTextColor = isLossless ? const Color(0xFF10B981) : theme.colorScheme.onSurfaceVariant;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: isPreferred ? theme.colorScheme.primaryContainer.withValues(alpha: 0.08) : Colors.transparent,
        border: Border.all(
          color: isPreferred ? theme.colorScheme.primary.withValues(alpha: 0.2) : Colors.transparent,
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Audio Format Badge
              Container(
                width: 52,
                padding: const EdgeInsets.symmetric(vertical: 4),
                alignment: Alignment.center,
                decoration: BoxDecoration(color: badgeBgColor, borderRadius: BorderRadius.circular(4)),
                child: Text(
                  ext,
                  style: theme.textTheme.labelMedium?.copyWith(color: badgeTextColor, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),

              // Filename & Parent Directory
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      fileName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: isPreferred ? FontWeight.bold : FontWeight.normal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const AppIcon(Icons.folder_open, size: 12, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            parentDir,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              if (isPreferred) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: theme.colorScheme.primary, borderRadius: BorderRadius.circular(4)),
                  child: Text(
                    'Best Copy',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],

              // Details (duration, size) & Badges
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    track.durationMs.toDurationString(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: isPreferred ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    track.fileSize.toFileSizeString(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _isProcessing ? null : () => _ignoreTrack(track),
                icon: AppIcon(
                  Icons.remove_circle_outline,
                  color: isPreferred
                      ? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4)
                      : theme.colorScheme.error.withValues(alpha: 0.7),
                  size: 20,
                ),
                tooltip: isPreferred ? 'Ignore preferred copy' : 'Ignore this copy',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
