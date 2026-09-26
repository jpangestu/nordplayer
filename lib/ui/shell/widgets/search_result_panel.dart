import 'package:nordplayer/ui/shell/search_viewmodel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nordplayer/ui/tracks/widgets/track_context_menu.dart';
import 'package:nordplayer/ui/shell/shell_viewmodel.dart';
import 'package:nordplayer/data/services/audio/player_service.dart';
import 'package:nordplayer/ui/shared/shortcuts.dart';
import 'package:nordplayer/ui/shared/ui/frosted_glass.dart';
import 'package:nordplayer/ui/shared/ui/music_tile.dart';

class SearchResultsDropdown extends ConsumerWidget {
  const SearchResultsDropdown({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shellState = ref.watch(shellViewModelProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    final searchResultsAsync = ref.watch(searchResultsProvider);
    final theme = Theme.of(context);

    // If the query is empty, hide the dropdown completely
    if (searchQuery.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    // Use TapRegion to detect clicks outside of the search components
    return TapRegion(
      groupId: 'nord_search_group', // Ties it to the search bar
      onTapOutside: (event) {
        ref.read(searchFocusNodeProvider).unfocus();
        ref.read(searchQueryProvider.notifier).clear();
      },
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: (MediaQuery.sizeOf(context).width * 0.4).clamp(200, 500), maxHeight: 400),
        child: FrostedGlass(
          backgroundColor: theme.colorScheme.surfaceContainerHigh.withValues(
            alpha: shellState.isAdaptiveBg ? shellState.adaptiveBgThemeOverlay * 0.5 : 1.0,
          ),
          blurSigma: shellState.adaptiveBgPanelBlur,
          borderRadius: 12,
          child: searchResultsAsync.when(
            loading: () => const SizedBox(height: 100, child: Center(child: CircularProgressIndicator())),
            error: (err, stack) => Padding(padding: const EdgeInsets.all(16), child: Text('Error: $err')),
            data: (tracks) {
              if (tracks.isEmpty) {
                return SizedBox(
                  width: .infinity,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'No results found for "$searchQuery"',
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                itemCount: tracks.length,
                itemExtent: 60,
                shrinkWrap: true, // Hugs the height of the list until maxHeight is hit
                itemBuilder: (context, index) {
                  final trackWithArtists = tracks[index];

                  return ClipRRect(
                    borderRadius: .circular(8),
                    child: MusicTile(
                      padding: const .symmetric(horizontal: 8),
                      albumArtPath: trackWithArtists.album.albumArtPath,
                      title: trackWithArtists.track.title,
                      artists: trackWithArtists.artists.map<String>((artist) => artist.name).toList(),
                      onTap: () {
                        ref
                            .read(playerServiceProvider)
                            .setPlaylist(tracksToPlay: tracks, initialIndex: index, playbackContextType: 'search');

                        ref.read(searchFocusNodeProvider).unfocus();
                        ref.read(searchQueryProvider.notifier).clear();
                      },
                      onRightClick: (globalPosition) {
                        SearchTracksContextMenu.show(
                          context: context,
                          ref: ref,
                          isAdaptive: shellState.isAdaptiveBg,
                          globalPosition: globalPosition,
                          tracks: tracks,
                          indexToPlay: index,
                          playbackContextType: 'search_dropdown',
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
