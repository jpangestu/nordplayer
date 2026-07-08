import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nordplayer/database/app_database.dart';
import 'package:nordplayer/pages/settings/ignored_paths_page.dart';
import 'package:nordplayer/routes/router.dart';
import 'package:nordplayer/services/background_task_service.dart';
import 'package:nordplayer/services/config_service.dart';
import 'package:nordplayer/services/duplicate_detector.dart';
import 'package:nordplayer/services/library_indexer/library_indexer.dart';
import 'package:nordplayer/utils/int_extension.dart';
import 'package:nordplayer/widgets/app_icon.dart';
import 'package:nordplayer/widgets/settings/section_container.dart';
import 'package:nordplayer/widgets/settings/section_divider.dart';
import 'package:nordplayer/widgets/settings/section_expansible.dart';
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

  Future<void> _cleanSingleGroup(DuplicateGroup group) async {
    setState(() => _isProcessing = true);
    try {
      final detector = ref.read(duplicateDetectorProvider);
      for (final track in group.tracks) {
        if (track.id != group.preferredTrack.id) {
          await detector.ignorePath(track);
        }
      }
      ref.invalidate(duplicateGroupsProvider);
      ref.invalidate(ignoredPathsProvider);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _keepAllBestCopies(BuildContext context, List<DuplicateGroup> groups) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keep all best copies?'),
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

    setState(() => _isProcessing = true);
    try {
      final detector = ref.read(duplicateDetectorProvider);
      for (final group in groups) {
        for (final track in group.tracks) {
          if (track.id != group.preferredTrack.id) {
            await detector.ignorePath(track);
          }
        }
      }
      ref.invalidate(duplicateGroupsProvider);
      ref.invalidate(ignoredPathsProvider);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _confirmIgnore(BuildContext context, Track track) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ignore this copy?'),
        content: Text(
          'The track will be removed from your library. The file itself will not be deleted.\n\nFile: ${track.filePath}',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Ignore')),
        ],
      ),
    );

    if (result == true) {
      setState(() => _isProcessing = true);
      try {
        final detector = ref.read(duplicateDetectorProvider);
        await detector.ignorePath(track);
        ref.invalidate(duplicateGroupsProvider);
        ref.invalidate(ignoredPathsProvider);
      } finally {
        if (mounted) setState(() => _isProcessing = false);
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
    // final appIconSet = ref.watch(appIconProvider);
    final tasks = ref.watch(backgroundTaskServiceProvider);
    final theme = Theme.of(context);

    final fingerprintTask = tasks
        .where((t) => t.id == 'fingerprint-generation' && t.status == BackgroundTaskStatus.running)
        .firstOrNull;

    return Scaffold(
      backgroundColor: appConfig.adaptiveBg ? Colors.transparent : Theme.of(context).colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: fingerprintTask != null
                ? SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Finding duplicates requires each track in library to have an audio fingerprint.'),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                fingerprintTask.message.isNotEmpty
                                    ? fingerprintTask.message
                                    : 'Generating audio fingerprints...',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2.0)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        LinearProgressIndicator(
                          value: fingerprintTask.progress,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                  )
                : ref
                      .watch(duplicateGroupsProvider)
                      .when(
                        loading: () => const SliverToBoxAdapter(
                          child: Center(
                            child: Row(
                              children: [
                                Text('Scanning library for duplicates...'),
                                Spacer(),
                                SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2.0)),
                              ],
                            ),
                          ),
                        ),
                        error: (error, stack) => SliverToBoxAdapter(child: Text('Error: $error')),
                        data: (duplicateGroups) {
                          final Map<String, List<DuplicateGroup>> artistGroups = {};
                          for (final group in duplicateGroups) {
                            final artist = group.artist.trim().isEmpty ? 'Unknown Artist' : group.artist;
                            artistGroups.putIfAbsent(artist, () => []).add(group);
                          }
                          final sortedArtistsString = artistGroups.keys.toList()
                            ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

                          return SliverMainAxisGroup(
                            slivers: [
                              SliverToBoxAdapter(
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                duplicateGroups.isEmpty
                                                    ? "No duplicates found!"
                                                    : 'Found ${duplicateGroups.length} duplicate groups.',
                                                style: Theme.of(context).textTheme.titleMedium,
                                              ),
                                              const SizedBox(height: 8),
                                              MouseRegion(
                                                cursor: SystemMouseCursors.click,
                                                child: GestureDetector(
                                                  onTap: () => context.go(
                                                    '${Routes.libraryIndexerPage}/${Routes.duplicatesPage}/${Routes.ignoredPathsPage}',
                                                  ),
                                                  child: Text(
                                                    'See list of all ignored tracks',
                                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                      color: Theme.of(context).colorScheme.primary,
                                                      decoration: TextDecoration.underline,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        OutlinedButton(
                                          onPressed: _isProcessing
                                              ? null
                                              : () => _keepAllBestCopies(context, duplicateGroups),
                                          child: const Row(children: [Icon(Icons.check), Text('Keep all best copies')]),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                ),
                              ),

                              SliverList.builder(
                                itemCount: sortedArtistsString.length,
                                itemBuilder: (context, index) {
                                  final artist = sortedArtistsString[index];
                                  final artistGroupsList = artistGroups[artist]!;
                                  final sortedArtistGroupsList = List<DuplicateGroup>.from(artistGroupsList)
                                    ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: SectionContainer(
                                      child: SectionExpansible(
                                        title: artist,
                                        subtitle: '${artistGroupsList.length.toString()} duplicates',
                                        body: Column(
                                          children: sortedArtistGroupsList.map((group) {
                                            return Padding(
                                              padding: const EdgeInsets.only(bottom: 16),
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
                                                                style: theme.textTheme.titleMedium?.copyWith(
                                                                  fontWeight: FontWeight.bold,
                                                                ),
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
                                                          onPressed: _isProcessing
                                                              ? null
                                                              : () => _cleanSingleGroup(group),
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
                                                        final ext = p
                                                            .extension(track.filePath)
                                                            .toUpperCase()
                                                            .replaceAll('.', '');
                                                        final details =
                                                            '$ext • ${track.fileSize.toFileSizeString()} • ${track.durationMs.toDurationString()}';

                                                        return Container(
                                                          margin: const EdgeInsets.symmetric(vertical: 4),
                                                          padding: const EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                            vertical: 6,
                                                          ),
                                                          decoration: BoxDecoration(
                                                            borderRadius: BorderRadius.circular(6),
                                                            color: isPreferred
                                                                ? theme.colorScheme.primaryContainer.withValues(
                                                                    alpha: 0.15,
                                                                  )
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
                                                                        fontWeight: isPreferred
                                                                            ? FontWeight.bold
                                                                            : FontWeight.normal,
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
                                                                  padding: const EdgeInsets.symmetric(
                                                                    horizontal: 6,
                                                                    vertical: 2,
                                                                  ),
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
                                                                onPressed: _isProcessing
                                                                    ? null
                                                                    : () => _confirmIgnore(context, track),
                                                                icon: AppIcon(
                                                                  Icons.remove_circle_outline,
                                                                  color: theme.colorScheme.onSurfaceVariant,
                                                                ),
                                                                tooltip: 'Ignore this copy',
                                                              ),
                                                            ],
                                                          ),
                                                        );
                                                      }).toList(),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
