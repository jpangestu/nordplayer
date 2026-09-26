import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nordplayer/data/repositories/artist_repository.dart';
import 'package:nordplayer/data/repositories/config_repository.dart';
import 'package:nordplayer/ui/artists/artists_ui_state.dart';
import 'package:nordplayer/utils/logger.dart';

/// ViewModel orchestrating state, repository subscriptions, and actions for the Artists overview screen.
class ArtistsViewModel extends Notifier<ArtistsUiState> with LoggerMixin {
  @override
  ArtistsUiState build() {
    final artistRepo = ref.watch(artistRepositoryProvider);
    final configRepo = ref.watch(configRepositoryProvider);

    final initialConfig = configRepo.currentConfig;

    final artistsSub = artistRepo.watchArtists().listen(
      (artists) {
        state = state.copyWith(artists: artists, isLoading: false, errorMessage: () => null);
      },
      onError: (err) {
        log.e('Error loading artists: $err');
        state = state.copyWith(isLoading: false, errorMessage: () => err.toString());
      },
    );

    final configSub = configRepo.watchConfig().listen((config) {
      state = state.copyWith(
        isAdaptiveBg: config.adaptiveBg,
        adaptiveBgPanelBlur: config.adaptiveBgPanelBlur,
        adaptiveBgThemeOverlay: config.adaptiveBgThemeOverlay,
      );
    });

    ref.onDispose(() {
      artistsSub.cancel();
      configSub.cancel();
    });

    return ArtistsUiState(
      isLoading: true,
      isAdaptiveBg: initialConfig.adaptiveBg,
      adaptiveBgPanelBlur: initialConfig.adaptiveBgPanelBlur,
      adaptiveBgThemeOverlay: initialConfig.adaptiveBgThemeOverlay,
    );
  }
}

/// Riverpod provider exposing [ArtistsViewModel].
final artistsViewModelProvider = NotifierProvider<ArtistsViewModel, ArtistsUiState>(ArtistsViewModel.new);
