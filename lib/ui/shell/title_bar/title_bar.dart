import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nordplayer/ui/shell/title_bar/window_control/breeze.dart';
import 'package:nordplayer/ui/shell/title_bar/window_control/windows11.dart';
import 'package:window_manager/window_manager.dart';

// windowManager.popUpWindowMenu is not working on windows
// And the windows tiling popover when hovering over maximize button is still not added

class TitleBar extends ConsumerStatefulWidget {
  const TitleBar({super.key});

  @override
  ConsumerState<TitleBar> createState() => _NordplayerTitleBarState();
}

class _NordplayerTitleBarState extends ConsumerState<TitleBar> with WindowListener {
  bool _isFocused = true;
  bool _isMaximized = false;

  Future<void> _initWindowState() async {
    final focused = await windowManager.isFocused();
    final maximized = await windowManager.isMaximized();
    if (mounted) {
      setState(() {
        _isFocused = focused;
        _isMaximized = maximized;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _initWindowState();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowFocus() {
    if (mounted) setState(() => _isFocused = true);
  }

  @override
  void onWindowBlur() {
    if (mounted) setState(() => _isFocused = false);
  }

  @override
  void onWindowMaximize() {
    if (mounted) setState(() => _isMaximized = true);
  }

  @override
  void onWindowUnmaximize() {
    if (mounted) setState(() => _isMaximized = false);
  }

  Future<void> _toggleMaximize() async {
    if (await windowManager.isMaximized()) {
      await windowManager.unmaximize();
    } else {
      await windowManager.maximize();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final titleColor = _isFocused
        ? colorScheme.onSurface
        : colorScheme.onSurface.withValues(alpha: 0.5);

    const double resizeEdgeHeight = 4.0;

    return Container(
      height: 34,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        border: Border(
          bottom: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.35), width: 1),
        ),
      ),
      child: Stack(
        children: [
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Row(
                    children: [
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onSecondaryTap: () async {
                          await windowManager.popUpWindowMenu();
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8.0, right: 6),
                          child: SvgPicture.asset(
                            'assets/icons/nordplayer_logo_white_transparent.svg',
                            width: 20,
                            height: 20,
                            colorFilter: ColorFilter.mode(titleColor, BlendMode.srcIn),
                          ),
                        ),
                      ),

                      Expanded(
                        child: DragToMoveArea(
                          child: GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onDoubleTap: _toggleMaximize,
                            onSecondaryTap: () async {
                              await windowManager.popUpWindowMenu();
                            },
                            child: Row(
                              children: [
                                Text(
                                  'Nordplayer',
                                  style: TextStyle(
                                    fontFamily: 'inter',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: titleColor,
                                  ),
                                ),
                                const Spacer(),
                              ],
                            ),
                          ),
                        ),
                      ),

                      DragToMoveArea(
                        child: GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onDoubleTap: _toggleMaximize,
                          onSecondaryTap: () async {
                            await windowManager.popUpWindowMenu();
                          },
                          // SizedBox can't be used inside DragToMoveArea because it can be clicked
                          child: Container(width: 8, color: Colors.transparent),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (Platform.isWindows) ...[
                DragToMoveArea(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onDoubleTap: _toggleMaximize,
                    onSecondaryTap: () async {
                      await windowManager.popUpWindowMenu();
                    },
                    child: Container(width: 8, color: Colors.transparent),
                  ),
                ),
                const Windows11WindowControl(),
              ] else if (Platform.isLinux) ...[
                const BreezeWindowControl(),
              ] else ...[
                const Windows11WindowControl(),
              ],
            ],
          ),

          // To increase window resize hitbox when window is not maximized
          if (!_isMaximized)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: resizeEdgeHeight,
              child: Row(
                children: [
                  MouseRegion(
                    cursor: SystemMouseCursors.resizeUpLeft,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onPanStart: (_) => windowManager.startResizing(ResizeEdge.topLeft),
                      child: const SizedBox(width: 8, height: resizeEdgeHeight),
                    ),
                  ),
                  Expanded(
                    child: MouseRegion(
                      cursor: SystemMouseCursors.resizeUp,
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onPanStart: (_) => windowManager.startResizing(ResizeEdge.top),
                        onDoubleTap: _toggleMaximize,
                      ),
                    ),
                  ),
                  MouseRegion(
                    cursor: SystemMouseCursors.resizeUpRight,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onPanStart: (_) => windowManager.startResizing(ResizeEdge.topRight),
                      child: const SizedBox(width: 8, height: resizeEdgeHeight),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
