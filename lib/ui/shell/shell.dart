import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nordplayer/config/app_config.dart';
import 'package:nordplayer/ui/shell/player_bar/player_bar.dart';
import 'package:nordplayer/ui/shell/sidebar/sidebar.dart';
import 'package:nordplayer/ui/shell/title_bar/title_bar.dart';
import 'package:nordplayer/ui/shell/window_backdrop.dart';

class Shell extends ConsumerWidget {
  final Widget child;

  const Shell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appConfig = ref.watch(appConfigProvider);
    final playerBarHeight = ref.watch(appConfig.ui.playerBar.height.provider);
    final sidebarWidth = ref.watch(appConfig.ui.sidebar.width.provider);
    final cursorOverride = ref.watch(cursorOverrideProvider);

    const resizeHitboxSize = 8.0;

    return MouseRegion(
      cursor: cursorOverride ?? MouseCursor.defer,
      child: IgnorePointer(
        ignoring: cursorOverride != null,
        child: WindowBackdrop(
          child: Material(
            type: .transparency,
            child: Column(
              children: [
                const TitleBar(),
                Expanded(
                  child: Stack(
                    children: [
                      Column(
                        children: [
                          Expanded(
                            child: Stack(
                              children: [
                                Row(
                                  children: [
                                    const Sidebar(),
                                    Expanded(child: ClipRect(child: child)),
                                  ],
                                ),
                                Positioned(
                                  top: 0,
                                  bottom: 0,
                                  left: sidebarWidth - (resizeHitboxSize / 2),
                                  width: resizeHitboxSize,
                                  child: const _SidebarResizeHandle(),
                                ),
                              ],
                            ),
                          ),
                          const PlayerBar(),
                        ],
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: playerBarHeight - (resizeHitboxSize / 2),
                        height: resizeHitboxSize,
                        child: const _PlayerBarResizeHandle(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarResizeHandle extends ConsumerStatefulWidget {
  const _SidebarResizeHandle();

  @override
  ConsumerState<_SidebarResizeHandle> createState() => _SidebarResizeHandleState();
}

class _SidebarResizeHandleState extends ConsumerState<_SidebarResizeHandle> {
  static const double _minWidth = 180.0;
  static const double _maxWidth = 480.0;

  double? _dragStartX;
  double? _dragStartWidth;

  void _endDrag() {
    _dragStartX = null;
    _dragStartWidth = null;
    ref.read(cursorOverrideProvider.notifier).set(null);
  }

  @override
  Widget build(BuildContext context) {
    final appConfig = ref.watch(appConfigProvider);

    return MouseRegion(
      cursor: SystemMouseCursors.resizeLeftRight,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragStart: (details) {
          _dragStartX = details.globalPosition.dx;
          _dragStartWidth = appConfig.ui.sidebar.width.value;
          ref.read(cursorOverrideProvider.notifier).set(SystemMouseCursors.resizeLeftRight);
        },
        onHorizontalDragUpdate: (details) {
          if (_dragStartX == null || _dragStartWidth == null) return;
          final deltaX = details.globalPosition.dx - _dragStartX!;
          appConfig.ui.sidebar.width.value = (_dragStartWidth! + deltaX).clamp(
            _minWidth,
            _maxWidth,
          );
        },
        onHorizontalDragEnd: (_) => _endDrag(),
        onHorizontalDragCancel: _endDrag,
      ),
    );
  }
}

class _PlayerBarResizeHandle extends ConsumerStatefulWidget {
  const _PlayerBarResizeHandle();

  @override
  ConsumerState<_PlayerBarResizeHandle> createState() => _PlayerBarResizeHandleState();
}

class _PlayerBarResizeHandleState extends ConsumerState<_PlayerBarResizeHandle> {
  static const double _minHeight = 64.0;
  static const double _maxHeight = 120.0;

  double? _dragStartY;
  double? _dragStartHeight;

  void _endDrag() {
    _dragStartY = null;
    _dragStartHeight = null;
    ref.read(cursorOverrideProvider.notifier).set(null);
  }

  @override
  Widget build(BuildContext context) {
    final appConfig = ref.watch(appConfigProvider);

    return MouseRegion(
      cursor: SystemMouseCursors.resizeUpDown,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragStart: (details) {
          _dragStartY = details.globalPosition.dy;
          _dragStartHeight = appConfig.ui.playerBar.height.value;
          ref.read(cursorOverrideProvider.notifier).set(SystemMouseCursors.resizeUpDown);
        },
        onVerticalDragUpdate: (details) {
          if (_dragStartY == null || _dragStartHeight == null) return;
          final deltaY = _dragStartY! - details.globalPosition.dy;
          appConfig.ui.playerBar.height.value = (_dragStartHeight! + deltaY).clamp(
            _minHeight,
            _maxHeight,
          );
        },
        onVerticalDragEnd: (_) => _endDrag(),
        onVerticalDragCancel: _endDrag,
      ),
    );
  }
}

final cursorOverrideProvider = NotifierProvider<CursorOverrideNotifier, MouseCursor?>(
  CursorOverrideNotifier.new,
);

class CursorOverrideNotifier extends Notifier<MouseCursor?> {
  @override
  MouseCursor? build() => null;

  void set(MouseCursor? cursor) => state = cursor;
}
