import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nordplayer/domain/models/models.dart';
import 'package:nordplayer/core/system/logger.dart';
import 'package:nordplayer/features/playlists/playlists_viewmodel.dart';
import 'package:nordplayer/routes/router.dart';
import 'package:nordplayer/widgets/nord_alert_dialog.dart';
import 'package:nordplayer/widgets/nord_snack_bar.dart';

/// Convenience function to display the [CreatePlaylistDialog].
Future<void> showCreatePlaylistDialog(BuildContext context, [Object? database]) async {
  await showDialog(context: context, builder: (context) => const CreatePlaylistDialog());
}

/// Convenience function to display the [CreatePlaylistDialog] and immediately add tracks upon creation.
Future<void> showCreatePlaylistDialogAndAddTracks(
  BuildContext context,
  dynamic dbOrTracks, [
  List<TrackWithArtists>? tracksToAdd,
]) async {
  final List<TrackWithArtists> tracks = switch (dbOrTracks) {
    List<TrackWithArtists> list => list,
    _ => tracksToAdd ?? const [],
  };

  await showDialog(
    context: context,
    builder: (context) => CreatePlaylistDialog(tracksToAdd: tracks),
  );
}

/// Convenience function to display the [RenamePlaylistDialog].
Future<void> showRenamePlaylistDialog(BuildContext context, Playlist playlist, [Object? database]) async {
  await showDialog(
    context: context,
    builder: (context) => RenamePlaylistDialog(playlist: playlist),
  );
}

/// Dialog allowing users to create a new playlist and optionally add initial tracks.
class CreatePlaylistDialog extends ConsumerStatefulWidget {
  final Object? database;
  final List<TrackWithArtists> tracksToAdd;

  const CreatePlaylistDialog({super.key, this.database, this.tracksToAdd = const []});

  @override
  ConsumerState<CreatePlaylistDialog> createState() => _CreatePlaylistDialogState();
}

class _CreatePlaylistDialogState extends ConsumerState<CreatePlaylistDialog> with LoggerMixin {
  late final TextEditingController _textController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _textController.text.trim();

    if (name.isEmpty) {
      Navigator.pop(context);
      return;
    }

    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      final trackIds = widget.tracksToAdd.map((t) => t.track.id).toList();
      final vm = ref.read(playlistsViewModelProvider);
      final newPlaylistId = await vm.createPlaylist(name, trackIds: trackIds);

      if (!mounted) return;

      if (widget.tracksToAdd.isNotEmpty) {
        showNordSnackBar(
          message: 'Created "$name" with ${trackIds.length} track(s)',
          type: .success,
          actionLabel: 'Open Playlist',
          onAction: (snackBarContext) {
            snackBarContext.go('${Routes.playlistsPage}/$newPlaylistId');
          },
        );
      } else {
        showNordSnackBar(
          message: 'Playlist "$name" created',
          type: .success,
          actionLabel: 'Open',
          onAction: (snackBarContext) {
            snackBarContext.go('${Routes.playlistsPage}/$newPlaylistId');
          },
        );
      }

      Navigator.pop(context);
    } catch (e, st) {
      log.e('Failed to create playlist "$name"', error: e, stackTrace: st);
      if (mounted) {
        showNordSnackBar(message: 'Failed to create playlist', type: .error);
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return NordAlertDialog(
      title: 'Create New Playlist',
      content: TextField(
        controller: _textController,
        autofocus: true,
        decoration: const InputDecoration(hintText: 'Playlist Name', border: OutlineInputBorder()),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Create'),
        ),
      ],
    );
  }
}

/// Dialog allowing users to rename an existing playlist.
class RenamePlaylistDialog extends ConsumerStatefulWidget {
  final Object? database;
  final Playlist playlist;

  const RenamePlaylistDialog({super.key, required this.playlist, this.database});

  @override
  ConsumerState<RenamePlaylistDialog> createState() => _RenamePlaylistDialogState();
}

class _RenamePlaylistDialogState extends ConsumerState<RenamePlaylistDialog> with LoggerMixin {
  late final TextEditingController _textController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.playlist.name);
    _textController.selection = TextSelection(baseOffset: 0, extentOffset: widget.playlist.name.length);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final newName = _textController.text.trim();

    if (newName.isEmpty || newName == widget.playlist.name) {
      Navigator.pop(context);
      return;
    }

    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      final vm = ref.read(playlistsViewModelProvider);
      await vm.renamePlaylist(widget.playlist.id, newName);

      if (!mounted) return;
      showNordSnackBar(message: 'Renamed to "$newName"', type: .success);
      Navigator.pop(context);
    } catch (e, st) {
      log.e('Failed to rename playlist', error: e, stackTrace: st);
      if (mounted) {
        showNordSnackBar(message: 'Failed to rename playlist', type: .error);
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return NordAlertDialog(
      title: 'Rename Playlist',
      content: TextField(
        controller: _textController,
        autofocus: true,
        decoration: const InputDecoration(hintText: 'New Playlist Name', border: OutlineInputBorder()),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Rename'),
        ),
      ],
    );
  }
}
