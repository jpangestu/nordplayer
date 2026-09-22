import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nordplayer/core/system/logger.dart';
import 'package:nordplayer/data/repositories/album_repository.dart';
import 'package:nordplayer/data/repositories/config_repository.dart';
import 'package:nordplayer/domain/models/models.dart';
import 'package:nordplayer/features/albums/albums_ui_state.dart';

/// ViewModel orchestrating state, repository subscriptions, and actions for the Albums overview screen.
class AlbumsViewModel extends Notifier<AlbumsUiState> with LoggerMixin {
  AlbumRepository get _albumRepository => ref.read(albumRepositoryProvider);

  @override
  AlbumsUiState build() {
    final albumRepo = ref.watch(albumRepositoryProvider);
    final configRepo = ref.watch(configRepositoryProvider);

    final initialConfig = configRepo.currentConfig;

    final albumsSub = albumRepo.watchAlbums().listen(
      (albums) {
        state = state.copyWith(albums: albums, isLoading: false, errorMessage: () => null);
      },
      onError: (err) {
        log.e('Error loading albums: $err');
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
      albumsSub.cancel();
      configSub.cancel();
    });

    return AlbumsUiState(
      isLoading: true,
      isAdaptiveBg: initialConfig.adaptiveBg,
      adaptiveBgPanelBlur: initialConfig.adaptiveBgPanelBlur,
      adaptiveBgThemeOverlay: initialConfig.adaptiveBgThemeOverlay,
    );
  }

  /// Fetches artists associated with tracks on an album (e.g. For various artists compilation menus).
  Future<List<Artist>> getAlbumArtists(int albumId) async {
    return await _albumRepository.getTrackArtists(albumId: albumId);
  }
}

/// Riverpod provider exposing [AlbumsViewModel].
final albumsViewModelProvider = NotifierProvider<AlbumsViewModel, AlbumsUiState>(AlbumsViewModel.new);
