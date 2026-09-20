import 'dart:math';

import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nordplayer/core/database/app_database.dart';
import 'package:nordplayer/core/models/table_column_config.dart';
import 'package:nordplayer/core/system/logger.dart';
import 'package:nordplayer/core/system/preference_service.dart';
import 'package:nordplayer/data/repositories/album_repository.dart';
import 'package:nordplayer/services/audio/player_service.dart';

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

/// Provider managing table column layout and visibility for the album detail table.
final albumDetailPageTableColumnsProvider =
    NotifierProvider<AlbumDetailPageTableColumnsNotifier, List<TableColumnConfig>>(
      AlbumDetailPageTableColumnsNotifier.new,
    );

class AlbumDetailPageTableColumnsNotifier extends Notifier<List<TableColumnConfig>> {
  @override
  List<TableColumnConfig> build() => _initialColumns;

  void toggleVisibility(String columnId) {
    state = state.map((col) {
      if (col.id == columnId) {
        return col.copyWith(isVisible: !col.isVisible);
      }
      return col;
    }).toList();
  }

  static const List<TableColumnConfig> _initialColumns = [
    TableColumnConfig(
      id: 'index',
      label: "#",
      width: 50,
      minWidth: 50,
      alignment: Alignment.centerRight,
    ),
    TableColumnConfig(
      id: 'title',
      label: "Title",
      flex: 5,
      minWidth: 150,
    ),
    TableColumnConfig(
      id: 'duration',
      label: 'Duration',
      width: 90,
      minWidth: 90,
      alignment: Alignment.center,
    ),
    TableColumnConfig(
      id: 'context_menu',
      label: '',
      width: 115,
      minWidth: 115,
      alignment: Alignment.centerRight,
    ),
  ];
}

/// ViewModel coordinating album detail playback and presentation actions.
class AlbumDetailViewModel(final Ref _ref) with LoggerMixin {
  PlayerService get _playerService => _ref.read(playerServiceProvider);
  PreferenceService get _preferenceService => _ref.read(preferenceServiceProvider.notifier);

  /// Plays the given album tracks, optionally picking a random start index if shuffle is enabled,
  /// and synchronizes user preferences.
  void playAlbum({
    required List<TrackWithArtists> tracks,
    required int albumId,
    required bool shouldShuffle,
    int? initialIndex,
    bool forceReload = true,
  }) {
    if (tracks.isEmpty) return;

    final startIndex = initialIndex ??
        (shouldShuffle && tracks.isNotEmpty ? Random().nextInt(tracks.length) : 0);

    _preferenceService.setShuffleMode(shouldShuffle);

    _playerService.setPlaylist(
      tracksToPlay: tracks,
      initialIndex: startIndex,
      playbackContextType: 'album',
      playbackContextId: albumId,
      forceReload: forceReload,
    );
  }
}

/// Riverpod provider exposing [AlbumDetailViewModel].
final albumDetailViewModelProvider = Provider<AlbumDetailViewModel>((ref) => AlbumDetailViewModel(ref));
