import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nordplayer/domain/models/models.dart';
import 'package:nordplayer/data/services/system/background_task_service.dart';
import 'package:nordplayer/ui/shared/themes/icon_sets/app_icon_set.dart';
import 'package:nordplayer/utils/int_extension.dart';
import 'package:nordplayer/ui/settings/library_indexer/duplicates_ui_state.dart';
import 'package:nordplayer/ui/settings/library_indexer/duplicates_viewmodel.dart';
import 'package:nordplayer/routing/router.dart';
import 'package:nordplayer/ui/shared/ui/app_icon.dart';
import 'package:nordplayer/ui/shared/ui/frosted_glass.dart';
import 'package:nordplayer/ui/shared/ui/nord_alert_dialog.dart';
import 'package:nordplayer/ui/shared/ui/nord_snack_bar.dart';
import 'package:path/path.dart' as p;

class DuplicatesView extends ConsumerStatefulWidget {
  const DuplicatesView({super.key});

  @override
  ConsumerState<DuplicatesView> createState() => _DuplicatesViewState();
}

class _DuplicatesViewState extends ConsumerState<DuplicatesView> {
  Future<void> _restoreTracks(List<Track> tracks) async {
    try {
      await ref.read(duplicatesViewModelProvider.notifier).restoreTracks(tracks);
    } catch (_) {}
  }

  Future<void> _keepBestCopy(DuplicateGroup group) async {
    try {
      final tracksToIgnore = await ref.read(duplicatesViewModelProvider.notifier).keepBestCopy(group);
      if (mounted && tracksToIgnore.isNotEmpty) {
        showNordSnackBar(
          message: 'Kept best copy of "${group.title}"',
          type: NordSnackBarType.general,
          actionLabel: 'Undo',
          duration: const Duration(seconds: 6),
          onAction: (context) => _restoreTracks(tracksToIgnore),
        );
      }
    } catch (_) {}
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

    try {
      await ref.read(duplicatesViewModelProvider.notifier).keepAllBestCopies(groups);
    } catch (_) {}
  }

  Future<void> _ignoreTrack(Track track) async {
    try {
      await ref.read(duplicatesViewModelProvider.notifier).ignoreTrack(track);

      if (mounted) {
        showNordSnackBar(
          message: 'Ignored "${p.basename(track.filePath)}"',
          type: NordSnackBarType.general,
          actionLabel: 'Undo',
          duration: const Duration(seconds: 6),
          onAction: (context) => _restoreTracks([track]),
        );
      }
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(duplicatesViewModelProvider.notifier).generateMissingFingerprintsIfNeeded();
    });
  }

  @override
  Widget build(BuildContext context) {
    final uiState = ref.watch(duplicatesViewModelProvider);
    final tasks = ref.watch(backgroundTaskServiceProvider);
    final theme = Theme.of(context);
    final appIconSet = ref.watch(appIconProvider);

    final libraryScanTask = tasks
        .where(
          (t) =>
              (t.id == 'library-scan' || t.id == 'metadata-reindex' || t.id == 'fingerprint-generation') &&
              t.status == BackgroundTaskStatus.running,
        )
        .firstOrNull;

    final sortedGroups = uiState.filteredGroups;
    final isScanLoading = uiState.isScanLoading;
    final hasError = uiState.hasError;
    final showKeepAllBest = uiState.showKeepAllBest;
    final showStats = uiState.showStats;

    return Scaffold(
      backgroundColor: uiState.adaptiveBg ? Colors.transparent : theme.colorScheme.surface,
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
                      blurSigma: uiState.adaptiveBgPanelBlur,
                      borderRadius: 16,
                      backgroundColor: uiState.adaptiveBg
                          ? theme.colorScheme.surfaceContainerLow.withValues(alpha: uiState.adaptiveBgThemeOverlay)
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
                                        onPressed: uiState.isProcessing
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
                                          : () => ref.read(duplicatesViewModelProvider.notifier).triggerRescan(),
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
                                        'Error: ${uiState.errorMessage}',
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
                                    uiState,
                                    label: 'Duplicate Groups',
                                    value: '${sortedGroups.length}',
                                    icon: appIconSet.copy,
                                  ),
                                  _buildStatItem(
                                    context,
                                    uiState,
                                    label: 'Redundant Tracks',
                                    value: '${sortedGroups.fold<int>(0, (sum, g) => sum + g.tracks.length - 1)}',
                                    icon: appIconSet.tracks,
                                  ),
                                  _buildStatItem(
                                    context,
                                    uiState,
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
                                  color: uiState.adaptiveBg
                                      ? theme.colorScheme.surfaceContainer.withValues(
                                          alpha: uiState.adaptiveBgThemeOverlay,
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
                        child: _buildDuplicateGroupCard(context, uiState, group),
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

  Widget _buildStatItem(
    BuildContext context,
    DuplicatesUiState uiState, {
    required String label,
    required String value,
    required IconData icon,
  }) {
    final theme = Theme.of(context);

    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: uiState.adaptiveBg
              ? theme.colorScheme.surfaceContainerHigh.withValues(alpha: uiState.adaptiveBgThemeOverlay)
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

  Widget _buildDuplicateGroupCard(BuildContext context, DuplicatesUiState uiState, DuplicateGroup group) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3), width: 1),
      ),
      child: FrostedGlass(
        blurSigma: uiState.adaptiveBgPanelBlur,
        borderRadius: 12,
        backgroundColor: uiState.adaptiveBg
            ? theme.colorScheme.surfaceContainerLow.withValues(alpha: uiState.adaptiveBgThemeOverlay)
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
                    onPressed: uiState.isProcessing ? null : () => _keepBestCopy(group),
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
                  return _buildTrackRow(context, uiState, track, isPreferred, group);
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackRow(
    BuildContext context,
    DuplicatesUiState uiState,
    Track track,
    bool isPreferred,
    DuplicateGroup group,
  ) {
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
                onPressed: uiState.isProcessing ? null : () => _ignoreTrack(track),
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
