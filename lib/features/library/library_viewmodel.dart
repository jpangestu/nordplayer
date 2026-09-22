import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nordplayer/core/models/library_section_config.dart';
import 'package:nordplayer/core/system/config_service.dart';
import 'package:nordplayer/core/system/logger.dart';
import 'package:nordplayer/data/repositories/album_repository.dart';
import 'package:nordplayer/data/repositories/config_repository.dart';
import 'package:nordplayer/data/repositories/playback_repository.dart';
import 'package:nordplayer/data/repositories/track_repository.dart';
import 'package:nordplayer/domain/models/models.dart';
import 'package:nordplayer/features/library/library_ui_state.dart';

export 'package:nordplayer/features/library/library_ui_state.dart';

/// ViewModel coordinating Library overview screen state, sections order, and playback.
class LibraryViewModel extends Notifier<LibraryUiState> with LoggerMixin {
  PlaybackRepository get _playbackRepository => ref.read(playbackRepositoryProvider);
  ConfigService get _configService => ref.read(configServiceProvider.notifier);

  @override
  LibraryUiState build() {
    final trackRepo = ref.watch(trackRepositoryProvider);
    final albumRepo = ref.watch(albumRepositoryProvider);
    final configRepo = ref.watch(configRepositoryProvider);

    final initialConfig = configRepo.currentConfig;
    final initialSections = initialConfig.librarySections;

    final statsSub = trackRepo.watchLibraryStats().listen(
      (stats) {
        state = state.copyWith(stats: stats, isLoading: false, errorMessage: () => null);
      },
      onError: (error) {
        state = state.copyWith(isLoading: false, errorMessage: () => error.toString());
      },
    );

    final recentSub = trackRepo.watchRecentlyAddedTracks(limitAmount: 12).listen((recent) {
      state = state.copyWith(recentlyAddedTracks: recent);
    });

    final tracksSub = trackRepo.watchAllTracks().listen((tracks) {
      if (tracks.isEmpty) {
        state = state.copyWith(sampleTracks: const []);
      } else {
        final sample = List<TrackWithArtists>.from(tracks)..shuffle();
        state = state.copyWith(sampleTracks: sample.take(6).toList());
      }
    });

    albumRepo
        .getRandomAlbums(limitAmount: 10)
        .then((albums) {
          state = state.copyWith(randomAlbums: albums);
        })
        .catchError((e) {
          log.w('Failed to load random albums: $e');
        });

    final configSub = configRepo.watchConfig().listen((config) {
      if (!listEquals(state.sections, config.librarySections) ||
          state.isAdaptiveBg != config.adaptiveBg ||
          state.adaptiveBgPanelBlur != config.adaptiveBgPanelBlur ||
          state.adaptiveBgThemeOverlay != config.adaptiveBgThemeOverlay) {
        state = state.copyWith(
          sections: config.librarySections,
          isAdaptiveBg: config.adaptiveBg,
          adaptiveBgPanelBlur: config.adaptiveBgPanelBlur,
          adaptiveBgThemeOverlay: config.adaptiveBgThemeOverlay,
        );
      }
    });

    ref.onDispose(() {
      statsSub.cancel();
      recentSub.cancel();
      tracksSub.cancel();
      configSub.cancel();
    });

    return LibraryUiState(
      sections: initialSections,
      isLoading: true,
      isAdaptiveBg: initialConfig.adaptiveBg,
      adaptiveBgPanelBlur: initialConfig.adaptiveBgPanelBlur,
      adaptiveBgThemeOverlay: initialConfig.adaptiveBgThemeOverlay,
    );
  }

  /// Moves a library section from [oldIndex] to [newIndex] and persists configuration.
  void reorderSections(int oldIndex, int newIndex) {
    final currentSections = List<LibrarySectionConfig>.from(state.sections);
    if (oldIndex < 0 || oldIndex >= currentSections.length) return;

    newIndex.clamp(0, currentSections.length - 1);

    final item = currentSections.removeAt(oldIndex);
    currentSections.insert(newIndex, item);

    log.i('Reordered library section "${item.id}" from $oldIndex to $newIndex');
    state = state.copyWith(sections: currentSections);
    _configService.updateConfig(librarySections: currentSections);
  }

  /// Toggles visibility for the section with [sectionId] and persists configuration.
  void toggleSectionVisibility(String sectionId) {
    final currentSections = List<LibrarySectionConfig>.from(state.sections);
    final index = currentSections.indexWhere((s) => s.id == sectionId);
    if (index == -1) return;

    final target = currentSections[index];
    final updated = target.copyWith(isVisible: !target.isVisible);
    currentSections[index] = updated;

    log.i('Toggled visibility for library section "$sectionId": ${updated.isVisible}');
    state = state.copyWith(sections: currentSections);
    _configService.updateConfig(librarySections: currentSections);
  }

  /// Toggles expansion of the Recently Added section (show 6 vs all).
  void toggleRecentlyAddedExpanded() {
    state = state.copyWith(isRecentlyAddedExpanded: !state.isRecentlyAddedExpanded);
  }

  /// Plays tracks in the specified context via [PlaybackRepository].
  void playTrack({
    required List<TrackWithArtists> tracksToPlay,
    required int index,
    required String playbackContextType,
    int? playbackContextId,
  }) {
    _playbackRepository.setPlaylist(
      tracksToPlay: tracksToPlay,
      initialIndex: index,
      playbackContextType: playbackContextType,
      playbackContextId: playbackContextId,
    );
  }
}

/// Riverpod provider exposing [LibraryViewModel].
final libraryViewModelProvider = NotifierProvider<LibraryViewModel, LibraryUiState>(LibraryViewModel.new);

/// Backward-compatible provider for library sections.
final librarySectionsProvider = Provider<List<LibrarySectionConfig>>((ref) {
  return ref.watch(libraryViewModelProvider.select((s) => s.sections));
});

/// Backward-compatible provider for sample tracks.
final librarySampleTracksProvider = Provider<List<TrackWithArtists>>((ref) {
  return ref.watch(libraryViewModelProvider.select((s) => s.sampleTracks));
});
