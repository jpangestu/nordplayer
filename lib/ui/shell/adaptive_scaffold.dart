import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nordplayer/config/app_config.dart';
import 'package:nordplayer/core/window/native_window.dart';

class AdaptiveScaffold extends ConsumerStatefulWidget {
  final Widget child;

  const AdaptiveScaffold({super.key, required this.child});

  @override
  ConsumerState<AdaptiveScaffold> createState() => _AdaptiveScaffoldState();
}

class _AdaptiveScaffoldState extends ConsumerState<AdaptiveScaffold> {
  ui.Image? _resolvedAlbumArt;
  ImageStream? _imageStream;
  ImageStreamListener? _streamListener;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyPlatformStyle();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolveAlbumArt();
  }

  // TODO: create currently played song album art stream
  void _resolveAlbumArt() {
    const assetImage = AssetImage('assets/album_art.jpg');
    final imageConfig = createLocalImageConfiguration(context);
    final newStream = assetImage.resolve(imageConfig);

    if (newStream.key == _imageStream?.key) return;

    if (_imageStream != null && _streamListener != null) {
      _imageStream!.removeListener(_streamListener!);
    }

    _imageStream = newStream;
    _streamListener = ImageStreamListener((info, _) {
      if (mounted) {
        setState(() {
          _resolvedAlbumArt = info.image;
        });
      }
    });

    _imageStream!.addListener(_streamListener!);
  }

  @override
  void dispose() {
    if (_imageStream != null && _streamListener != null) {
      _imageStream!.removeListener(_streamListener!);
    }
    super.dispose();
  }

  void _applyPlatformStyle() {
    final appConfig = ref.read(appConfigProvider);
    final windowBgType = ref.read(appConfig.windowBg.type.provider);
    final nativeWindow = ref.read(nativeWindowProvider);
    final platformStyle = Platform.isWindows
        ? ref.read(appConfig.windowBg.platformStyle.windows.provider)
        : null;

    nativeWindow.setWindowPlatformStyle(
      windowBgType == WindowBgType.platformStyle ? platformStyle : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final appConfig = ref.watch(appConfigProvider);
    final windowBgType = ref.watch(appConfig.windowBg.type.provider);
    final themeOverlayOpacity = ref.watch(appConfig.themeOverlayOpacity.provider);
    final albumArtBlurSigma = ref.watch(appConfig.windowBg.albumArt.blurSigma.provider);
    final albumArtFit = ref.watch(appConfig.windowBg.albumArt.fit.provider);

    final colorScheme = Theme.of(context).colorScheme;

    // Reactively update window backdrop when config changes
    ref.listen(appConfig.windowBg.type.provider, (_, newType) {
      _applyPlatformStyle();
    });
    ref.listen(appConfig.windowBg.platformStyle.windows.provider, (_, newEffect) {
      _applyPlatformStyle();
    });

    return Scaffold(
      backgroundColor: windowBgType != WindowBgType.solid
          ? Colors.transparent
          : colorScheme.surface,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ======================================================================================
          // Album Art layer
          // ======================================================================================
          if (windowBgType == WindowBgType.albumArt) ...[
            // Ambient background (blurred)
            if (_resolvedAlbumArt != null &&
                albumArtFit != BoxFit.cover &&
                albumArtFit != BoxFit.fill)
              RepaintBoundary(
                child: ImageFiltered(
                  imageFilter: ui.ImageFilter.blur(
                    tileMode: ui.TileMode.clamp,
                    sigmaX: 20,
                    sigmaY: 20,
                  ),
                  child: CustomPaint(
                    painter: ImageAmbientPainter(image: _resolvedAlbumArt!, fit: albumArtFit),
                    size: Size.infinite,
                  ),
                ),
              ),

            // The album art
            ImageFiltered(
              imageFilter: ui.ImageFilter.blur(
                tileMode: ui.TileMode.clamp,
                sigmaX: albumArtBlurSigma,
                sigmaY: albumArtBlurSigma,
              ),
              child: Image.asset('assets/album_art.jpg', fit: albumArtFit),
            ),

            // ColorTheme overlay tint
            ColoredBox(
              color: colorScheme.surface.withValues(alpha: themeOverlayOpacity.clamp(0.0, 1.0)),
            ),
          ] else if (windowBgType != WindowBgType.solid) ...[
            // Translucent platform style overlay
            ColoredBox(
              color: colorScheme.surface.withValues(alpha: themeOverlayOpacity.clamp(0.0, 1.0)),
            ),
          ],

          widget.child,
        ],
      ),
    );
  }
}

/// A custom painter that renders an ambient, edge-matching background to cover blank space from
/// non-fill image fit (not BoxFit.cover or BoxFit.fill).
///
/// Slices thin perimeter strips from [image] and stretches them to the center of the canvas,
/// eliminating transparent gaps so Gaussian blur produces zero dark edge shadows.
class ImageAmbientPainter({
  required final ui.Image image,

  /// The active fit used by the foreground artwork (e.g. [BoxFit.contain]).
  required final BoxFit fit,
}) extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final imageSize = Size(image.width.toDouble(), image.height.toDouble());
    final imageFitted = applyBoxFit(fit, imageSize, size);

    final horizontalGap = (size.width - imageFitted.destination.width) / 2;
    final verticalGap = (size.height - imageFitted.destination.height) / 2;

    // How much pixel should we pick from the edge of the image
    const double stripThickness = 4.0;

    final paint = Paint()
      ..isAntiAlias = true
      ..filterQuality = FilterQuality.low;

    // If there's horizontal blank space
    if (horizontalGap > 0) {
      final halfWidth = size.width / 2;

      // Left strip stretches to center (fills left half)
      final srcLeft = Rect.fromLTWH(0, 0, stripThickness, imageSize.height);
      final dstLeft = Rect.fromLTWH(0, 0, halfWidth + 1, size.height);
      canvas.drawImageRect(image, srcLeft, dstLeft, paint);

      // Right strip stretches from center to right edge (fills right half)
      final srcRight = Rect.fromLTWH(
        imageSize.width - stripThickness,
        0,
        stripThickness,
        imageSize.height,
      );
      final dstRight = Rect.fromLTWH(halfWidth - 1, 0, halfWidth + 1, size.height);
      canvas.drawImageRect(image, srcRight, dstRight, paint);
    }

    // If there's vertical blank space
    if (verticalGap > 0) {
      final halfHeight = size.height / 2;

      // Top strip stretches to center (fills top half)
      final srcTop = Rect.fromLTWH(0, 0, imageSize.width, stripThickness);
      final dstTop = Rect.fromLTWH(0, 0, size.width, halfHeight + 1);
      canvas.drawImageRect(image, srcTop, dstTop, paint);

      // Bottom strip stretches from center to bottom (fills bottom half)
      final srcBottom = Rect.fromLTWH(
        0,
        imageSize.height - stripThickness,
        imageSize.width,
        stripThickness,
      );
      final dstBottom = Rect.fromLTWH(0, halfHeight - 1, size.width, halfHeight + 1);
      canvas.drawImageRect(image, srcBottom, dstBottom, paint);
    }
  }

  @override
  bool shouldRepaint(ImageAmbientPainter oldDelegate) {
    return oldDelegate.image != image || oldDelegate.fit != fit;
  }
}
