import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nordplayer/services/background_task_service.dart';
import 'package:nordplayer/services/config_service.dart';
import 'package:nordplayer/services/performance_tracker.dart';
import 'package:nordplayer/theming/icon-sets/app_icon_set.dart';
import 'package:nordplayer/widgets/frosted_glass.dart';
import 'package:nordplayer/widgets/popover_panel.dart';
import 'package:nordplayer/widgets/title_bar/background_task_panel.dart';
import 'package:nordplayer/widgets/title_bar/base_button.dart';
import 'package:nordplayer/widgets/title_bar/keyboard_shortcuts_panel.dart';
import 'package:nordplayer/widgets/title_bar/performance_panel.dart';
import 'package:nordplayer/widgets/title_bar/window_control/breeze.dart';
import 'package:nordplayer/widgets/title_bar/window_control/windows11.dart';
import 'package:window_manager/window_manager.dart';

class NordTitleBar extends ConsumerStatefulWidget {
  const NordTitleBar({super.key});

  @override
  ConsumerState<NordTitleBar> createState() => _NordplayerTitleBarState();
}

class _NordplayerTitleBarState extends ConsumerState<NordTitleBar> {
  final GlobalKey _shortcutsButtonKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appConfig = ref.watch(configServiceProvider).requireValue;
    final appIconSet = ref.watch(appIconProvider);

    return FrostedGlass(
      blurSigma: (appConfig.adaptiveBgPanelBlur + 30).clamp(0, 100),
      backgroundColor: appConfig.adaptiveBg
          ? colorScheme.surfaceContainer.withValues(alpha: appConfig.adaptiveBgThemeOverlay)
          : colorScheme.surfaceContainer,
      child: SizedBox(
        height: 34,
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () async {
                        await windowManager.popUpWindowMenu();
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8.0, right: 4),
                        child: SvgPicture.asset(
                          'assets/icons/nordplayer_logo_white_transparent.svg',
                          width: 22,
                          height: 22,
                          colorFilter: ColorFilter.mode(colorScheme.onSurface, BlendMode.srcIn),
                        ),
                      ),
                    ),

                    const Expanded(
                      child: DragToMoveArea(child: Row(children: [Text('Nordplayer'), Spacer()])),
                    ),

                    const _BackgroundTaskButton(),
                    // SizedBox can't be used inside DragToMoveArea because it can be clicked
                    DragToMoveArea(child: Container(width: 8, color: Colors.transparent)),

                    _Performance(appIconSet: appIconSet),

                    DragToMoveArea(child: Container(width: 8, color: Colors.transparent)),

                    BaseButton(
                      key: _shortcutsButtonKey,
                      icon: appIconSet.keyboardShortcut,
                      buttonHeight: 24,
                      buttonWidth: 24,
                      iconSize: 17,
                      iconColor: colorScheme.onSurface,
                      overlayColor: colorScheme.onSurface.withValues(alpha: 0.1),
                      tooltip: 'Keyboard Shortcuts',
                      onClick: () {
                        showPopover(
                          context: context,
                          anchorKey: _shortcutsButtonKey,
                          width: 280,
                          child: const KeyboardShortcutsPanel(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            if (Platform.isWindows) ...[
              DragToMoveArea(child: Container(width: 8, color: Colors.transparent)),
              const Windows11WindowControl(),
            ] else if (Platform.isLinux) ...[
              const BreezeWindowControl(),
            ] else ...[
              const Windows11WindowControl(),
            ],
          ],
        ),
      ),
    );
  }
}

class _Performance extends StatefulWidget {
  final AppIconSet appIconSet;
  const _Performance({required this.appIconSet});

  @override
  State<_Performance> createState() => _PerformanceState();
}

class _PerformanceState extends State<_Performance> {
  final GlobalKey _fpsButtonKey = GlobalKey();
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: PerformanceTracker.instance,
      builder: (context, _) {
        final tracker = PerformanceTracker.instance;
        final baseColor = colorScheme.onSurface;
        final textColor = _isHovering
            ? baseColor
            : (tracker.isIdle ? baseColor.withValues(alpha: 0.3) : baseColor.withValues(alpha: 0.7));

        final baseStyle = TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: textColor,
          fontFamily: 'jetbrains_mono',
        );

        final List<Widget> widgets = [];

        if (tracker.isVisible('frameLatency')) {
          final val = tracker.formatLatency(tracker.currentFrameTime);
          widgets.add(Text(val, style: baseStyle));
        }
        if (tracker.isVisible('potentialFps')) {
          final val = tracker.isIdle ? 'Idle' : '${tracker.potentialFps} FPS';
          widgets.add(Text(val, style: baseStyle));
        }
        if (tracker.isVisible('averageFrameTime')) {
          final val = tracker.isIdle || tracker.averageFrameTime == 0.0
              ? 'Avg: Idle'
              : 'Avg: ${tracker.formatLatency(tracker.averageFrameTime)}';
          widgets.add(Text(val, style: baseStyle));
        }
        if (tracker.isVisible('avgPotentialFps')) {
          final val = tracker.isIdle ? 'Avg: Idle' : 'Avg: ${tracker.averagePotentialFps} FPS';
          widgets.add(Text(val, style: baseStyle));
        }
        if (tracker.isVisible('minFrameTime')) {
          final val = 'Min: ${tracker.formatLatency(tracker.minFrameTime)}';
          widgets.add(Text(val, style: baseStyle));
        }
        if (tracker.isVisible('maxPotentialFps')) {
          final val = 'Max: ${tracker.maxPotentialFps} FPS';
          widgets.add(Text(val, style: baseStyle));
        }
        if (tracker.isVisible('maxFrameTime')) {
          final val = 'Max: ${tracker.formatLatency(tracker.maxFrameTime)}';
          widgets.add(Text(val, style: baseStyle));
        }
        if (tracker.isVisible('minPotentialFps')) {
          final val = 'Min: ${tracker.minPotentialFps} FPS';
          widgets.add(Text(val, style: baseStyle));
        }
        if (tracker.isVisible('actualFrameRate')) {
          final val = tracker.isIdle ? 'Idle' : '${tracker.actualFrameRate} Hz';
          widgets.add(Text(val, style: baseStyle));
        }
        if (tracker.isVisible('cpuUsage')) {
          final val = '${tracker.cpuUsage.toStringAsFixed(1)}% CPU';
          widgets.add(Text(val, style: baseStyle));
        }
        if (tracker.isVisible('ramUsage')) {
          final val = tracker.formatRam(tracker.ramBytes);
          widgets.add(Text(val, style: baseStyle));
        }

        if (widgets.isEmpty) {
          return BaseButton(
            key: _fpsButtonKey,
            icon: widget.appIconSet.performance,
            buttonHeight: 24,
            buttonWidth: 24,
            iconSize: 17,
            iconColor: colorScheme.onSurface,
            overlayColor: colorScheme.onSurface.withValues(alpha: 0.1),
            tooltip: 'Performance Metrics',
            onClick: () {
              showPopover(context: context, anchorKey: _fpsButtonKey, width: 300, child: const PerformancePanel());
            },
          );
        }

        final List<Widget> children = [];
        for (int i = 0; i < widgets.length; i++) {
          children.add(widgets[i]);
          if (i < widgets.length - 1) {
            children.add(
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text('|', style: baseStyle.copyWith(color: textColor.withValues(alpha: 0.3))),
              ),
            );
          }
        }

        return MouseRegion(
          onEnter: (_) => setState(() => _isHovering = true),
          onExit: (_) => setState(() => _isHovering = false),
          child: GestureDetector(
            key: _fpsButtonKey,
            onTap: () {
              showPopover(context: context, anchorKey: _fpsButtonKey, width: 300, child: const PerformancePanel());
            },
            behavior: HitTestBehavior.opaque,
            child: Tooltip(
              message: 'Performance Metrics',
              waitDuration: const Duration(milliseconds: 500),
              child: Container(
                height: 34,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(mainAxisSize: MainAxisSize.min, children: children),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BackgroundTaskButton extends ConsumerStatefulWidget {
  const _BackgroundTaskButton();

  @override
  ConsumerState<_BackgroundTaskButton> createState() => _BackgroundTaskButtonState();
}

class _BackgroundTaskButtonState extends ConsumerState<_BackgroundTaskButton> with SingleTickerProviderStateMixin {
  final GlobalKey _buttonKey = GlobalKey();
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(vsync: this, duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(backgroundTaskServiceProvider);
    if (tasks.isEmpty) return const SizedBox.shrink();

    final runningTasks = tasks.where((t) => t.status == BackgroundTaskStatus.running).toList();
    final isRunning = runningTasks.isNotEmpty;

    if (isRunning) {
      if (!_rotationController.isAnimating) {
        _rotationController.repeat();
      }
    } else {
      if (_rotationController.isAnimating) {
        _rotationController.stop();
      }
    }

    final colorScheme = Theme.of(context).colorScheme;

    // Calculate aggregate progress for running tasks
    double? progress;
    bool hasIndeterminate = false;
    int totalProcessed = 0;
    int totalCount = 0;

    for (final BackgroundTask task in runningTasks) {
      if (task.isIndeterminate) {
        hasIndeterminate = true;
      }
      totalProcessed += task.processed;
      totalCount += task.total;
    }

    if (isRunning && !hasIndeterminate && totalCount > 0) {
      progress = totalProcessed / totalCount;
    }

    final hasFailed = tasks.any((t) => t.status == BackgroundTaskStatus.failed);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        BaseButton(
          key: _buttonKey,
          buttonHeight: 28,
          buttonWidth: 28,
          iconSize: 17,
          iconColor: colorScheme.onSurface,
          overlayColor: colorScheme.onSurface.withValues(alpha: 0.1),
          tooltip: 'Performance Metrics',
          onClick: () {
            showPopover(context: context, anchorKey: _buttonKey, width: 320, child: const BackgroundTaskPanel());
          },
          child: SizedBox(
            width: 28,
            height: 28,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (isRunning) ...[
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 1.8,
                      valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                      backgroundColor: colorScheme.onSurface.withValues(alpha: 0.1),
                    ),
                  ),
                  RotationTransition(
                    turns: _rotationController,
                    child: Icon(Icons.sync, size: 10, color: colorScheme.primary),
                  ),
                ] else ...[
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          value: 1.0,
                          strokeWidth: 1.8,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            hasFailed ? colorScheme.error : colorScheme.primary,
                          ),
                        ),
                      ),
                      Icon(
                        hasFailed ? Icons.close : Icons.check,
                        size: 10,
                        color: hasFailed ? colorScheme.error : colorScheme.primary,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
