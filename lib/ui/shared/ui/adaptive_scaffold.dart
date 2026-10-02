import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nordplayer/data/repositories/config_repository.dart';
import 'package:nordplayer/data/repositories/ui_preferences_repository.dart';
import 'package:nordplayer/data/services/audio/player_state.dart';

/// Provider for the active album art path to be displayed in the adaptive background.
/// Extracted so background updates are cleanly decoupled and deduplicated.
final currentAdaptiveArtPathProvider = Provider<String?>((ref) {
  final trackAlbumArtPath = ref.watch(currentTrackProvider.select((t) => t?.album.albumArtPath));
  final cachedAlbumArtPath = ref.watch(uiPreferencesStateProvider.select((p) => p.cachedAlbumArtPath));
  final rawPath = (trackAlbumArtPath != null && trackAlbumArtPath.isNotEmpty) ? trackAlbumArtPath : cachedAlbumArtPath;
  return (rawPath != null && rawPath.isNotEmpty) ? rawPath : null;
});

/// Scaffold widget supporting an adaptive ambient background extracted from the current track.
class AdaptiveScaffold extends StatelessWidget {
  const AdaptiveScaffold({super.key, required this.body});

  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          // Solid background to prevent transparency during transitions or due to sub-pixel rendering gaps.
          // Color is outlineVariant to create a workaround for windows fractional scale transparency issues on divider.
          Positioned.fill(child: ColoredBox(color: Theme.of(context).colorScheme.outlineVariant)),

          // The optimized adaptive background layer isolated from body rebuilds.
          const Positioned.fill(child: AdaptiveBackground()),

          // Content
          body,
        ],
      ),
    );
  }
}

/// The animated, resource-optimized background layer for adaptive album art.
///
/// Features:
/// 1. Debouncing on rapid track skipping to prevent loading, decoding, and blurring intermediate tracks.
/// 2. Strict maximum of two layers in the crossfade stack to guarantee O(1) memory usage.
/// 3. Leaf-level RepaintBoundary caching so GPU blur filters do not re-rasterize every frame of opacity animations.
/// 4. Dynamic downsampling of decode dimensions to eliminate multi-megabyte bitmap decodes.
/// 5. Proactive cache eviction of obsolete album arts from Flutter's ImageCache.
class AdaptiveBackground extends ConsumerStatefulWidget {
  const AdaptiveBackground({super.key});

  @override
  ConsumerState<AdaptiveBackground> createState() => _AdaptiveBackgroundState();
}

class _AdaptiveBackgroundState extends ConsumerState<AdaptiveBackground> with SingleTickerProviderStateMixin {
  late final AnimationController _crossfadeController;
  late final Animation<double> _crossfadeAnimation;

  Timer? _debounceTimer;
  String? _pendingArtPath;

  _BackgroundData? _currentData;
  _BackgroundData? _previousData;

  @override
  void initState() {
    super.initState();
    _crossfadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _crossfadeAnimation = CurvedAnimation(parent: _crossfadeController, curve: Curves.easeOutCubic);
    _crossfadeController.addStatusListener(_onAnimationStatusChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _crossfadeController.removeStatusListener(_onAnimationStatusChanged);
    _crossfadeController.dispose();
    super.dispose();
  }

  void _onAnimationStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      if (_previousData != null) {
        final oldPath = _previousData?.artPath;
        if (mounted) {
          setState(() {
            _previousData = null;
          });
        }
        if (oldPath != null && oldPath != _currentData?.artPath) {
          _evictArtPath(oldPath);
        }
      }
    }
  }

  void _handleArtPathChanged(String? newPath) {
    if (!mounted) return;
    if (newPath == _currentData?.artPath && (_debounceTimer == null || !_debounceTimer!.isActive)) {
      return;
    }

    _pendingArtPath = newPath;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 120), () {
      if (!mounted) return;
      _applyPendingArt();
    });
  }

  void _applyPendingArt() {
    final targetPath = _pendingArtPath;
    if (targetPath == _currentData?.artPath && _previousData == null) return;

    final config = ref.read(configStateProvider);
    final newEntry = _BackgroundData(targetPath, config.adaptiveBgAlbumFit, config.adaptiveBgAlbumBlur);

    setState(() {
      if (_previousData != null &&
          _previousData!.artPath != targetPath &&
          _previousData!.artPath != _currentData?.artPath) {
        _evictArtPath(_previousData!.artPath);
      }
      _previousData = _currentData;
      _currentData = newEntry;
      _crossfadeController.forward(from: 0.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Clear global image cache when adaptive background is turned off to release memory
    ref.listen<bool>(configStateProvider.select((v) => v.adaptiveBg), (previous, next) {
      if (previous == true && next == false) {
        _debounceTimer?.cancel();
        _crossfadeController.stop();
        _previousData = null;
        _currentData = null;
        PaintingBinding.instance.imageCache.clear();
      }
    });

    ref.listen<String?>(currentAdaptiveArtPathProvider, (previous, next) {
      _handleArtPathChanged(next);
    });

    final adaptiveBg = ref.watch(configStateProvider.select((v) => v.adaptiveBg));
    if (!adaptiveBg) {
      return const SizedBox.shrink();
    }

    final blur = ref.watch(configStateProvider.select((v) => v.adaptiveBgAlbumBlur));
    final fit = ref.watch(configStateProvider.select((v) => v.adaptiveBgAlbumFit));
    final themeOverlay = ref.watch(configStateProvider.select((v) => v.adaptiveBgThemeOverlay));

    // Initialize or update current data if fit/blur changed dynamically (e.g. from sliders)
    if (_currentData == null) {
      final initialArtPath = ref.read(currentAdaptiveArtPathProvider);
      _currentData = _BackgroundData(initialArtPath, fit, blur);
      _crossfadeController.value = 1.0;
    } else if (_currentData!.fit != fit || _currentData!.blur != blur) {
      _currentData = _BackgroundData(_currentData!.artPath, fit, blur);
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        if (_previousData != null) RepaintBoundary(child: _BackgroundLayerWidget(data: _previousData!)),
        if (_currentData != null)
          FadeTransition(
            opacity: _crossfadeAnimation,
            child: RepaintBoundary(child: _BackgroundLayerWidget(data: _currentData!)),
          ),
        // Dimmer / Theme Overlay
        Positioned.fill(
          child: IgnorePointer(
            child: ColoredBox(color: Theme.of(context).colorScheme.surface.withValues(alpha: themeOverlay)),
          ),
        ),
      ],
    );
  }
}

class const _BackgroundData(final String? artPath, final BoxFit fit, final double blur) {
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _BackgroundData &&
          runtimeType == other.runtimeType &&
          artPath == other.artPath &&
          fit == other.fit &&
          blur == other.blur;

  @override
  int get hashCode => Object.hash(artPath, fit, blur);
}

class _BackgroundLayerWidget extends StatelessWidget {
  final _BackgroundData data;

  const _BackgroundLayerWidget({required this.data});

  @override
  Widget build(BuildContext context) {
    final artPath = data.artPath;
    final hasValidArt = artPath != null && artPath.isNotEmpty;
    final fit = data.fit;
    final blur = data.blur;

    final cacheW = _getOptimalCacheWidth(blur);

    Widget imageWidget;
    Widget? ambientFillWidget;

    if (hasValidArt) {
      final file = File(artPath);
      imageWidget = Image.file(
        file,
        fit: fit,
        cacheWidth: cacheW,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => _FallbackImage(fit: fit, cacheWidth: cacheW),
      );

      // Only add ambient fill when in contain mode, where letterboxing needs filling.
      // For cover and fill, the main image covers the entire screen, making ambient fill redundant.
      if (fit == BoxFit.contain) {
        ambientFillWidget = Image.file(
          file,
          fit: BoxFit.fill,
          cacheWidth: 100, // 100px thumbnail is optimal for heavy sigma 80 blur
          gaplessPlayback: true,
          errorBuilder: (_, _, _) => const SizedBox.shrink(),
        );
      }
    } else {
      imageWidget = _FallbackImage(fit: fit, cacheWidth: cacheW);
      if (fit == BoxFit.contain) {
        ambientFillWidget = const _FallbackImage(fit: BoxFit.fill, cacheWidth: 100);
      }
    }

    Widget? blurredAmbient;
    if (ambientFillWidget != null) {
      blurredAmbient = SizedBox.expand(
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80, tileMode: TileMode.mirror),
          child: ambientFillWidget,
        ),
      );
    }

    Widget mainContent;
    if (blur > 0) {
      mainContent = SizedBox.expand(
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(
            sigmaX: blur,
            sigmaY: blur,
            // When fit is contain, decal bounds blur to the centered image.
            // When fit is cover or fill, mirror prevents transparent edge bleeding.
            tileMode: fit == BoxFit.contain ? TileMode.decal : TileMode.mirror,
          ),
          child: imageWidget,
        ),
      );
    } else {
      mainContent = SizedBox.expand(child: imageWidget);
    }

    if (blurredAmbient != null) {
      return Stack(fit: StackFit.expand, children: [blurredAmbient, mainContent]);
    }

    return mainContent;
  }
}

class _FallbackImage extends StatelessWidget {
  final BoxFit fit;
  final int cacheWidth;

  const _FallbackImage({required this.fit, required this.cacheWidth});

  @override
  Widget build(BuildContext context) {
    return Image.asset('assets/images/default_background.png', fit: fit, cacheWidth: cacheWidth, gaplessPlayback: true);
  }
}

int _getOptimalCacheWidth(double blur) {
  // If heavily blurred (blur >= 50), downscale heavily to save memory and raster bandwidth
  if (blur >= 50) return 120;
  // For moderate blur (10 < blur < 50), 360px gives smooth gradients
  if (blur > 10) return 360;
  // For low or zero blur, cap at 1280px to avoid decoding uncompressed 4000x4000 raw images (64MB each)
  return 1280;
}

void _evictArtPath(String? path) {
  if (path == null || path.isEmpty) return;
  try {
    final file = File(path);
    FileImage(file).evict();
    for (final w in const [100, 120, 360, 1280]) {
      ResizeImage(FileImage(file), width: w).evict();
    }
  } catch (_) {}
}
