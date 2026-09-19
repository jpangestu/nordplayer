import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nordplayer/core/database/app_database.dart';
import 'package:nordplayer/core/models/selection_state.dart';
import 'package:nordplayer/core/services/config_service.dart';
import 'package:nordplayer/core/theme/icon-sets/app_icon_set.dart';
import 'package:nordplayer/core/utils/int_extension.dart';
import 'package:nordplayer/data/repositories/repositories.dart';
import 'package:nordplayer/pages/pages_context_menu.dart';
import 'package:nordplayer/services/player_service.dart';
import 'package:nordplayer/widgets/animated_equalizer_icon.dart';
import 'package:nordplayer/widgets/app_icon.dart';
import 'package:nordplayer/widgets/sliver_resizable_table.dart';
import 'package:nordplayer/widgets/unimplemented.dart';

/// Available sorting criteria for album tracks.
enum AlbumTrackSort {
  trackNumber('Track Number'),
  title('Title'),
  duration('Duration');

  final String label;
  const AlbumTrackSort(this.label);
}

/// Provider managing active sort criterion for album detail tracks.
final albumTrackSortProvider = NotifierProvider<AlbumTrackSortNotifier, AlbumTrackSort>(
  AlbumTrackSortNotifier.new,
);

class AlbumTrackSortNotifier extends Notifier<AlbumTrackSort> {
  @override
  AlbumTrackSort build() => AlbumTrackSort.trackNumber;

  void setSort(AlbumTrackSort sort) {
    state = sort;
  }
}

/// Sort ordering direction.
enum SortOrder {
  ascending('Ascending'),
  descending('Descending');

  final String label;
  const SortOrder(this.label);
}

/// Provider managing active sort direction for album detail tracks.
final albumTrackSortOrderProvider = NotifierProvider<AlbumTrackSortOrderNotifier, SortOrder>(
  AlbumTrackSortOrderNotifier.new,
);

class AlbumTrackSortOrderNotifier extends Notifier<SortOrder> {
  @override
  SortOrder build() => SortOrder.ascending;

  void setOrder(SortOrder order) {
    state = order;
  }
}

/// Provider managing favorites-only filter toggle for album detail tracks.
final albumShowFavoritesOnlyProvider = NotifierProvider<AlbumShowFavoritesOnlyNotifier, bool>(
  AlbumShowFavoritesOnlyNotifier.new,
);

class AlbumShowFavoritesOnlyNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() {
    state = !state;
  }
}

/// Computes sorted, ordered, and filtered tracks for a given album.
final sortedAlbumWithTracksProvider = Provider.autoDispose.family<AsyncValue<AlbumWithTracks?>, int>((ref, albumId) {
  final albumAsync = ref.watch(albumWithTracksProvider(albumId));
  final currentSort = ref.watch(albumTrackSortProvider);
  final currentOrder = ref.watch(albumTrackSortOrderProvider);
  final showFavoritesOnly = ref.watch(albumShowFavoritesOnlyProvider);

  return albumAsync.whenData((data) {
    if (data == null) return null;
    final orderMultiplier = currentOrder == SortOrder.ascending ? 1 : -1;
    var sortedTracks = List<TrackWithArtists>.from(data.tracks);

    if (showFavoritesOnly) {
      // Future favorite filter hook
    }

    switch (currentSort) {
      case AlbumTrackSort.trackNumber:
        sortedTracks.sort((a, b) => a.track.trackNumber.compareTo(b.track.trackNumber) * orderMultiplier);
        break;
      case AlbumTrackSort.title:
        sortedTracks.sort(
          (a, b) => a.track.title.toLowerCase().compareTo(b.track.title.toLowerCase()) * orderMultiplier,
        );
        break;
      case AlbumTrackSort.duration:
        sortedTracks.sort((a, b) => a.track.durationMs.compareTo(b.track.durationMs) * orderMultiplier);
        break;
    }
    return AlbumWithTracks(album: data.album, tracks: sortedTracks, tracksLengthMs: data.tracksLengthMs);
  });
});

/// Context menu popup widget for selecting which columns appear in the album detail table.
class AlbumDetailPageTableColumnSelectorMenu extends ConsumerWidget {
  const AlbumDetailPageTableColumnSelectorMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final columns = ref.watch(albumDetailPageTableColumnsProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: columns.map((col) {
        return InkWell(
          onTap: () {
            ref.read(albumDetailPageTableColumnsProvider.notifier).toggleVisibility(col.id);
          },
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(
                  col.isVisible ? Icons.check_box : Icons.check_box_outline_blank,
                  size: 20,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                const SizedBox(width: 12),
                Text(
                  col.label.isEmpty ? (col.id == 'context_menu' ? 'More Options' : col.id) : col.label,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Provider managing table column layout and visibility for the album detail table.
final albumDetailPageTableColumnsProvider =
    NotifierProvider<AlbumDetailPageTableColumnsNotifier, List<TableColumn<TrackWithArtists>>>(
      AlbumDetailPageTableColumnsNotifier.new,
    );

class AlbumDetailPageTableColumnsNotifier extends Notifier<List<TableColumn<TrackWithArtists>>> {
  @override
  List<TableColumn<TrackWithArtists>> build() => _initialColumns;

  void toggleVisibility(String columnId) {
    state = state.map((col) {
      if (col.id == columnId) {
        return col.copyWith(isVisible: !col.isVisible);
      }
      return col;
    }).toList();
  }

  static final List<TableColumn<TrackWithArtists>> _initialColumns = [
    TableColumn<TrackWithArtists>(
      id: 'index',
      label: "#",
      width: 50,
      minWidth: 50,
      alignment: Alignment.centerRight,
      cellBuilder: (context, track, index) {
        return Consumer(
          builder: (context, ref, child) {
            final isActiveTrack = ref.watch(currentTrackProvider)?.track.filePath == track.track.filePath;

            if (isActiveTrack) {
              final isAudioPlaying = ref.watch(isPlayingProvider);

              return AnimatedEqualizerIcon(
                color: Theme.of(context).colorScheme.primary,
                size: 16,
                isPlaying: isAudioPlaying,
              );
            }
            return Text(
              track.track.trackNumber.toString(),
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6)),
            );
          },
        );
      },
    ),
    TableColumn<TrackWithArtists>(
      id: 'title',
      label: "Title",
      flex: 5,
      minWidth: 150,
      cellBuilder: (context, track, index) {
        return Text(track.track.title);
      },
    ),
    TableColumn<TrackWithArtists>(
      id: 'duration',
      label: 'Duration',
      width: 90,
      minWidth: 90,
      alignment: Alignment.center,
      cellBuilder: (context, track, index) {
        return Text(track.track.durationMs.toDurationString());
      },
    ),
    TableColumn<TrackWithArtists>(
      id: 'context_menu',
      label: '',
      width: 115,
      minWidth: 115,
      alignment: Alignment.centerRight,
      cellBuilder: (context, track, index) {
        return Consumer(
          builder: (context, ref, child) {
            final appIconSet = ref.watch(appIconProvider);

            return Row(
              mainAxisAlignment: .end,
              children: [
                IconButton(
                  onPressed: () {
                    unimplemented(context);
                  },
                  icon: AppIcon(appIconSet.favorite),
                ),
                Listener(
                  onPointerDown: (event) {
                    // Sync Selection consistently using 'album'
                    final selectionNotifier = ref.read(selectedTracksIndexProvider('album').notifier);
                    if (!ref.read(selectedTracksIndexProvider('album')).contains(index)) {
                      selectionNotifier.selectTrack(index, isCtrlSelect: false, isShiftSelect: false);
                    }

                    final albumId = track.album.id;
                    final sortedData = ref.read(sortedAlbumWithTracksProvider(albumId)).value;
                    final tracks = sortedData?.tracks ?? [];

                    final selectedIndices = ref.read(selectedTracksIndexProvider('album')).toList()..sort();
                    final selectedTracks = selectedIndices
                        .where((i) => i >= 0 && i < tracks.length)
                        .map((i) => tracks[i])
                        .toList();

                    TrackContextMenu.show(
                      context: context,
                      ref: ref,
                      isAdaptive: ref.read(configServiceProvider).adaptiveBg,
                      globalPosition: event.position,
                      tracks: tracks,
                      clickedIndex: index,
                      selectedTracks: selectedTracks,
                      playbackContextType: 'album',
                      playbackContextId: albumId,
                    );
                  },
                  child: IconButton(icon: AppIcon(appIconSet.contextMenu), onPressed: () {}),
                ),
              ],
            );
          },
        );
      },
    ),
  ];
}
