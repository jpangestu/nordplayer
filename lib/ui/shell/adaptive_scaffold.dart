import 'dart:io';

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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyPlatformStyle();
    });
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
    final themeOverlay = ref.watch(appConfig.windowBg.albumArt.themeOverlay.provider);

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
          if (windowBgType != WindowBgType.solid)
            ColoredBox(color: colorScheme.surface.withValues(alpha: themeOverlay.clamp(0.0, 1.0))),

          widget.child,
        ],
      ),
    );
  }
}
