import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nordplayer/config/app_config.dart';
import 'package:nordplayer/core/window/native_window.dart';
import 'package:nordplayer/ui/shell/adaptive_surface.dart';

class AdaptiveSurfaceBenchmarkView extends ConsumerStatefulWidget {
  const AdaptiveSurfaceBenchmarkView({super.key});

  @override
  ConsumerState<AdaptiveSurfaceBenchmarkView> createState() => _AdaptiveSurfaceBenchmarkViewState();
}

class _AdaptiveSurfaceBenchmarkViewState extends ConsumerState<AdaptiveSurfaceBenchmarkView> {
  int _cardCount = 24;
  bool _showShadow = true;
  final double _cornerRadius = 14.0;
  bool _nestedPanels = true;
  bool _blurOnSharpBackdrop = true;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final appConfig = ref.watch(appConfigProvider);

    final windowBackdropType = ref.watch(appConfig.windowBackdrop.type.provider);
    final themeOverlayOpacity = ref.watch(appConfig.windowBackdrop.themeOverlayOpacity.provider);
    final platformStyle = ref.watch(appConfig.windowBackdrop.platformStyle.windows.provider);
    final albumArtBlurRadius = ref.watch(appConfig.windowBackdrop.albumArt.blurRadius.provider);
    final albumArtFit = ref.watch(appConfig.windowBackdrop.albumArt.fit.provider);

    final opacityLow = ref.watch(appConfig.surface.opacityLow.provider);
    final opacityMid = ref.watch(appConfig.surface.opacityMid.provider);
    final opacityHigh = ref.watch(appConfig.surface.opacityHigh.provider);
    final surfaceBlurRadius = ref.watch(appConfig.surface.blurRadius.provider);

    final isImageBackdrop =
        windowBackdropType == WindowBackdropType.albumArt ||
        windowBackdropType == WindowBackdropType.customImage;
    final isBackdropFilterActive =
        _blurOnSharpBackdrop && isImageBackdrop && albumArtBlurRadius < 10.0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // -------------------------------------------------------------------
          // Floating Benchmark Control Header
          // -------------------------------------------------------------------
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: AdaptiveSurface(
              elevation: SurfaceElevation.high,
              cornerRadius: 16.0,
              showShadow: true,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        tooltip: 'Back to Library',
                        onPressed: () => context.pop(),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'AdaptiveSurface Test Suite',
                        style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 16,
                    runSpacing: 10,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      // Backdrop Type Segmented Control
                      SegmentedButton<WindowBackdropType>(
                        segments: const [
                          ButtonSegment(
                            value: WindowBackdropType.solid,
                            icon: Icon(Icons.stop_outlined, size: 16),
                            label: Text('Solid'),
                          ),
                          ButtonSegment(
                            value: WindowBackdropType.platformStyle,
                            icon: Icon(Icons.blur_on_outlined, size: 16),
                            label: Text('Platform'),
                          ),
                          ButtonSegment(
                            value: WindowBackdropType.albumArt,
                            icon: Icon(Icons.album_outlined, size: 16),
                            label: Text('Album Art'),
                          ),
                        ],
                        selected: {windowBackdropType},
                        onSelectionChanged: (val) {
                          appConfig.windowBackdrop.type.value = val.first;
                        },
                      ),

                      // Platform Style Selector when in platformStyle mode
                      if (windowBackdropType == WindowBackdropType.platformStyle)
                        SegmentedButton<WindowsWindowStyle>(
                          segments: const [
                            ButtonSegment(
                              value: WindowsWindowStyle.acrylic,
                              icon: Icon(Icons.blur_on, size: 16),
                              label: Text('Acrylic'),
                            ),
                            ButtonSegment(
                              value: WindowsWindowStyle.mica,
                              icon: Icon(Icons.auto_awesome_outlined, size: 16),
                              label: Text('Mica'),
                            ),
                            ButtonSegment(
                              value: WindowsWindowStyle.micaAlt,
                              icon: Icon(Icons.tab_outlined, size: 16),
                              label: Text('Mica Alt'),
                            ),
                          ],
                          selected: {platformStyle},
                          onSelectionChanged: (val) {
                            appConfig.windowBackdrop.platformStyle.windows.value = val.first;
                          },
                        ),

                      // Album Art Fit Selector when in albumArt mode
                      if (windowBackdropType == WindowBackdropType.albumArt)
                        SegmentedButton<BoxFit>(
                          segments: const [
                            ButtonSegment(
                              value: BoxFit.cover,
                              icon: Icon(Icons.crop_free_outlined, size: 16),
                              label: Text('Cover'),
                            ),
                            ButtonSegment(
                              value: BoxFit.contain,
                              icon: Icon(Icons.fit_screen_outlined, size: 16),
                              label: Text('Contain'),
                            ),
                            ButtonSegment(
                              value: BoxFit.fill,
                              icon: Icon(Icons.aspect_ratio_outlined, size: 16),
                              label: Text('Fill'),
                            ),
                            ButtonSegment(
                              value: BoxFit.fitWidth,
                              icon: Icon(Icons.swap_horiz_outlined, size: 16),
                              label: Text('Fit Width'),
                            ),
                          ],
                          selected: {albumArtFit},
                          onSelectionChanged: (val) {
                            appConfig.windowBackdrop.albumArt.fit.value = val.first;
                          },
                        ),

                      // Card Count Selector
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Cards: ', style: textTheme.labelMedium),
                          DropdownButton<int>(
                            value: _cardCount,
                            dropdownColor: colorScheme.surfaceContainerHigh,
                            underline: const SizedBox.shrink(),
                            items: const [
                              DropdownMenuItem(value: 6, child: Text('6 cards')),
                              DropdownMenuItem(value: 12, child: Text('12 cards')),
                              DropdownMenuItem(value: 24, child: Text('24 cards')),
                              DropdownMenuItem(value: 48, child: Text('48 cards')),
                              DropdownMenuItem(value: 96, child: Text('96 cards')),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _cardCount = val);
                            },
                          ),
                        ],
                      ),

                      // blurOnSharpBackdrop Toggle
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Blur On Sharp Art: ', style: textTheme.labelMedium),
                          Switch(
                            value: _blurOnSharpBackdrop,
                            onChanged: (val) => setState(() => _blurOnSharpBackdrop = val),
                          ),
                        ],
                      ),

                      // Shadow Toggle
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Shadow: ', style: textTheme.labelMedium),
                          Switch(
                            value: _showShadow,
                            onChanged: (val) => setState(() => _showShadow = val),
                          ),
                        ],
                      ),

                      // Nested Panels Toggle
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Nested Panels: ', style: textTheme.labelMedium),
                          Switch(
                            value: _nestedPanels,
                            onChanged: (val) => setState(() => _nestedPanels = val),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // -------------------------------------------------------------------
          // Live Opacity & Blur Inspector
          // -------------------------------------------------------------------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: AdaptiveSurface(
              elevation: SurfaceElevation.low,
              cornerRadius: 12.0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: _buildSlider(
                      title: 'Low: ${(opacityLow * 100).round()}%',
                      value: opacityLow,
                      max: 1.0,
                      divisions: 20,
                      onChanged: (v) => appConfig.surface.opacityLow.value = v,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildSlider(
                      title: 'Mid: ${(opacityMid * 100).round()}%',
                      value: opacityMid,
                      max: 1.0,
                      divisions: 20,
                      onChanged: (v) => appConfig.surface.opacityMid.value = v,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildSlider(
                      title: 'High: ${(opacityHigh * 100).round()}%',
                      value: opacityHigh,
                      max: 1.0,
                      divisions: 20,
                      onChanged: (v) => appConfig.surface.opacityHigh.value = v,
                    ),
                  ),
                  if (windowBackdropType != WindowBackdropType.solid) ...[
                    const SizedBox(width: 14),
                    Expanded(
                      child: _buildSlider(
                        title: 'Scrim: ${(themeOverlayOpacity * 100).round()}%',
                        value: themeOverlayOpacity,
                        max: 1.0,
                        divisions: 20,
                        onChanged: (v) => appConfig.windowBackdrop.themeOverlayOpacity.value = v,
                      ),
                    ),
                  ],
                  if (windowBackdropType == WindowBackdropType.albumArt) ...[
                    const SizedBox(width: 14),
                    Expanded(
                      child: _buildSlider(
                        title: 'Art Blur: ${albumArtBlurRadius.round()}px',
                        value: albumArtBlurRadius,
                        max: 100.0,
                        divisions: 100,
                        onChanged: (v) => appConfig.windowBackdrop.albumArt.blurRadius.value = v,
                      ),
                    ),
                  ],
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildSlider(
                      title: isBackdropFilterActive
                          ? 'Surface Blur: ${surfaceBlurRadius.round()}px'
                          : 'Surface Blur: (Inactive)',
                      value: surfaceBlurRadius,
                      max: 50.0,
                      divisions: 50,
                      enabled: isBackdropFilterActive,
                      onChanged: isBackdropFilterActive
                          ? (v) => appConfig.surface.blurRadius.value = v
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // -------------------------------------------------------------------
          // Scrollable Stress Grid of AdaptiveSurfaces
          // -------------------------------------------------------------------
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 320,
                mainAxisExtent: 220,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
              ),
              itemCount: _cardCount,
              itemBuilder: (context, index) {
                // Alternate elevations across cards: low, mid, high
                final elevation = switch (index % 3) {
                  0 => SurfaceElevation.low,
                  1 => SurfaceElevation.mid,
                  _ => SurfaceElevation.high,
                };

                return AdaptiveSurface(
                  elevation: elevation,
                  cornerRadius: _cornerRadius,
                  showShadow: _showShadow,
                  blurOnSharpBackdrop: _blurOnSharpBackdrop,
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Header Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Icon(
                            switch (index % 4) {
                              0 => Icons.album,
                              1 => Icons.audiotrack,
                              2 => Icons.playlist_play,
                              _ => Icons.graphic_eq,
                            },
                            color: colorScheme.primary,
                            size: 22,
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'ELEVATION: ${elevation.name.toUpperCase()}',
                              style: textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Title & Subtitle
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Track #$index - Ambient Soundscape',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Art Blur: ${albumArtBlurRadius.round()}px | Fit: ${albumArtFit.name}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodySmall?.copyWith(
                              fontSize: 11,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),

                      // Nested Child Surface (Tests surface stacking / nesting)
                      if (_nestedPanels)
                        AdaptiveSurface(
                          elevation: elevation == SurfaceElevation.high
                              ? SurfaceElevation.mid
                              : SurfaceElevation.low,
                          cornerRadius: 8.0,
                          blurOnSharpBackdrop: _blurOnSharpBackdrop,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Nested Surface',
                                style: textTheme.bodySmall?.copyWith(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Icon(Icons.layers, size: 14, color: colorScheme.onSurfaceVariant),
                            ],
                          ),
                        )
                      else
                        const SizedBox(height: 8),

                      // Progress bar footer
                      LinearProgressIndicator(
                        value: ((index * 23) % 100) / 100.0,
                        backgroundColor: colorScheme.outlineVariant.withValues(alpha: 0.3),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlider({
    required String title,
    required double value,
    required double max,
    required int divisions,
    required ValueChanged<double>? onChanged,
    bool enabled = true,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Opacity(
      opacity: enabled ? 1.0 : 0.45,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.labelSmall?.copyWith(
              color: enabled ? null : colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          SizedBox(
            height: 24,
            child: Slider(
              value: value.clamp(0.0, max),
              min: 0.0,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
