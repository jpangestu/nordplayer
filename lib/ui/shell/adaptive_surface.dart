import 'dart:ui' show ImageFilter;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nordplayer/config/app_config.dart';

/// Semantic elevation levels that define spatial depth and surface opacity.
///
/// Maps directly to the app's surface container color ramp and resolves mode-aware
/// opacities depending on the active [WindowBackdropType].
enum SurfaceElevation {
  /// Subtle grouping level for grouping stuff.
  low,

  /// Default elevation level for title bar, sidebar, player bar, etc.
  mid,

  /// Elevated level for popovers and dialogs.
  high,
}

/// An adaptive container that automatically resolves colors, opacities, and blurs.
class const AdaptiveSurface({
  super.key,

  /// The visual depth and opacity tier of the surface.
  ///
  /// Controls which surface container color is resolved from [ColorScheme] and dictates opacity
  /// when floating over non-solid window backdrops.
  final SurfaceElevation elevation = SurfaceElevation.mid,

  /// The corner rounding radius of the surface in pixels.
  final double cornerRadius = 0.0,

  /// Space to inset the [child] inside the surface bounds.
  final EdgeInsetsGeometry? padding,

  /// An optional explicit width constraint for the surface.
  final double? width,

  /// An optional explicit height constraint for the surface.
  final double? height,

  /// Whether to project a soft drop shadow behind the surface.
  final bool showShadow = false,

  /// Whether to add blur when the underlying image backdrop is sharp (blur radius < 10px).
  final bool blurOnSharpBackdrop = false,

  /// The widget content rendered inside this surface.
  required final Widget child,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final appConfig = ref.watch(appConfigProvider);
    final windowBackdropType = ref.watch(appConfig.windowBackdrop.type.provider);
    final themeOverlayOpacity = ref.watch(appConfig.windowBackdrop.themeOverlayOpacity.provider);
    final surfaceBlurRadius = ref.watch(appConfig.surface.blurRadius.provider);
    final surfaceOpacityLow = ref.watch(appConfig.surface.opacityLow.provider);
    final surfaceOpacityMid = ref.watch(appConfig.surface.opacityMid.provider);
    final surfaceOpacityHigh = ref.watch(appConfig.surface.opacityHigh.provider);
    final albumArtBlurRadius = ref.watch(appConfig.windowBackdrop.albumArt.blurRadius.provider);

    final shouldBlur =
        blurOnSharpBackdrop &&
        (windowBackdropType == WindowBackdropType.albumArt ||
            windowBackdropType == WindowBackdropType.customImage) &&
        albumArtBlurRadius < 10.0;

    final effectiveColor = _resolveEffectiveColor(
      colorScheme: colorScheme,
      windowBackdropType: windowBackdropType,
      themeOverlayOpacity: themeOverlayOpacity,
      surfaceOpacityLow: surfaceOpacityLow,
      surfaceOpacityMid: surfaceOpacityMid,
      surfaceOpacityHigh: surfaceOpacityHigh,
    );
    final effectiveShadows = _resolveShadows(isDark);

    final borderRadius = BorderRadius.circular(cornerRadius);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(borderRadius: borderRadius, boxShadow: effectiveShadows),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            // Gaussian blur
            if (shouldBlur)
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: surfaceBlurRadius,
                    sigmaY: surfaceBlurRadius,
                    tileMode: TileMode.clamp,
                  ),
                  child: ColoredBox(color: effectiveColor),
                ),
              )
            else
              // Solid color-theme
              Positioned.fill(child: ColoredBox(color: effectiveColor)),

            if (padding != null) Padding(padding: padding!, child: child) else child,

            // Can put Border here (drawn on top, immune to blur bleed)
            // Positioned.fill(
            //   child: IgnorePointer(
            //     child: DecoratedBox(
            //       decoration: BoxDecoration(borderRadius: borderRadius, border: effectiveBorder),
            //     ),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }

  Color _resolveEffectiveColor({
    required ColorScheme colorScheme,
    required WindowBackdropType windowBackdropType,
    required double themeOverlayOpacity,
    required double surfaceOpacityLow,
    required double surfaceOpacityMid,
    required double surfaceOpacityHigh,
  }) {
    final baseColor = switch (elevation) {
      SurfaceElevation.low => colorScheme.surfaceContainerLow,
      SurfaceElevation.mid => colorScheme.surfaceContainer,
      SurfaceElevation.high => colorScheme.surfaceContainerHigh,
    };

    final Color effectiveColor;

    if (windowBackdropType == WindowBackdropType.solid) {
      effectiveColor = baseColor;
    } else {
      effectiveColor = baseColor.withValues(
        alpha: switch (elevation) {
          SurfaceElevation.low => (surfaceOpacityLow).clamp(0.0, 1.0),
          SurfaceElevation.mid => (surfaceOpacityMid).clamp(0.0, 1.0),
          SurfaceElevation.high => (surfaceOpacityHigh).clamp(0.0, 1.0),
        },
      );
    }

    return effectiveColor;
  }

  List<BoxShadow>? _resolveShadows(bool isDark) {
    if (!showShadow) return null;

    final alphaKey = isDark ? 0.28 : 0.14;
    final alphaAmbient = isDark ? 0.12 : 0.06;

    return switch (elevation) {
      SurfaceElevation.low => [
        BoxShadow(
          color: Colors.black.withValues(alpha: alphaAmbient),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
      SurfaceElevation.mid => [
        BoxShadow(
          color: Colors.black.withValues(alpha: alphaKey),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
      SurfaceElevation.high => [
        BoxShadow(
          color: Colors.black.withValues(alpha: alphaKey),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: alphaAmbient),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ],
    };
  }
}
