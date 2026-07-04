import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nordplayer/database/app_database.dart';
import 'package:nordplayer/services/config_service.dart';
import 'package:nordplayer/widgets/app_icon.dart';

final ignoredPathsProvider = FutureProvider.autoDispose<List<IgnoredPath>>((ref) async {
  final db = ref.read(appDatabaseProvider);
  final paths = await db.select(db.ignoredPaths).get();
  return paths.toList()..sort((a, b) => a.filePath.compareTo(b.filePath));
});

class IgnoredPathsPage extends ConsumerStatefulWidget {
  const IgnoredPathsPage({super.key});

  @override
  ConsumerState<IgnoredPathsPage> createState() => _IgnoredPathsPageState();
}

class _IgnoredPathsPageState extends ConsumerState<IgnoredPathsPage> {
  bool _isProcessing = false;

  Future<void> _restorePath(IgnoredPath path) async {
    setState(() => _isProcessing = true);
    try {
      final db = ref.read(appDatabaseProvider);
      await (db.delete(db.ignoredPaths)..where((t) => t.filePath.equals(path.filePath))).go();
      ref.invalidate(ignoredPathsProvider);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _restoreAll(List<IgnoredPath> paths) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore all tracks?'),
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

    setState(() => _isProcessing = true);
    try {
      final db = ref.read(appDatabaseProvider);
      await db.delete(db.ignoredPaths).go();
      ref.invalidate(ignoredPathsProvider);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appConfig = ref.watch(configServiceProvider).requireValue;

    return Scaffold(
      backgroundColor: appConfig.adaptiveBg ? Colors.transparent : Theme.of(context).colorScheme.surface,
      body: ref
          .watch(ignoredPathsProvider)
          .when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: Text('Error: $error')),
            data: (paths) {
              if (paths.isEmpty) {
                return const Center(child: Text('No ignored tracks.'));
              }

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Found ${paths.length} ignored tracks. Restore them and scan your library to re-add them.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        const SizedBox(width: 16),
                        OutlinedButton.icon(
                          onPressed: _isProcessing ? null : () => _restoreAll(paths),
                          icon: const AppIcon(Icons.restore_page),
                          label: const Text('Restore All'),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: paths.length,
                      itemBuilder: (context, index) {
                        final path = paths[index];
                        return ListTile(
                          title: Text(path.filePath, maxLines: 2, overflow: TextOverflow.ellipsis),
                          trailing: IconButton(
                            icon: const AppIcon(Icons.restore),
                            tooltip: 'Restore track',
                            onPressed: _isProcessing ? null : () => _restorePath(path),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
    );
  }
}
