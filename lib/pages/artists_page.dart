import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nordplayer/services/config_service.dart';
import 'package:nordplayer/widgets/nord_alert_dialog.dart';

class ArtistsPage extends ConsumerStatefulWidget {
  const ArtistsPage({super.key});

  @override
  ConsumerState<ArtistsPage> createState() => _ArtistsPageState();
}

class _ArtistsPageState extends ConsumerState<ArtistsPage> {
  final TextEditingController _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appConfig = ref.watch(configServiceProvider).requireValue;

    return Scaffold(
      backgroundColor: appConfig.adaptiveBg
          ? theme.colorScheme.surfaceContainer.withValues(alpha: 0.0)
          : theme.colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: .center,
          children: [
            // const Text('Artists'),
            // TextButton(
            //   onPressed: () {
            //     showNordSnackBar(
            //       context: context,
            //       message: 'Created playlist 1 with 12 tracks',
            //       type: .general,
            //       actionLabel: 'Open Playlist',
            //       onAction: (snackbarContext) {},
            //     );
            //   },
            //   child: const Text('Show snack bar with action button'),
            // ),
            // TextButton(
            //   onPressed: () {
            //     showNordSnackBar(
            //       context: context,
            //       message: 'Created playlist 1 with 12 tracks',
            //       type: .info,
            //       actionLabel: 'Open Playlist',
            //       onAction: (snackbarContext) {},
            //     );
            //   },
            //   child: const Text('Show snack bar with action button'),
            // ),
            // TextButton(
            //   onPressed: () {
            //     showNordSnackBar(
            //       context: context,
            //       message: 'Created playlist 1 with 12 tracks',
            //       type: .warning,
            //       actionLabel: 'Open Playlist',
            //       onAction: (snackbarContext) {},
            //     );
            //   },
            //   child: const Text('Show snack bar with action button'),
            // ),
            // TextButton(
            //   onPressed: () {
            //     showNordSnackBar(
            //       context: context,
            //       message: 'Created playlist 1 with 12 tracks',
            //       type: .success,
            //       actionLabel: 'Open Playlist',
            //       onAction: (snackbarContext) {},
            //     );
            //   },
            //   child: const Text('Show snack bar with action button'),
            // ),
            // TextButton(
            //   onPressed: () {
            //     showNordSnackBar(
            //       context: context,
            //       message: 'Created playlist 1 with 12 tracks',
            //       type: .error,
            //       actionLabel: 'Open Playlist',
            //       onAction: (snackbarContext) {},
            //     );
            //   },
            //   child: const Text('Show snack bar with action button'),
            // ),
            TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return NordAlertDialog(
                      title: 'Create New Playlist',
                      content: TextField(
                        controller: _textController,
                        autofocus: true,
                        decoration: const InputDecoration(hintText: 'Playlist Name', border: OutlineInputBorder()),
                        onSubmitted: (value) {},
                      ),
                      actions: [
                        TextButton(onPressed: () => context.pop(), child: const Text('Cancel')),
                        FilledButton(onPressed: () {}, child: const Text('Create')),
                      ],
                    );
                  },
                );
              },
              child: const Text('Show snack bar with action button'),
            ),
          ],
        ),
      ),
    );
  }
}
