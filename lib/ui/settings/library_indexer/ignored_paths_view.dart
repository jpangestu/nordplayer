import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nordplayer/data/database/app_database.dart' show IgnoredPath;
import 'package:nordplayer/ui/shared/themes/icon_sets/app_icon_set.dart';
import 'package:nordplayer/ui/settings/library_indexer/ignored_paths_viewmodel.dart';
import 'package:nordplayer/ui/shared/ui/app_icon.dart';
import 'package:nordplayer/ui/shared/ui/frosted_glass.dart';
import 'package:nordplayer/ui/shared/ui/nord_alert_dialog.dart';
import 'package:nordplayer/ui/shared/ui/nord_snack_bar.dart';
import 'package:path/path.dart' as p;

class IgnoredPathsView extends ConsumerStatefulWidget {
  const IgnoredPathsView({super.key});

  @override
  ConsumerState<IgnoredPathsView> createState() => _IgnoredPathsViewState();
}

class _IgnoredPathsViewState extends ConsumerState<IgnoredPathsView> {
  Future<void> _ignorePaths(List<String> filePaths) async {
    try {
      await ref.read(ignoredPathsViewModelProvider.notifier).reignorePaths(filePaths);
    } catch (_) {}
  }

  Future<void> _restorePath(IgnoredPath path) async {
    try {
      await ref.read(ignoredPathsViewModelProvider.notifier).restorePath(path);

      if (mounted) {
        showNordSnackBar(
          message: 'Restored "${p.basename(path.filePath)}"',
          type: NordSnackBarType.general,
          actionLabel: 'Undo',
          duration: const Duration(seconds: 6),
          onAction: (context) async {
            await _ignorePaths([path.filePath]);
          },
        );
      }
    } catch (_) {}
  }

  Future<void> _restoreAll(List<IgnoredPath> paths) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => NordAlertDialog(
        title: 'Restore all tracks?',
        content: const Text(
          'This will clear the ignored tracks list. You will need to scan your library to re-add these tracks.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Restore All')),
        ],
      ),
    );

    if (result != true) return;

    final pathsToRestore = paths.map((p) => p.filePath).toList();

    try {
      await ref.read(ignoredPathsViewModelProvider.notifier).restoreAll(paths);

      if (mounted) {
        showNordSnackBar(
          message: 'Restored ${pathsToRestore.length} tracks',
          type: NordSnackBarType.general,
          actionLabel: 'Undo',
          duration: const Duration(seconds: 6),
          onAction: (context) async {
            await _ignorePaths(pathsToRestore);
          },
        );
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appIconSet = ref.watch(appIconProvider);
    final uiState = ref.watch(ignoredPathsViewModelProvider);

    final filteredPaths = uiState.filteredPaths;
    final isLoading = uiState.isLoading;
    final hasError = uiState.hasError;
    final showRestoreAll = uiState.showRestoreAll;
    final showEmptyMessage = uiState.showEmptyMessage;
    final showList = uiState.showList;

    return Scaffold(
      backgroundColor: uiState.adaptiveBg ? Colors.transparent : theme.colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
          child: CustomScrollView(
            slivers: [
              if (isLoading)
                const SliverFillRemaining(child: Center(child: CircularProgressIndicator(strokeWidth: 2.0)))
              else if (hasError)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('Error: ${uiState.errorMessage}', style: TextStyle(color: theme.colorScheme.error)),
                  ),
                )
              else
                SliverMainAxisGroup(
                  slivers: [
                    // Summary Card
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                              width: 1,
                            ),
                          ),
                          child: FrostedGlass(
                            blurSigma: uiState.adaptiveBgPanelBlur,
                            borderRadius: 16,
                            backgroundColor: uiState.adaptiveBg
                                ? theme.colorScheme.surfaceContainerLow.withValues(
                                    alpha: uiState.adaptiveBgThemeOverlay,
                                  )
                                : theme.colorScheme.surfaceContainerLow,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
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
                                              'Ignored Tracks Overview',
                                              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              filteredPaths.isEmpty ? 'No ignored tracks.' : 'Restoring tracks will re-add them back into your library scanning scope.',
                                              style: theme.textTheme.bodySmall?.copyWith(
                                                color: theme.colorScheme.onSurfaceVariant,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (showRestoreAll) ...[
                                        const SizedBox(width: 16),
                                        OutlinedButton.icon(
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: theme.colorScheme.primary,
                                            side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.5)),
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          ),
                                          onPressed: uiState.isProcessing ? null : () => _restoreAll(filteredPaths),
                                          icon: const AppIcon(Icons.restore_page, size: 18),
                                          label: const Text(
                                            'Restore All',
                                            style: TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  if (showEmptyMessage)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 24),
                                      child: Center(
                                        child: Text(
                                          'Any duplicate files that you choose to ignore will appear here.',
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            color: theme.colorScheme.onSurfaceVariant,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    if (showList)
                      // List of ignored paths in a modern cards list
                      SliverList.builder(
                        itemCount: filteredPaths.length,
                        itemBuilder: (context, index) {
                          final path = filteredPaths[index];
                          final fileName = p.basename(path.filePath);
                          final dirName = p.dirname(path.filePath);

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              child: FrostedGlass(
                                blurSigma: uiState.adaptiveBgPanelBlur,
                                borderRadius: 12,
                                backgroundColor: uiState.adaptiveBg
                                    ? theme.colorScheme.surfaceContainer.withValues(
                                        alpha: uiState.adaptiveBgThemeOverlay,
                                      )
                                    : theme.colorScheme.surfaceContainer,
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      // Music Icon
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: AppIcon(
                                          appIconSet.tracks,
                                          color: theme.colorScheme.primary.withValues(alpha: 0.7),
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),

                                      // Filename and Path
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              fileName,
                                              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
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
                                                    dirName,
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

                                      // Actions
                                      IconButton(
                                        icon: const AppIcon(Icons.restore),
                                        tooltip: 'Restore track',
                                        color: theme.colorScheme.primary,
                                        onPressed: uiState.isProcessing ? null : () => _restorePath(path),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
