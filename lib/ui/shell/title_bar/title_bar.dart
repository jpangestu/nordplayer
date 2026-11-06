import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nordplayer/core/window/drag_to_move_area.dart';
import 'package:nordplayer/core/window/native_window.dart';
import 'package:nordplayer/ui/shell/title_bar/window_control/breeze.dart';
import 'package:nordplayer/ui/shell/title_bar/window_control/windows11.dart';

class TitleBar extends ConsumerWidget {
  const TitleBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nativeWindow = ref.read(nativeWindowProvider);
    final isFocused = ref.watch(isWindowFocusedProvider);
    final isMaximized = ref.watch(isWindowMaximizedProvider);

    final colorScheme = Theme.of(context).colorScheme;
    final titleColor = isFocused
        ? colorScheme.onSurface
        : colorScheme.onSurface.withValues(alpha: 0.5);

    const double resizeHitboxHeight = 6.0;

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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: DragToMoveArea(
                  child: Container(
                    color: Colors.transparent,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 12.0, right: 6),
                          child: SvgPicture.asset(
                            'assets/icons/nordplayer_logo_white_transparent.svg',
                            width: 20,
                            height: 20,
                            colorFilter: ColorFilter.mode(titleColor, BlendMode.srcIn),
                          ),
                        ),
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
              if (Platform.isWindows)
                const Windows11WindowControl()
              else if (Platform.isLinux)
                const BreezeWindowControl()
              else
                const Windows11WindowControl(),
            ],
          ),

          // Custom resize hitbox at the very top of the window when not maximized
          if (!isMaximized)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: resizeHitboxHeight,
              child: Row(
                children: [
                  MouseRegion(
                    cursor: SystemMouseCursors.resizeUpLeft,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onPanStart: (_) => nativeWindow.startResizing(WindowResizeEdge.topLeft),
                      child: const SizedBox(width: 8, height: resizeHitboxHeight),
                    ),
                  ),
                  Expanded(
                    child: MouseRegion(
                      cursor: SystemMouseCursors.resizeUp,
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onPanStart: (_) => nativeWindow.startResizing(WindowResizeEdge.top),
                        onDoubleTap: nativeWindow.toggleMaximize,
                      ),
                    ),
                  ),
                  MouseRegion(
                    cursor: SystemMouseCursors.resizeUpRight,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onPanStart: (_) => nativeWindow.startResizing(WindowResizeEdge.topRight),
                      child: const SizedBox(width: 8, height: resizeHitboxHeight),
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
